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

"""消息相关 Schema"""

from pydantic import BaseModel
from typing import Optional
from datetime import datetime
import uuid

from app.models.message import MessageTypeEnum


class MessageResponse(BaseModel):
    """消息响应"""
    id: uuid.UUID
    user_id: uuid.UUID
    message_type: MessageTypeEnum
    title: str
    content: Optional[str]
    related_order_id: Optional[uuid.UUID]
    is_read: bool
    priority: str
    created_at: datetime
    read_at: Optional[datetime]

    class Config:
        from_attributes = True
