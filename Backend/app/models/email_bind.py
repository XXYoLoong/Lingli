"""邮箱绑定验证码模型"""

from datetime import datetime

from sqlalchemy import String, DateTime, Boolean, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base, generate_uuid


class EmailBindCode(Base):
    __tablename__ = "email_bind_code"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=generate_uuid)
    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("user_account.id"), nullable=False, index=True)
    email: Mapped[str] = mapped_column(String(100), nullable=False, index=True)
    code_hash: Mapped[str] = mapped_column(String(128), nullable=False)
    is_used: Mapped[bool] = mapped_column(Boolean, default=False)
    expires_at: Mapped[datetime] = mapped_column(DateTime, nullable=False, index=True)
    used_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, index=True)
