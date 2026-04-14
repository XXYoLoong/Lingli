"""AI 审核日志模型"""

import uuid
from datetime import datetime
from enum import Enum

from sqlalchemy import String, DateTime, Text, ForeignKey, Integer, Enum as SAEnum
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base, generate_uuid


class AiTaskStatusEnum(str, Enum):
    PENDING = "pending"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"


class AiTaskTypeEnum(str, Enum):
    REVIEW = "review"
    SUMMARY = "summary"
    CLASSIFY = "classify"
    ANALYSIS = "analysis"


class AiReviewLog(Base):
    __tablename__ = "ai_review_log"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=generate_uuid)
    order_id: Mapped[str] = mapped_column(String(36), ForeignKey("service_order.id"), nullable=False, index=True)
    task_type: Mapped[AiTaskTypeEnum] = mapped_column(SAEnum(AiTaskTypeEnum), nullable=False)
    model_name: Mapped[str | None] = mapped_column(String(50), nullable=True)
    request_prompt: Mapped[str | None] = mapped_column(Text, nullable=True)
    response_content: Mapped[str | None] = mapped_column(Text, nullable=True)
    status: Mapped[AiTaskStatusEnum] = mapped_column(SAEnum(AiTaskStatusEnum), default=AiTaskStatusEnum.PENDING)
    confidence: Mapped[int | None] = mapped_column(Integer, nullable=True)
    category_suggestion: Mapped[str | None] = mapped_column(String(50), nullable=True)
    urgency_suggestion: Mapped[str | None] = mapped_column(String(20), nullable=True)
    risk_tags: Mapped[str | None] = mapped_column(String(500), nullable=True)
    summary: Mapped[str | None] = mapped_column(Text, nullable=True)
    error_message: Mapped[str | None] = mapped_column(Text, nullable=True)
    tokens_used: Mapped[int | None] = mapped_column(Integer, nullable=True)
    cost: Mapped[int | None] = mapped_column(Integer, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    completed_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)

    order = relationship("ServiceOrder")
