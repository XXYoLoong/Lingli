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
    task_id: str
    status: AiTaskStatusEnum
    category_suggestion: Optional[str]
    urgency_suggestion: Optional[str]
    risk_tags: list[str] = []
    summary: Optional[str]
    confidence: Optional[float]


class AiTaskResponse(BaseModel):
    """AI 任务响应"""
    task_id: str
    order_id: str | None = None
    order_no: str | None = None
    task_type: AiTaskTypeEnum
    status: AiTaskStatusEnum
    model_name: Optional[str]
    created_at: datetime
    completed_at: Optional[datetime]
