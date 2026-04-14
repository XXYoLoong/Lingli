"""认证路由"""

from datetime import timedelta

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.user import UserAccount, RoleEnum, WorkerProfile
from app.schemas.user import UserCreate, UserLogin, UserResponse
from app.schemas.auth import TokenResponse
from app.services.auth_service import hash_password, authenticate_user, create_access_token
from app.config import settings
from app.services.dependencies import get_current_user

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
    from datetime import datetime
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
