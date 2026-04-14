"""工单相关 Schema"""

from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
import uuid

from app.models.order import OrderStatusEnum


class OrderCreate(BaseModel):
    """创建工单"""
    service_type: str = Field(..., max_length=50)
    title: str = Field(..., max_length=200)
    description: Optional[str] = None
    voice_transcript: Optional[str] = None
    contact_name: Optional[str] = Field(None, max_length=50)
    contact_phone: Optional[str] = Field(None, max_length=20)
    service_address: Optional[str] = Field(None, max_length=255)
    longitude: Optional[int] = None
    latitude: Optional[int] = None
    appointment_time: Optional[datetime] = None
    attachment_keys: list[str] = []


class OrderUpdate(BaseModel):
    """更新工单"""
    title: Optional[str] = Field(None, max_length=200)
    description: Optional[str] = None
    contact_name: Optional[str] = Field(None, max_length=50)
    contact_phone: Optional[str] = Field(None, max_length=20)
    service_address: Optional[str] = Field(None, max_length=255)
    appointment_time: Optional[datetime] = None


class OrderCheckIn(BaseModel):
    """签到请求"""
    check_in_code: str = Field(..., max_length=20)
    longitude: Optional[int] = None
    latitude: Optional[int] = None


class OrderComplete(BaseModel):
    """完成工单"""
    service_result: str
    attachment_keys: list[str] = []
    abnormal_flag: bool = False
    abnormal_reason: Optional[str] = None


class OrderAttachmentResponse(BaseModel):
    """工单附件"""
    id: uuid.UUID
    file_key: str
    file_path: str
    file_name: str
    mime_type: Optional[str]
    attachment_type: str
    created_at: datetime

    class Config:
        from_attributes = True


class OrderResponse(BaseModel):
    """工单响应"""
    id: uuid.UUID
    order_no: str
    station_id: uuid.UUID
    service_type: str
    title: str
    description: Optional[str]
    contact_name: Optional[str]
    contact_phone: Optional[str]
    service_address: Optional[str]
    appointment_time: Optional[datetime]
    status: OrderStatusEnum
    urgency_level: str
    ai_category: Optional[str]
    ai_risk_tags: Optional[str]
    ai_summary: Optional[str]
    assigned_worker_id: Optional[uuid.UUID]
    service_result: Optional[str]
    abnormal_flag: bool
    created_at: datetime
    updated_at: datetime
    completed_at: Optional[datetime]
    attachments: list[OrderAttachmentResponse] = []

    class Config:
        from_attributes = True
