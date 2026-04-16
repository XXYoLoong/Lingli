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
