"""认证路由"""

from datetime import timedelta, datetime
import hashlib
import random

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.user import UserAccount, RoleEnum, WorkerProfile
from app.models.password_reset import PasswordResetCode
from app.schemas.user import UserCreate, UserLogin, UserResponse
from app.schemas.auth import TokenResponse, ResetCodeSendRequest, PasswordResetRequest, PasswordChangeRequest
from app.services.auth_service import hash_password, verify_password, authenticate_user, create_access_token
from app.config import settings
from app.services.dependencies import get_current_user
from app.services.email_service import EmailService

router = APIRouter(prefix="/auth", tags=["认证"])


@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def register(user_data: UserCreate, db: Session = Depends(get_db)):
    """用户注册"""
    # 检查手机号是否已存在
    existing = db.query(UserAccount).filter(
        UserAccount.phone == user_data.phone
    ).first()
    if existing:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="手机号已被注册")

    # 检查用户名是否已存在
    existing_user = db.query(UserAccount).filter(
        UserAccount.username == user_data.username
    ).first()
    if existing_user:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="用户名已存在")
    if user_data.email and db.query(UserAccount).filter(UserAccount.email == user_data.email).first():
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="邮箱已被注册")

    # 创建用户
    user = UserAccount(
        username=user_data.username,
        phone=user_data.phone,
        email=user_data.email,
        password_hash=hash_password(user_data.password),
        role=user_data.role,
        real_name=user_data.real_name,
        station_id=user_data.station_id,
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    # 如果是服务人员角色，创建档案
    if user_data.role == RoleEnum.WORKER:
        profile = WorkerProfile(user_id=user.id)
        db.add(profile)
        db.commit()

    return user


@router.post("/login", response_model=TokenResponse)
def login(login_data: UserLogin, db: Session = Depends(get_db)):
    """用户登录"""
    user = authenticate_user(db, login_data.phone, login_data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="手机号或密码错误",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # 更新最后登录时间
    user.last_login_at = datetime.utcnow()
    db.commit()

    access_token = create_access_token(
        data={"sub": str(user.id), "role": user.role.value}
    )

    return TokenResponse(
        access_token=access_token,
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
    )


@router.get("/me", response_model=UserResponse)
def get_me(current_user: UserAccount = Depends(get_current_user)):
    """获取当前用户信息"""
    return current_user


@router.post("/password/send-code")
def send_reset_code(payload: ResetCodeSendRequest, db: Session = Depends(get_db)):
    """发送重置密码验证码"""
    user = db.query(UserAccount).filter(UserAccount.email == payload.email).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="邮箱未注册")
    if not user.is_active:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="账户已停用")

    latest = (
        db.query(PasswordResetCode)
        .filter(PasswordResetCode.email == payload.email)
        .order_by(PasswordResetCode.created_at.desc())
        .first()
    )
    if latest and (datetime.utcnow() - latest.created_at).total_seconds() < settings.RESET_CODE_RESEND_SECONDS:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail=f"验证码发送过于频繁，请{settings.RESET_CODE_RESEND_SECONDS}秒后再试",
        )

    code = f"{random.randint(0, 999999):06d}"
    code_hash = hashlib.sha256(f"{payload.email}:{code}".encode("utf-8")).hexdigest()
    rec = PasswordResetCode(
        email=payload.email,
        code_hash=code_hash,
        expires_at=datetime.utcnow() + timedelta(minutes=settings.RESET_CODE_EXPIRE_MINUTES),
    )
    db.add(rec)
    db.commit()
    try:
        EmailService.send_reset_code(payload.email, code)
    except Exception:
        db.delete(rec)
        db.commit()
        raise
    return {"message": "验证码已发送，请查收邮箱"}


@router.post("/password/reset")
def reset_password(payload: PasswordResetRequest, db: Session = Depends(get_db)):
    """验证码重置密码"""
    user = db.query(UserAccount).filter(UserAccount.email == payload.email).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="邮箱未注册")

    rec = (
        db.query(PasswordResetCode)
        .filter(
            PasswordResetCode.email == payload.email,
            PasswordResetCode.is_used == False,  # noqa: E712
            PasswordResetCode.expires_at >= datetime.utcnow(),
        )
        .order_by(PasswordResetCode.created_at.desc())
        .first()
    )
    if not rec:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="验证码无效或已过期")

    code_hash = hashlib.sha256(f"{payload.email}:{payload.code}".encode("utf-8")).hexdigest()
    if code_hash != rec.code_hash:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="验证码错误")

    user.password_hash = hash_password(payload.new_password)
    rec.is_used = True
    rec.used_at = datetime.utcnow()
    db.commit()
    return {"message": "密码重置成功"}


@router.post("/password/change")
def change_password(
    payload: PasswordChangeRequest,
    db: Session = Depends(get_db),
    current_user: UserAccount = Depends(get_current_user),
):
    """登录后修改自身密码"""
    if not verify_password(payload.old_password, current_user.password_hash):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="旧密码错误")
    if payload.old_password == payload.new_password:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="新密码不能与旧密码相同")
    current_user.password_hash = hash_password(payload.new_password)
    db.commit()
    return {"message": "密码修改成功"}
