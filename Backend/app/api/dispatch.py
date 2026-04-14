"""调度路由"""

import uuid
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.user import UserAccount, RoleEnum, WorkerProfile
from app.models.order import ServiceOrder, OrderStatusEnum
from app.models.dispatch import DispatchTask, DispatchStatusEnum
from app.schemas.dispatch import DispatchRequest, DispatchResponse, DispatchCandidate, DispatchReassignRequest, DispatchRejectRequest
from app.services.dependencies import get_current_user, require_role
from app.services.dispatch_service import calculate_dispatch_scores

router = APIRouter(prefix="/dispatch", tags=["调度"])


@router.post("/calculate/{order_id}", response_model=list[DispatchCandidate])
def calculate_candidates(
    order_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: UserAccount = Depends(require_role(RoleEnum.STATION_MANAGER, RoleEnum.DISPATCHER, RoleEnum.ADMIN)),
):
    """计算工单的候选服务人员推荐列表"""
    order = db.query(ServiceOrder).filter(ServiceOrder.id == order_id).first()
    if not order:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="工单不存在")

    workers = db.query(WorkerProfile).filter(
        WorkerProfile.status == "available",
        WorkerProfile.current_load < WorkerProfile.max_load,
    ).all()

    candidates = calculate_dispatch_scores(db, order, workers)
    # 按总分排序，取前 10 名
    candidates.sort(key=lambda c: c.total_score, reverse=True)
    return candidates[:10]


@router.post("/", response_model=DispatchResponse, status_code=status.HTTP_201_CREATED)
def assign_task(
    dispatch_data: DispatchRequest,
    db: Session = Depends(get_db),
    current_user: UserAccount = Depends(require_role(RoleEnum.STATION_MANAGER, RoleEnum.DISPATCHER, RoleEnum.ADMIN)),
):
    """手动派单"""
    order = db.query(ServiceOrder).filter(ServiceOrder.id == dispatch_data.order_id).first()
    if not order:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="工单不存在")
    if order.status not in (OrderStatusEnum.CREATED, OrderStatusEnum.PENDING_DISPATCH, OrderStatusEnum.REASSIGNED):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="工单状态不允许派单")

    # 更新工单状态和指派人员
    order.status = OrderStatusEnum.PENDING_ACCEPT
    order.assigned_worker_id = dispatch_data.worker_id

    # 创建调度记录
    task = DispatchTask(
        order_id=dispatch_data.order_id,
        station_id=order.station_id,
        candidate_worker_id=dispatch_data.worker_id,
        dispatcher_user_id=current_user.id,
        dispatch_reason=dispatch_data.dispatch_reason,
        status=DispatchStatusEnum.ASSIGNED,
    )
    db.add(task)

    # 增加服务人员负载
    profile = db.query(WorkerProfile).filter(WorkerProfile.user_id == dispatch_data.worker_id).first()
    if profile:
        profile.current_load += 1

    db.commit()
    db.refresh(task)
    return task


@router.post("/auto/{order_id}", response_model=list[DispatchResponse], status_code=status.HTTP_201_CREATED)
def auto_dispatch(
    order_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: UserAccount = Depends(require_role(RoleEnum.STATION_MANAGER, RoleEnum.DISPATCHER, RoleEnum.ADMIN)),
):
    """自动推荐派单（返回推荐列表，由调度员确认）"""
    order = db.query(ServiceOrder).filter(ServiceOrder.id == order_id).first()
    if not order:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="工单不存在")

    workers = db.query(WorkerProfile).filter(
        WorkerProfile.status == "available",
        WorkerProfile.current_load < WorkerProfile.max_load,
    ).all()

    candidates = calculate_dispatch_scores(db, order, workers)
    candidates.sort(key=lambda c: c.total_score, reverse=True)
    top_candidates = candidates[:3]

    tasks = []
    for candidate in top_candidates:
        task = DispatchTask(
            order_id=order_id,
            station_id=order.station_id,
            candidate_worker_id=candidate.worker_id,
            dispatcher_user_id=current_user.id,
            score=candidate.total_score,
            distance_score=candidate.distance_score,
            type_match_score=candidate.type_match_score,
            load_score=candidate.load_score,
            urgency_score=candidate.urgency_score,
            status=DispatchStatusEnum.PENDING,
        )
        db.add(task)
        tasks.append(task)

    db.commit()
    for t in tasks:
        db.refresh(t)
    return tasks


@router.post("/accept/{task_id}", status_code=status.HTTP_204_NO_CONTENT)
def accept_task(
    task_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: UserAccount = Depends(get_current_user),
):
    """服务人员接受工单"""
    if current_user.role != RoleEnum.WORKER:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="仅服务人员可接受工单")

    task = db.query(DispatchTask).filter(DispatchTask.id == task_id).first()
    if not task:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="调度任务不存在")
    if task.candidate_worker_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="非任务指派对象")

    from datetime import datetime
    task.status = DispatchStatusEnum.ACCEPTED
    task.responded_at = datetime.utcnow()

    order = db.query(ServiceOrder).filter(ServiceOrder.id == task.order_id).first()
    if order:
        order.status = OrderStatusEnum.PENDING_ARRIVE
        order.assigned_worker_id = current_user.id

    db.commit()


@router.post("/reject/{task_id}", status_code=status.HTTP_204_NO_CONTENT)
def reject_task(
    task_id: uuid.UUID,
    reject_data: DispatchRejectRequest,
    db: Session = Depends(get_db),
    current_user: UserAccount = Depends(get_current_user),
):
    """服务人员拒绝工单"""
    if current_user.role != RoleEnum.WORKER:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="仅服务人员可拒绝工单")

    task = db.query(DispatchTask).filter(DispatchTask.id == task_id).first()
    if not task:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="调度任务不存在")
    if task.candidate_worker_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="非任务指派对象")

    from datetime import datetime
    task.status = DispatchStatusEnum.REJECTED
    task.reject_reason = reject_data.reason
    task.responded_at = datetime.utcnow()

    db.commit()


@router.get("/my-tasks", response_model=list[DispatchResponse])
def get_my_tasks(
    db: Session = Depends(get_db),
    current_user: UserAccount = Depends(get_current_user),
):
    """获取我的调度任务（服务人员）"""
    if current_user.role != RoleEnum.WORKER:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="仅服务人员可访问")

    tasks = db.query(DispatchTask).filter(
        DispatchTask.candidate_worker_id == current_user.id,
        DispatchTask.status.in_([DispatchStatusEnum.PENDING, DispatchStatusEnum.ASSIGNED]),
    ).order_by(DispatchTask.created_at.desc()).all()
    return tasks
