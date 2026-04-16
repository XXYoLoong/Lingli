"""认证相关 Schema"""

from pydantic import BaseModel, Field, EmailStr


class TokenResponse(BaseModel):
    """令牌响应"""
    access_token: str
    token_type: str = "bearer"
    expires_in: int  # 秒


class RefreshTokenRequest(BaseModel):
    """刷新令牌请求"""
    refresh_token: str = Field(..., min_length=1)


class ResetCodeSendRequest(BaseModel):
    """发送重置验证码请求"""
    email: EmailStr


class PasswordResetRequest(BaseModel):
    """验证码重置密码请求"""
    email: EmailStr
    code: str = Field(..., pattern=r"^\d{6}$")
    new_password: str = Field(..., min_length=8, max_length=128)


class PasswordChangeRequest(BaseModel):
    """登录后修改自身密码"""
    old_password: str = Field(..., min_length=1, max_length=128)
    new_password: str = Field(..., min_length=8, max_length=128)
