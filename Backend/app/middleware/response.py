"""统一响应中间件"""

from fastapi import Request
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
import uuid
from datetime import datetime


async def unified_response_middleware(request: Request, call_next):
    """统一响应格式中间件"""
    response = await call_next(request)

    # 跳过健康检查和静态资源
    if request.url.path in ("/health", "/", "/docs", "/openapi.json", "/redoc"):
        return response

    return response


class ResponseWrapper:
    """统一响应包装器"""

    @staticmethod
    def success(data=None, message="操作成功"):
        return {
            "code": 200,
            "message": message,
            "data": data,
            "requestId": str(uuid.uuid4()),
        }

    @staticmethod
    def error(code: int = 400, message: str = "操作失败", data=None):
        return {
            "code": code,
            "message": message,
            "data": data,
            "requestId": str(uuid.uuid4()),
        }

    @staticmethod
    def paginated(items: list, page: int = 1, page_size: int = 20, total: int = 0):
        return {
            "code": 200,
            "message": "操作成功",
            "data": {
                "list": items,
                "pageNo": page,
                "pageSize": page_size,
                "total": total,
            },
            "requestId": str(uuid.uuid4()),
        }
