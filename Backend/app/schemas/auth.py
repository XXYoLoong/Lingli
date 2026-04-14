"""认证相关 Schema"""

from pydantic import BaseModel, Field
from typing import Optional


class TokenResponse(BaseModel):
    """令牌响应"""
    access_token: str
    token_type: str = "bearer"
    expires_in: int  # 秒


class RefreshTokenRequest(BaseModel):
    """刷新令牌请求"""
    refresh_token: str = Field(..., min_length=1)
