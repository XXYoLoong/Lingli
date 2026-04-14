"""消息路由"""

import uuid
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.user import UserAccount
from app.models.message import Message, MessageTypeEnum
from app.schemas.message import MessageResponse
from app.services.dependencies import get_current_user

router = APIRouter(prefix="/messages", tags=["消息"])


@router.get("/", response_model=list[MessageResponse])
def get_messages(
    message_type: MessageTypeEnum | None = Query(None),
    is_read: bool | None = Query(None),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user: UserAccount = Depends(get_current_user),
):
    """获取消息列表"""
    query = db.query(Message).filter(Message.user_id == current_user.id)
    if message_type:
        query = query.filter(Message.message_type == message_type)
    if is_read is not None:
        query = query.filter(Message.is_read == is_read)

    query = query.order_by(Message.created_at.desc())
    offset = (page - 1) * page_size
    return query.offset(offset).limit(page_size).all()


@router.get("/unread-count")
def get_unread_count(
    db: Session = Depends(get_db),
    current_user: UserAccount = Depends(get_current_user),
):
    """获取未读消息数量"""
    count = db.query(Message).filter(
        Message.user_id == current_user.id,
        Message.is_read == False,
    ).count()
    return {"count": count}


@router.post("/{message_id}/read", status_code=status.HTTP_204_NO_CONTENT)
def mark_read(
    message_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: UserAccount = Depends(get_current_user),
):
    """标记消息已读"""
    message = db.query(Message).filter(Message.id == message_id).first()
    if not message:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="消息不存在")
    if message.user_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="无权操作此消息")

    from datetime import datetime
    message.is_read = True
    message.read_at = datetime.utcnow()
    db.commit()


@router.post("/read-all", status_code=status.HTTP_204_NO_CONTENT)
def mark_all_read(
    db: Session = Depends(get_db),
    current_user: UserAccount = Depends(get_current_user),
):
    """标记所有消息已读"""
    from datetime import datetime
    db.query(Message).filter(
        Message.user_id == current_user.id,
        Message.is_read == False,
    ).update({"is_read": True, "read_at": datetime.utcnow()})
    db.commit()
