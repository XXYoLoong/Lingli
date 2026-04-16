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

"""用户管理路由"""

from datetime import datetime, timedelta
import hashlib
import random

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.user import UserAccount, RoleEnum, WorkerProfile
from app.models.email_bind import EmailBindCode
from app.schemas.user import UserResponse, UserEmailUpdate, UserEmailCodeSend, UserEmailVerify
from app.schemas.admin import UserCreateByAdmin, UserStatusUpdate, UserPasswordResetByAdmin, UserEmailUpdateByAdmin, UserUpdateByAdmin
from app.services.auth_service import hash_password
from app.services.dependencies import get_current_user, is_super_admin
from app.services.email_service import EmailService
from app.config import settings

router = APIRouter(prefix="/users", tags=["用户管理"])


def _ensure_super_admin(current_user: UserAccount) -> None:
    if not is_super_admin(current_user):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="仅小小游龙账号可进行管理操作",
        )


@router.get("/", response_model=list[UserResponse])
def list_users(
    role: RoleEnum | None = Query(None),
    db: Session = Depends(get_db),
    current_user: UserAccount = Depends(get_current_user),
):
    _ensure_super_admin(current_user)
    query = db.query(UserAccount)
    if role:
        query = query.filter(UserAccount.role == role)
    return query.order_by(UserAccount.created_at.desc()).all()


@router.post("/", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def create_user(
    payload: UserCreateByAdmin,
    db: Session = Depends(get_db),
    current_user: UserAccount = Depends(get_current_user),
):
    _ensure_super_admin(current_user)
    if db.query(UserAccount).filter(UserAccount.phone == payload.phone).first():
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="手机号已被注册")
    if db.query(UserAccount).filter(UserAccount.username == payload.username).first():
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="用户名已存在")
    if payload.email and db.query(UserAccount).filter(UserAccount.email == payload.email).first():
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="邮箱已被注册")

    user = UserAccount(
        username=payload.username,
        phone=payload.phone,
        email=payload.email,
        password_hash=hash_password(payload.password),
        role=payload.role,
        real_name=payload.real_name,
        is_active=True,
        is_verified=True,
    )
    db.add(user)
    db.flush()
    if payload.role == RoleEnum.WORKER:
        db.add(WorkerProfile(user_id=user.id, max_load=10, status="available"))
    db.commit()
    db.refresh(user)
    return user


@router.patch("/{user_id}", response_model=UserResponse)
def update_user(
    user_id: str,
    payload: UserUpdateByAdmin,
    db: Session = Depends(get_db),
    current_user: UserAccount = Depends(get_current_user),
):
    _ensure_super_admin(current_user)
    user = db.query(UserAccount).filter(UserAccount.id == user_id).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="用户不存在")

    if payload.email:
        existing = db.query(UserAccount).filter(
            UserAccount.email == payload.email,
            UserAccount.id != user.id,
        ).first()
        if existing:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="该邮箱已被其他账号使用")

    old_role = user.role
    user.real_name = payload.real_name
    user.role = payload.role
    user.email = payload.email
    user.is_verified = bool(payload.email)

    if payload.role == RoleEnum.WORKER and old_role != RoleEnum.WORKER:
        profile = db.query(WorkerProfile).filter(WorkerProfile.user_id == user.id).first()
        if not profile:
            db.add(WorkerProfile(user_id=user.id, max_load=10, status="available"))

    db.commit()
    db.refresh(user)
    return user


@router.patch("/{user_id}/status", response_model=UserResponse)
def update_user_status(
    user_id: str,
    payload: UserStatusUpdate,
    db: Session = Depends(get_db),
    current_user: UserAccount = Depends(get_current_user),
):
    _ensure_super_admin(current_user)
    user = db.query(UserAccount).filter(UserAccount.id == user_id).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="用户不存在")
    if is_super_admin(user):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="超级管理员不可被停用")
    user.is_active = payload.is_active
    db.commit()
    db.refresh(user)
    return user


