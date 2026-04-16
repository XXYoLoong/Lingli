"""邮件发送服务（SMTP）"""

import smtplib
from email.message import EmailMessage

from fastapi import HTTPException, status

from app.config import settings


class EmailService:
    @staticmethod
    def _send_email(email: str, subject: str, content: str) -> None:
        if settings.EMAIL_PROVIDER != "smtp":
            raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="邮件服务未启用")
        if not (
            settings.SMTP_HOST
            and settings.SMTP_PORT
            and settings.SMTP_USERNAME
            and settings.SMTP_PASSWORD
            and settings.SMTP_FROM_EMAIL
        ):
            raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="邮件服务配置不完整")

        message = EmailMessage()
        message["Subject"] = subject
        message["From"] = settings.SMTP_FROM_EMAIL
        message["To"] = email
        message.set_content(content)

        try:
            if settings.SMTP_USE_SSL:
                with smtplib.SMTP_SSL(settings.SMTP_HOST, settings.SMTP_PORT, timeout=20) as smtp:
                    smtp.login(settings.SMTP_USERNAME, settings.SMTP_PASSWORD)
                    smtp.send_message(message)
            else:
                with smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT, timeout=20) as smtp:
                    if settings.SMTP_USE_TLS:
                        smtp.starttls()
                    smtp.login(settings.SMTP_USERNAME, settings.SMTP_PASSWORD)
                    smtp.send_message(message)
        except Exception as exc:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail=f"邮件发送失败: {exc}",
            ) from exc

    @staticmethod
    def send_reset_code(email: str, code: str) -> None:
        EmailService._send_email(
            email=email,
            subject="邻里账号密码重置验证码",
            content=(
                f"您本次的密码重置验证码为：{code}\n"
                f"验证码 {settings.RESET_CODE_EXPIRE_MINUTES} 分钟内有效，请勿泄露给他人。"
            ),
        )

    @staticmethod
    def send_bind_code(email: str, code: str) -> None:
        EmailService._send_email(
            email=email,
            subject="邻里账号邮箱绑定验证码",
            content=(
                f"您本次的邮箱绑定验证码为：{code}\n"
                f"验证码 {settings.RESET_CODE_EXPIRE_MINUTES} 分钟内有效，请勿泄露给他人。"
            ),
        )
