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

"""后台管理相关 Schema"""

from pydantic import BaseModel, Field, EmailStr

from app.models.user import RoleEnum


class UserCreateByAdmin(BaseModel):
    username: str = Field(..., min_length=3, max_length=50)
    phone: str = Field(..., pattern=r"^1[3-9]\d{9}$")
    email: EmailStr | None = None
    password: str = Field(..., min_length=8, max_length=128)
    real_name: str | None = Field(default=None, max_length=50)
    role: RoleEnum = RoleEnum.RESIDENT


class UserStatusUpdate(BaseModel):
    is_active: bool


class UserPasswordResetByAdmin(BaseModel):
    new_password: str = Field(..., min_length=8, max_length=128)


class UserEmailUpdateByAdmin(BaseModel):
    email: EmailStr


class UserUpdateByAdmin(BaseModel):
    real_name: str | None = Field(default=None, max_length=50)
    role: RoleEnum
    email: EmailStr | None = None
