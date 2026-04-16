# Copyright 2026 Jiacheng Ni
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""工单路由"""

import uuid
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import func

from app.database import get_db
from app.models.user import UserAccount, RoleEnum
from app.models.order import ServiceOrder, OrderStatusEnum
from app.models.dispatch import DispatchTask
from app.models.message import Message, MessageTypeEnum
from app.schemas.order import (
    OrderCreate, OrderUpdate, OrderResponse,
    OrderCheckIn, OrderComplete,
)
from app.services.dependencies import get_current_user
from app.services.dispatch_service import calculate_dispatch_scores

router = APIRouter(prefix="/orders", tags=["工单"])


def generate_order_no() -> str:
    """生成工单号"""
    now = datetime.utcnow()
    return f"NL{now.strftime('%Y%m%d%H%M%S')}{uuid.uuid4().hex[:6].upper()}"


@router.post("/", response_model=OrderResponse, status_code=status.HTTP_201_CREATED)
def create_order(
    order_data: OrderCreate,
    db: Session = Depends(get_db),
    current_user: UserAccount = Depends(get_current_user),
):
    """创建工单（居民端）"""
    order = ServiceOrder(
        order_no=generate_order_no(),
        station_id=current_user.station_id or _get_default_station(db),
        creator_id=current_user.id,
        service_type=order_data.service_type,
        title=order_data.title,
        description=order_data.description,
        voice_transcript=order_data.voice_transcript,
        contact_name=order_data.contact_name,
        contact_phone=order_data.contact_phone,
        service_address=order_data.service_address,
        longitude=order_data.longitude,
        latitude=order_data.latitude,
        appointment_time=order_data.appointment_time,
        status=OrderStatusEnum.CREATED,
    )
    db.add(order)
    db.commit()
    db.refresh(order)

    # 异步触发 AI 审核（记录任务到日志）
    _trigger_ai_review(db, order)

    return order


@router.get("/", response_model=list[OrderResponse])
def list_orders(
    status_filter: OrderStatusEnum | None = Query(None, alias="status"),
    service_type: str | None = None,
    station_id: uuid.UUID | None = None,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user: UserAccount = Depends(get_current_user),
):
    """获取工单列表"""
    query = db.query(ServiceOrder)

    if status_filter:
        query = query.filter(ServiceOrder.status == status_filter)
    if service_type:
        query = query.filter(ServiceOrder.service_type == service_type)
    if station_id:
        query = query.filter(ServiceOrder.station_id == station_id)

    # 角色数据范围控制
    if current_user.role == RoleEnum.RESIDENT:
        query = query.filter(ServiceOrder.creator_id == current_user.id)
    elif current_user.role == RoleEnum.WORKER:
        query = query.filter(ServiceOrder.assigned_worker_id == current_user.id)

    query = query.order_by(ServiceOrder.created_at.desc())
    offset = (page - 1) * page_size
    return query.offset(offset).limit(page_size).all()


@router.get("/{order_id}", response_model=OrderResponse)
def get_order(
    order_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: UserAccount = Depends(get_current_user),
):
    """获取工单详情"""
    order = db.query(ServiceOrder).filter(ServiceOrder.id == order_id).first()
    if not order:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="工单不存在")
    return order


@router.patch("/{order_id}", response_model=OrderResponse)
def update_order(
    order_id: uuid.UUID,
    order_data: OrderUpdate,
    db: Session = Depends(get_db),
    current_user: UserAccount = Depends(get_current_user),
):
    """更新工单（仅创建者可更新草稿阶段）"""
    order = db.query(ServiceOrder).filter(ServiceOrder.id == order_id).first()
    if not order:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="工单不存在")
    if order.creator_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="无权修改此工单")
    if order.status != OrderStatusEnum.CREATED:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="工单已进入流程，不可修改")

    for field, value in order_data.model_dump(exclude_unset=True).items():
        setattr(order, field, value)
    db.commit()
    db.refresh(order)
    return order


@router.post("/{order_id}/check-in", response_model=OrderResponse)
def check_in(
    order_id: uuid.UUID,
    check_in_data: OrderCheckIn,
    db: Session = Depends(get_db),
    current_user: UserAccount = Depends(get_current_user),
):
    """服务人员到场签到"""
    if current_user.role != RoleEnum.WORKER:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="仅服务人员可签到")

    order = db.query(ServiceOrder).filter(ServiceOrder.id == order_id).first()
    if not order:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="工单不存在")
    if order.assigned_worker_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="非指派服务人员")
    if order.status not in (OrderStatusEnum.PENDING_ARRIVE,):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="工单状态不允许签到")

    # 校验服务码
    if order.check_in_code and order.check_in_code != check_in_data.check_in_code:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="服务码错误")

    order.status = OrderStatusEnum.IN_SERVICE
    order.check_in_time = datetime.utcnow()
    order.check_in_longitude = check_in_data.longitude
    order.check_in_latitude = check_in_data.latitude
    db.commit()
    db.refresh(order)
    return order


@router.post("/{order_id}/complete", response_model=OrderResponse)
def complete_order(
    order_id: uuid.UUID,
    complete_data: OrderComplete,
    db: Session = Depends(get_db),
    current_user: UserAccount = Depends(get_current_user),
):
    """服务人员完成工单"""
    if current_user.role != RoleEnum.WORKER:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="仅服务人员可完成工单")

    order = db.query(ServiceOrder).filter(ServiceOrder.id == order_id).first()
    if not order:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="工单不存在")
    if order.assigned_worker_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="非指派服务人员")

    order.status = OrderStatusEnum.PENDING_CONFIRM
    order.service_result = complete_data.service_result
    order.abnormal_flag = complete_data.abnormal_flag
    order.abnormal_reason = complete_data.abnormal_reason
    order.completed_at = datetime.utcnow()
    db.commit()
    db.refresh(order)
    return order


@router.post("/{order_id}/cancel", status_code=status.HTTP_204_NO_CONTENT)
def cancel_order(
    order_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: UserAccount = Depends(get_current_user),
):
    """取消工单（仅创建者可在创建阶段取消）"""
    order = db.query(ServiceOrder).filter(ServiceOrder.id == order_id).first()
    if not order:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="工单不存在")
    if order.creator_id != current_user.id and current_user.role not in (RoleEnum.STATION_MANAGER, RoleEnum.ADMIN):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="无权取消此工单")
    if order.status not in (OrderStatusEnum.CREATED, OrderStatusEnum.PENDING_DISPATCH):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="工单已进入流程，不可取消")

    order.status = OrderStatusEnum.CLOSED
    db.commit()


def _get_default_station(db: Session) -> uuid.UUID:
    """获取默认站点（第一个可用站点）"""
    from app.models.station import ServiceStation
    station = db.query(ServiceStation).filter(ServiceStation.status == "active").first()
    if not station:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="无可用服务站点")
    return station.id


def _trigger_ai_review(db: Session, order: ServiceOrder):
    """触发 AI 审核（异步任务记录）"""
    from app.models.ai_log import AiReviewLog, AiTaskTypeEnum, AiTaskStatusEnum
    ai_log = AiReviewLog(
        order_id=order.id,
        task_type=AiTaskTypeEnum.REVIEW,
        status=AiTaskStatusEnum.PENDING,
        request_prompt=f"工单标题: {order.title}\n描述: {order.description or '无'}",
    )
    db.add(ai_log)
    db.commit()