@router.patch("/{user_id}/password")
def reset_user_password(
    user_id: str,
    payload: UserPasswordResetByAdmin,
    db: Session = Depends(get_db),
    current_user: UserAccount = Depends(get_current_user),
):
    _ensure_super_admin(current_user)
    user = db.query(UserAccount).filter(UserAccount.id == user_id).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="用户不存在")
    user.password_hash = hash_password(payload.new_password)
    db.commit()
    return {"message": "密码重置成功"}


@router.patch("/me/email", response_model=UserResponse)
def update_my_email(
    payload: UserEmailUpdate,
    db: Session = Depends(get_db),
    current_user: UserAccount = Depends(get_current_user),
):
    raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="请先发送并验证邮箱验证码后再绑定")


@router.post("/me/email/send-code")
def send_my_email_code(
    payload: UserEmailCodeSend,
    db: Session = Depends(get_db),
    current_user: UserAccount = Depends(get_current_user),
):
    existing = db.query(UserAccount).filter(
        UserAccount.email == payload.email,
        UserAccount.id != current_user.id,
    ).first()
    if existing:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="该邮箱已被其他账号使用")

    latest = (
        db.query(EmailBindCode)
        .filter(
            EmailBindCode.user_id == current_user.id,
            EmailBindCode.email == payload.email,
        )
        .order_by(EmailBindCode.created_at.desc())
        .first()
    )
    if latest and (datetime.utcnow() - latest.created_at).total_seconds() < settings.RESET_CODE_RESEND_SECONDS:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail=f"验证码发送过于频繁，请{settings.RESET_CODE_RESEND_SECONDS}秒后再试",
        )

    code = f"{random.randint(0, 999999):06d}"
    code_hash = hashlib.sha256(f"{current_user.id}:{payload.email}:{code}".encode("utf-8")).hexdigest()
    rec = EmailBindCode(
        user_id=current_user.id,
        email=payload.email,
        code_hash=code_hash,
        expires_at=datetime.utcnow() + timedelta(minutes=settings.RESET_CODE_EXPIRE_MINUTES),
    )
    db.add(rec)
    db.commit()
    try:
        EmailService.send_bind_code(payload.email, code)
    except Exception:
        db.delete(rec)
        db.commit()
        raise
    return {"message": "验证码已发送，请查收邮箱"}


@router.post("/me/email/verify", response_model=UserResponse)
def verify_my_email(
    payload: UserEmailVerify,
    db: Session = Depends(get_db),
    current_user: UserAccount = Depends(get_current_user),
):
    existing = db.query(UserAccount).filter(
        UserAccount.email == payload.email,
        UserAccount.id != current_user.id,
    ).first()
    if existing:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="该邮箱已被其他账号使用")

    rec = (
        db.query(EmailBindCode)
        .filter(
            EmailBindCode.user_id == current_user.id,
            EmailBindCode.email == payload.email,
            EmailBindCode.is_used == False,  # noqa: E712
            EmailBindCode.expires_at >= datetime.utcnow(),
        )
        .order_by(EmailBindCode.created_at.desc())
        .first()
    )
    if not rec:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="验证码无效或已过期")

    code_hash = hashlib.sha256(f"{current_user.id}:{payload.email}:{payload.code}".encode("utf-8")).hexdigest()
    if code_hash != rec.code_hash:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="验证码错误")

    current_user.email = payload.email
    current_user.is_verified = True
    rec.is_used = True
    rec.used_at = datetime.utcnow()
    db.commit()
    db.refresh(current_user)
    return current_user


@router.patch("/{user_id}/email", response_model=UserResponse)
def update_user_email(
    user_id: str,
    payload: UserEmailUpdateByAdmin,
    db: Session = Depends(get_db),
    current_user: UserAccount = Depends(get_current_user),
):
    _ensure_super_admin(current_user)
    user = db.query(UserAccount).filter(UserAccount.id == user_id).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="用户不存在")
    existing = db.query(UserAccount).filter(
        UserAccount.email == payload.email,
        UserAccount.id != user.id,
    ).first()
    if existing:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="该邮箱已被其他账号使用")
    user.email = payload.email
    user.is_verified = True
    db.commit()
    db.refresh(user)
    return user
