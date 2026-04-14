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
