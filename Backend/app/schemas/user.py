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

"""用户相关 Schema"""

from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import datetime
import uuid

from app.models.user import RoleEnum


class UserCreate(BaseModel):
    """创建用户"""
    username: str = Field(..., min_length=3, max_length=50)
    phone: str = Field(..., pattern=r"^1[3-9]\d{9}$")
    email: Optional[EmailStr] = None
    password: str = Field(..., min_length=8, max_length=128)
    role: RoleEnum = RoleEnum.RESIDENT
    real_name: Optional[str] = Field(None, max_length=50)
    station_id: Optional[uuid.UUID] = None


class UserLogin(BaseModel):
    """用户登录"""
    phone: str = Field(..., pattern=r"^1[3-9]\d{9}$")
    password: str = Field(..., min_length=1, max_length=128)


class UserUpdate(BaseModel):
    """更新用户信息"""
    real_name: Optional[str] = None
    email: Optional[EmailStr] = None
    avatar_url: Optional[str] = None
    station_id: Optional[uuid.UUID] = None


class UserEmailUpdate(BaseModel):
    """用户绑定或修改邮箱"""
    email: EmailStr


class UserEmailCodeSend(BaseModel):
    """发送邮箱绑定验证码"""
    email: EmailStr


class UserEmailVerify(BaseModel):
    """验证邮箱绑定验证码"""
    email: EmailStr
    code: str = Field(..., pattern=r"^\d{6}$")


class WorkerProfileCreate(BaseModel):
    """创建服务人员档案"""
    service_types: list[str] = []
    id_number: Optional[str] = None
    certificate_url: Optional[str] = None
    max_load: int = 10


class UserResponse(BaseModel):
    """用户响应"""
    id: uuid.UUID
    username: str
    phone: str
    email: Optional[str]
    role: RoleEnum
    real_name: Optional[str]
    avatar_url: Optional[str]
    is_active: bool
    is_verified: bool
    station_id: Optional[uuid.UUID]
    created_at: datetime

    class Config:
        from_attributes = True
