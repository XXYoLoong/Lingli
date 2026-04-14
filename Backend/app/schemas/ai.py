"""AI 相关 Schema"""

from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
import uuid

from app.models.ai_log import AiTaskTypeEnum, AiTaskStatusEnum


class AiTaskRequest(BaseModel):
    """AI 任务请求"""
    order_id: uuid.UUID
    task_type: AiTaskTypeEnum = AiTaskTypeEnum.REVIEW
    force: bool = False  # 强制重新生成


class AiReviewResponse(BaseModel):
    """AI 审核响应"""
    task_id: uuid.UUID
    status: AiTaskStatusEnum
    category_suggestion: Optional[str]
    urgency_suggestion: Optional[str]
    risk_tags: list[str] = []
    summary: Optional[str]
    confidence: Optional[float]


class AiTaskResponse(BaseModel):
    """AI 任务响应"""
    task_id: uuid.UUID
    task_type: AiTaskTypeEnum
    status: AiTaskStatusEnum
    model_name: Optional[str]
    created_at: datetime
    completed_at: Optional[datetime]
