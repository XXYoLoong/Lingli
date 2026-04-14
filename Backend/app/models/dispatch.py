"""调度任务模型"""

import uuid
from datetime import datetime
from enum import Enum

from sqlalchemy import String, DateTime, Text, ForeignKey, Enum as SAEnum, Integer
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base, generate_uuid


class DispatchStatusEnum(str, Enum):
    PENDING = "pending"
    ASSIGNED = "assigned"
    ACCEPTED = "accepted"
    REJECTED = "rejected"
    REASSIGNED = "reassigned"


class DispatchTask(Base):
    __tablename__ = "dispatch_task"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=generate_uuid)
    order_id: Mapped[str] = mapped_column(String(36), ForeignKey("service_order.id"), nullable=False, index=True)
    station_id: Mapped[str] = mapped_column(String(36), ForeignKey("service_station.id"), nullable=False)
    candidate_worker_id: Mapped[str] = mapped_column(String(36), nullable=False)
    dispatcher_user_id: Mapped[str | None] = mapped_column(String(36), ForeignKey("user_account.id"), nullable=True)
    score: Mapped[int] = mapped_column(Integer, default=0)
    status: Mapped[DispatchStatusEnum] = mapped_column(SAEnum(DispatchStatusEnum), default=DispatchStatusEnum.PENDING)
    dispatch_reason: Mapped[str | None] = mapped_column(Text, nullable=True)
    reject_reason: Mapped[str | None] = mapped_column(Text, nullable=True)
    distance_score: Mapped[int] = mapped_column(Integer, default=0)
    type_match_score: Mapped[int] = mapped_column(Integer, default=0)
    load_score: Mapped[int] = mapped_column(Integer, default=0)
    urgency_score: Mapped[int] = mapped_column(Integer, default=0)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    responded_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)

    order = relationship("ServiceOrder")
    station = relationship("ServiceStation")
    dispatcher_user = relationship("UserAccount")
