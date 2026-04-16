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

"""站点相关 Schema"""

from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
import uuid


class StationCreate(BaseModel):
    """创建站点"""
    name: str = Field(..., max_length=100)
    code: str = Field(..., max_length=20)
    address: str = Field(..., max_length=255)
    contact_phone: Optional[str] = Field(None, max_length=20)
    longitude: Optional[float] = None
    latitude: Optional[float] = None
    service_radius: int = 3000
    description: Optional[str] = None


class StationUpdate(BaseModel):
    """更新站点"""
    name: Optional[str] = Field(None, max_length=100)
    address: Optional[str] = Field(None, max_length=255)
    contact_phone: Optional[str] = Field(None, max_length=20)
    longitude: Optional[float] = None
    latitude: Optional[float] = None
    service_radius: Optional[int] = None
    description: Optional[str] = None
    status: Optional[str] = None


class StationResponse(BaseModel):
    """站点响应"""
    id: uuid.UUID
    name: str
    code: str
    address: str
    contact_phone: Optional[str]
    service_radius: int
    status: str
    description: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True
