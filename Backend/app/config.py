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

    # 短信验证码配置（阿里云短信）
    SMS_PROVIDER: str = "aliyun"
    SMS_ALIYUN_ACCESS_KEY_ID: str = os.getenv("SMS_ALIYUN_ACCESS_KEY_ID", "")
    SMS_ALIYUN_ACCESS_KEY_SECRET: str = os.getenv("SMS_ALIYUN_ACCESS_KEY_SECRET", "")
    SMS_ALIYUN_SIGN_NAME: str = os.getenv("SMS_ALIYUN_SIGN_NAME", "")
    SMS_ALIYUN_TEMPLATE_CODE: str = os.getenv("SMS_ALIYUN_TEMPLATE_CODE", "")
    RESET_CODE_EXPIRE_MINUTES: int = 10
    RESET_CODE_RESEND_SECONDS: int = 60

    # 邮件验证码配置（SMTP）
    EMAIL_PROVIDER: str = "smtp"
    SMTP_HOST: str = os.getenv("SMTP_HOST", "")
    SMTP_PORT: int = int(os.getenv("SMTP_PORT", "465"))
    SMTP_USERNAME: str = os.getenv("SMTP_USERNAME", "")
    SMTP_PASSWORD: str = os.getenv("SMTP_PASSWORD", "")
    SMTP_FROM_EMAIL: str = os.getenv("SMTP_FROM_EMAIL", "")
    SMTP_USE_TLS: bool = os.getenv("SMTP_USE_TLS", "false").lower() == "true"
    SMTP_USE_SSL: bool = os.getenv("SMTP_USE_SSL", "true").lower() == "true"

    # 超级管理员（仅该账号可做系统管理）
    SUPER_ADMIN_NAME: str = "小小游龙"

    # Qwen API 配置
    DASHSCOPE_API_KEY: str = os.getenv("DASHSCOPE_API_KEY", "")
    QWEN_BASE_URL: str = "https://dashscope.aliyuncs.com/compatible-mode/v1"
    QWEN_MODEL_DEFAULT: str = "deepseek-chat"
    QWEN_MODEL_REVIEW: str = "deepseek-chat"
    QWEN_MODEL_SUMMARY: str = "deepseek-reasoner"
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
