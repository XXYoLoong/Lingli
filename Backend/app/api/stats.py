"""统计路由"""

import uuid
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import func, extract

from app.database import get_db
from app.models.user import UserAccount, RoleEnum
from app.models.order import ServiceOrder, OrderStatusEnum
from app.models.station import ServiceStation
from app.services.dependencies import get_current_user, require_role

router = APIRouter(prefix="/stats", tags=["统计"])


@router.get("/station/{station_id}")
def get_station_stats(
    station_id: uuid.UUID,
    start_date: str | None = Query(None, description="开始日期 YYYY-MM-DD"),
    end_date: str | None = Query(None, description="结束日期 YYYY-MM-DD"),
    db: Session = Depends(get_db),
    current_user: UserAccount = Depends(require_role(RoleEnum.STATION_MANAGER, RoleEnum.OPERATOR, RoleEnum.ADMIN)),
):
    """获取站点统计数据"""
    station = db.query(ServiceStation).filter(ServiceStation.id == station_id).first()
    if not station:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="站点不存在")

    query = db.query(ServiceOrder).filter(ServiceOrder.station_id == station_id)

    # 日期范围过滤
    if start_date:
        query = query.filter(ServiceOrder.created_at >= datetime.strptime(start_date, "%Y-%m-%d"))
    if end_date:
        query = query.filter(ServiceOrder.created_at <= datetime.strptime(end_date, "%Y-%m-%d"))

    orders = query.all()

    total = len(orders)
    by_status = {}
    by_type = {}
    completed_count = 0

    for order in orders:
        status_key = order.status.value
        by_status[status_key] = by_status.get(status_key, 0) + 1

        type_key = order.service_type
        by_type[type_key] = by_type.get(type_key, 0) + 1

        if order.status in (OrderStatusEnum.COMPLETED, OrderStatusEnum.CLOSED):
            completed_count += 1

    return {
        "station_id": station_id,
        "station_name": station.name,
        "total_orders": total,
        "completed_orders": completed_count,
        "completion_rate": round(completed_count / total * 100, 2) if total > 0 else 0,
        "by_status": by_status,
        "by_type": by_type,
    }


@router.get("/orders/trend")
def get_order_trend(
    station_id: uuid.UUID | None = Query(None),
    days: int = Query(7, ge=1, le=90),
    db: Session = Depends(get_db),
    current_user: UserAccount = Depends(get_current_user),
):
    """获取工单趋势数据（按天）"""
    from datetime import timedelta

    start_date = datetime.utcnow() - timedelta(days=days)
    query = db.query(ServiceOrder).filter(ServiceOrder.created_at >= start_date)

    if station_id:
        query = query.filter(ServiceOrder.station_id == station_id)

    orders = query.all()

    # 按天聚合
    daily_data = {}
    for order in orders:
        day_key = order.created_at.strftime("%Y-%m-%d")
        if day_key not in daily_data:
            daily_data[day_key] = {"total": 0, "completed": 0, "in_progress": 0}
        daily_data[day_key]["total"] += 1
        if order.status in (OrderStatusEnum.COMPLETED, OrderStatusEnum.CLOSED):
            daily_data[day_key]["completed"] += 1
        else:
            daily_data[day_key]["in_progress"] += 1

    return {"trend": daily_data, "days": days}
