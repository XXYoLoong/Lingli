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

"""调度相关 Schema"""

from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
import uuid

from app.models.dispatch import DispatchStatusEnum


class DispatchCandidate(BaseModel):
    """候选服务人员"""
    worker_id: uuid.UUID
    worker_name: Optional[str] = None
    distance_score: int = 0
    type_match_score: int = 0
    load_score: int = 0
    urgency_score: int = 0
    total_score: float = 0


class DispatchRequest(BaseModel):
    """派单请求"""
    order_id: uuid.UUID
    worker_id: uuid.UUID
    dispatch_reason: Optional[str] = None


class DispatchBatchRequest(BaseModel):
    """批量派单请求"""
    order_ids: list[uuid.UUID]
    worker_ids: list[uuid.UUID]


class DispatchResponse(BaseModel):
    """调度响应"""
    id: uuid.UUID
    order_id: uuid.UUID
    station_id: uuid.UUID
    candidate_worker_id: uuid.UUID
    score: float
    status: DispatchStatusEnum
    dispatch_reason: Optional[str]
    created_at: datetime
    responded_at: Optional[datetime]

    class Config:
        from_attributes = True


class DispatchReassignRequest(BaseModel):
    """改派请求"""
    order_id: uuid.UUID
    new_worker_id: uuid.UUID
    reason: Optional[str] = None


class DispatchRejectRequest(BaseModel):
    """拒绝工单请求"""
    reason: Optional[str] = None
