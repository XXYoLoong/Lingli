"""
邻里后端服务配置
采用环境变量注入敏感配置，Qwen API Key 通过 DASHSCOPE_API_KEY 环境变量读取
"""

import os
from pathlib import Path
from pydantic_settings import BaseSettings
from typing import Optional

# 开发环境强制使用 SQLite pysqlite 驱动（避免 aiosqlite 冲突）
_os_db_url = os.environ.get("DATABASE_URL", "")
if _os_db_url and "aiosqlite" in _os_db_url:
    os.environ["DATABASE_URL"] = _os_db_url.replace("aiosqlite", "pysqlite")

BACKEND_DIR = Path(__file__).resolve().parent.parent


class Settings(BaseSettings):
    """应用配置"""

    # 应用基础配置
    APP_NAME: str = "邻里后端服务"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = False

    # 数据库配置
    DATABASE_URL: str = "sqlite+pysqlite:///./neighbor.db"
    DATABASE_POOL_SIZE: int = 5
    DATABASE_MAX_OVERFLOW: int = 10

    # Redis 配置
    REDIS_URL: str = "redis://localhost:6379/0"
    REDIS_TOKEN_EXPIRE: int = 3600 * 24  # 24 小时

    # JWT 配置
    SECRET_KEY: str = os.getenv("SECRET_KEY", "change-this-in-production")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24  # 24 小时

    # Qwen API 配置
    DASHSCOPE_API_KEY: str = os.getenv("DASHSCOPE_API_KEY", "")
    QWEN_BASE_URL: str = "https://dashscope.aliyuncs.com/compatible-mode/v1"
    QWEN_MODEL_DEFAULT: str = "qwen-plus"
    QWEN_MODEL_REVIEW: str = "qwen-plus"
    QWEN_MODEL_SUMMARY: str = "qwen-flash"
    QWEN_TIMEOUT: int = 30
    QWEN_MAX_RETRIES: int = 3

    # 文件存储配置
    UPLOAD_DIR: str = "./uploads"
    MAX_UPLOAD_SIZE: int = 10 * 1024 * 1024  # 10MB

    # CORS 配置
    CORS_ORIGINS: list[str] = ["*"]

    # 日志配置
    LOG_LEVEL: str = "INFO"

    class Config:
        env_file = str(BACKEND_DIR / ".env")
        env_file_encoding = "utf-8"
        case_sensitive = True


settings = Settings()
