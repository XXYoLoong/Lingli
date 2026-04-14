"""工单模型"""

import uuid
from datetime import datetime
from enum import Enum

from sqlalchemy import String, DateTime, Text, ForeignKey, Enum as SAEnum, Integer, Boolean
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base, generate_uuid


class OrderStatusEnum(str, Enum):
    CREATED = "created"
    PENDING_DISPATCH = "pending_dispatch"
    PENDING_ACCEPT = "pending_accept"
    PENDING_ARRIVE = "pending_arrive"
    IN_SERVICE = "in_service"
    PENDING_CONFIRM = "pending_confirm"
    COMPLETED = "completed"
    AFTER_SALE = "after_sale"
    CLOSED = "closed"


class ServiceOrder(Base):
    __tablename__ = "service_order"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=generate_uuid)
    order_no: Mapped[str] = mapped_column(String(30), unique=True, nullable=False, index=True)
    station_id: Mapped[str] = mapped_column(String(36), ForeignKey("service_station.id"), nullable=False, index=True)
    creator_id: Mapped[str] = mapped_column(String(36), ForeignKey("user_account.id"), nullable=False)
    service_type: Mapped[str] = mapped_column(String(50), nullable=False, index=True)
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    voice_transcript: Mapped[str | None] = mapped_column(Text, nullable=True)
    contact_name: Mapped[str | None] = mapped_column(String(50), nullable=True)
    contact_phone: Mapped[str | None] = mapped_column(String(20), nullable=True)
    service_address: Mapped[str | None] = mapped_column(String(255), nullable=True)
    longitude: Mapped[int | None] = mapped_column(Integer, nullable=True)
    latitude: Mapped[int | None] = mapped_column(Integer, nullable=True)
    appointment_time: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    status: Mapped[OrderStatusEnum] = mapped_column(SAEnum(OrderStatusEnum), default=OrderStatusEnum.CREATED)
    urgency_level: Mapped[str] = mapped_column(String(20), default="normal")
    ai_category: Mapped[str | None] = mapped_column(String(50), nullable=True)
    ai_risk_tags: Mapped[str | None] = mapped_column(String(500), nullable=True)
    ai_summary: Mapped[str | None] = mapped_column(Text, nullable=True)
    assigned_worker_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    check_in_time: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    check_in_longitude: Mapped[int | None] = mapped_column(Integer, nullable=True)
    check_in_latitude: Mapped[int | None] = mapped_column(Integer, nullable=True)
    check_in_code: Mapped[str | None] = mapped_column(String(20), nullable=True)
    service_result: Mapped[str | None] = mapped_column(Text, nullable=True)
    abnormal_flag: Mapped[bool] = mapped_column(Boolean, default=False)
    abnormal_reason: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    completed_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)

    station = relationship("ServiceStation")
    creator = relationship("UserAccount", foreign_keys=[creator_id])
    attachments = relationship("OrderAttachment", back_populates="order")


class OrderAttachment(Base):
    __tablename__ = "order_attachment"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=generate_uuid)
    order_id: Mapped[str] = mapped_column(String(36), ForeignKey("service_order.id"), nullable=False, index=True)
    file_key: Mapped[str] = mapped_column(String(255), nullable=False)
    file_path: Mapped[str] = mapped_column(String(500), nullable=False)
    file_name: Mapped[str] = mapped_column(String(255), nullable=False)
    mime_type: Mapped[str | None] = mapped_column(String(100), nullable=True)
    file_size: Mapped[int | None] = mapped_column(Integer, nullable=True)
    attachment_type: Mapped[str] = mapped_column(String(30), nullable=False)
    uploaded_by: Mapped[str] = mapped_column(String(36), nullable=False)
    description: Mapped[str | None] = mapped_column(String(500), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    order = relationship("ServiceOrder", back_populates="attachments")
