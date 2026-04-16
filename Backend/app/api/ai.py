"""AI 代理路由"""

from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.user import UserAccount, RoleEnum
from app.models.order import ServiceOrder
from app.models.ai_log import AiReviewLog, AiTaskTypeEnum, AiTaskStatusEnum
from app.schemas.ai import AiTaskRequest, AiReviewResponse, AiTaskResponse
from app.services.dependencies import get_current_user, require_role, is_super_admin
from app.services.ai_service import AIService
from app.config import settings

router = APIRouter(prefix="/ai", tags=["AI 智能辅助"])
ai_service = AIService()


@router.post("/review", response_model=AiTaskResponse)
def trigger_review(
    request: AiTaskRequest,
    db: Session = Depends(get_db),
    current_user: UserAccount = Depends(require_role(RoleEnum.STATION_MANAGER, RoleEnum.OPERATOR, RoleEnum.ADMIN)),
):
    """触发工单 AI 审核分析"""
    order = db.query(ServiceOrder).filter(ServiceOrder.id == request.order_id).first()
    if not order:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="工单不存在")

    # 检查是否已有进行中的任务
    existing = db.query(AiReviewLog).filter(
        AiReviewLog.order_id == request.order_id,
        AiReviewLog.task_type == request.task_type,
        AiReviewLog.status.in_([AiTaskStatusEnum.PENDING, AiTaskStatusEnum.PROCESSING]),
    ).first()

    if existing and not request.force:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="已有正在处理的 AI 任务")

    # 构造请求提示词
    prompt = ai_service.build_review_prompt(order)

    ai_log = AiReviewLog(
        order_id=request.order_id,
        task_type=request.task_type,
        status=AiTaskStatusEnum.PROCESSING,
        model_name=settings.QWEN_MODEL_REVIEW,
        request_prompt=prompt,
    )
    db.add(ai_log)
    db.commit()
    db.refresh(ai_log)

    # 同步调用（生产环境应改为异步任务队列）
    try:
        result = ai_service.call_qwen_api(prompt, request.task_type)
        ai_log.status = AiTaskStatusEnum.COMPLETED
        ai_log.response_content = result.get("content", "")
        ai_log.category_suggestion = result.get("category", "")
        ai_log.urgency_suggestion = result.get("urgency", "")
        ai_log.risk_tags = result.get("risk_tags", "")
        ai_log.summary = result.get("summary", "")
        ai_log.confidence = int(result.get("confidence", 0) * 100)
        ai_log.tokens_used = result.get("tokens_used")
        ai_log.completed_at = datetime.utcnow()

        # 回写到工单
        if result.get("category"):
            order.ai_category = result["category"]
        if result.get("urgency"):
            order.urgency_level = result["urgency"]
        if result.get("risk_tags"):
            order.ai_risk_tags = result["risk_tags"]
        if result.get("summary"):
            order.ai_summary = result["summary"]

        db.commit()
    except Exception as e:
        ai_log.status = AiTaskStatusEnum.FAILED
        ai_log.error_message = str(e)
        db.commit()

    return AiTaskResponse(
        task_id=ai_log.id,
        order_id=ai_log.order_id,
        order_no=order.order_no,
        task_type=ai_log.task_type,
        status=ai_log.status,
        model_name=ai_log.model_name,
        created_at=ai_log.created_at,
        completed_at=ai_log.completed_at,
    )


@router.get("/review/{task_id}", response_model=AiReviewResponse)
def get_review_result(
    task_id: str,
    db: Session = Depends(get_db),
    current_user: UserAccount = Depends(get_current_user),
):
    """获取 AI 审核结果"""
    ai_log = db.query(AiReviewLog).filter(AiReviewLog.id == str(task_id)).first()
    if not ai_log:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="AI 任务不存在")

    import json
    risk_tags = []
    if ai_log.risk_tags:
        try:
            risk_tags = json.loads(ai_log.risk_tags)
        except (json.JSONDecodeError, TypeError):
            risk_tags = [ai_log.risk_tags]

    return AiReviewResponse(
        task_id=ai_log.id,
        status=ai_log.status,
        category_suggestion=ai_log.category_suggestion,
        urgency_suggestion=ai_log.urgency_suggestion,
        risk_tags=risk_tags,
        summary=ai_log.summary,
        confidence=ai_log.confidence / 100 if ai_log.confidence else None,
    )


@router.get("/tasks", response_model=list[AiTaskResponse])
def list_ai_tasks(
    status_filter: AiTaskStatusEnum | None = None,
    task_type: AiTaskTypeEnum | None = None,
    db: Session = Depends(get_db),
    current_user: UserAccount = Depends(get_current_user),
):
    """获取 AI 任务列表"""
    query = db.query(AiReviewLog)
    if status_filter:
        query = query.filter(AiReviewLog.status == status_filter)
    if task_type:
        query = query.filter(AiReviewLog.task_type == task_type)

    if current_user.role == RoleEnum.RESIDENT:
        query = query.join(ServiceOrder, ServiceOrder.id == AiReviewLog.order_id).filter(
            ServiceOrder.creator_id == current_user.id
        )
    elif current_user.role == RoleEnum.WORKER:
        query = query.join(ServiceOrder, ServiceOrder.id == AiReviewLog.order_id).filter(
            ServiceOrder.assigned_worker_id == current_user.id
        )
    elif current_user.role in (RoleEnum.STATION_MANAGER, RoleEnum.DISPATCHER, RoleEnum.OPERATOR):
        query = query.join(ServiceOrder, ServiceOrder.id == AiReviewLog.order_id).filter(
            ServiceOrder.station_id == current_user.station_id
        )
    elif current_user.role == RoleEnum.ADMIN and not is_super_admin(current_user):
        query = query.join(ServiceOrder, ServiceOrder.id == AiReviewLog.order_id).filter(
            ServiceOrder.station_id == current_user.station_id
        )

    logs = query.order_by(AiReviewLog.created_at.desc()).limit(200).all()
    return [
        AiTaskResponse(
            task_id=log.id,
            order_id=log.order_id,
            order_no=log.order.order_no if log.order else None,
            task_type=log.task_type,
            status=log.status,
            model_name=log.model_name,
            created_at=log.created_at,
            completed_at=log.completed_at,
        )
        for log in logs
    ]
