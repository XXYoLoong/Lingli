"""数据库连接与会话管理"""

import uuid
from sqlalchemy import create_engine, event
from sqlalchemy.orm import sessionmaker, DeclarativeBase

from app.config import settings

is_sqlite = "sqlite" in settings.DATABASE_URL.lower()

connect_args = {}
if is_sqlite:
    connect_args["check_same_thread"] = False

engine = create_engine(
    settings.DATABASE_URL,
    connect_args=connect_args,
    echo=settings.DEBUG,
    pool_pre_ping=True,
)

if is_sqlite:
    @event.listens_for(engine, "connect")
    def set_sqlite_pragma(dbapi_connection, connection_record):
        cursor = dbapi_connection.cursor()
        cursor.execute("PRAGMA journal_mode=WAL")
        cursor.close()

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


class Base(DeclarativeBase):
    """所有 ORM 模型的基类"""
    pass


def generate_uuid() -> str:
    return str(uuid.uuid4())


def get_db():
    """获取数据库会话依赖，用于 FastAPI 的 Depends"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
