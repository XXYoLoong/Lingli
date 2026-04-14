"""统计相关 Schema"""

from pydantic import BaseModel
from typing import Optional


class StationStats(BaseModel):
    """站点统计"""
    station_id: str
    station_name: str
    total_orders: int
    completed_orders: int
    completion_rate: float
    by_status: dict[str, int] = {}
    by_type: dict[str, int] = {}


class OrderStats(BaseModel):
    """工单统计"""
    total: int = 0
    by_status: dict[str, int] = {}
    by_type: dict[str, int] = {}
