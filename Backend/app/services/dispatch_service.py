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

"""调度算法服务"""

import uuid
from app.models.order import ServiceOrder
from app.models.user import WorkerProfile
from app.schemas.dispatch import DispatchCandidate
from sqlalchemy.orm import Session

# 派单评分权重配置
WEIGHT_DISTANCE = 0.30
WEIGHT_TYPE_MATCH = 0.30
WEIGHT_LOAD = 0.20
WEIGHT_URGENCY = 0.20


def calculate_dispatch_scores(db: Session, order: ServiceOrder, workers: list[WorkerProfile]) -> list[DispatchCandidate]:
    """计算所有候选服务人员的综合派单得分"""
    candidates = []

    for worker in workers:
        distance_score = _calc_distance_score(order, worker)
        type_match_score = _calc_type_match_score(order, worker)
        load_score = _calc_load_score(worker)
        urgency_score = _calc_urgency_score(order)

        total = (
            distance_score * WEIGHT_DISTANCE +
            type_match_score * WEIGHT_TYPE_MATCH +
            load_score * WEIGHT_LOAD +
            urgency_score * WEIGHT_URGENCY
        )

        # 获取用户名
        from app.models.user import UserAccount
        user = db.query(UserAccount).filter(UserAccount.id == worker.user_id).first()

        candidates.append(DispatchCandidate(
            worker_id=worker.user_id,
            worker_name=user.real_name if user else None,
            distance_score=int(distance_score * 100),
            type_match_score=int(type_match_score * 100),
            load_score=int(load_score * 100),
            urgency_score=int(urgency_score * 100),
            total_score=round(total * 100, 2),
        ))

    return candidates


def _calc_distance_score(order: ServiceOrder, worker: WorkerProfile) -> float:
    """计算距离得分 (0-1)"""
    if not order.longitude or not order.latitude:
        return 0.5  # 无法计算距离时给中间分

    # 简化计算：实际应使用 Haversine 公式，这里用简化的欧几里得近似
    # 假设站点有经纬度信息，这里从 worker 所在站点获取
    from app.models.station import ServiceStation
    station = None  # 需要通过 worker 关联获取站点
    if not station or not station.longitude or not station.latitude:
        return 0.5

    # 简化距离计算（实际应使用地理距离公式）
    delta_lon = (order.longitude - station.longitude) / 1000000  # 转回实际经纬度
    delta_lat = (order.latitude - station.latitude) / 1000000

    # 近似距离（度）
    approx_distance = (delta_lon ** 2 + delta_lat ** 2) ** 0.5

    # 转换为得分：距离越近得分越高，3km 以内满分
    max_distance = 0.03  # 约 3km（纬度）
    return max(0, 1 - approx_distance / max_distance)


def _calc_type_match_score(order: ServiceOrder, worker: WorkerProfile) -> float:
    """计算服务类型匹配得分 (0-1)"""
    if not worker.service_types:
        return 0.5

    # 服务类型简单匹配
    import json
    try:
        types = json.loads(worker.service_types)
        if order.service_type in types:
            return 1.0
        return 0.3
    except (json.JSONDecodeError, TypeError):
        return 0.5


def _calc_load_score(worker: WorkerProfile) -> float:
    """计算负载得分 (0-1)，负载越低得分越高"""
    if worker.max_load <= 0:
        return 0
    remaining_ratio = (worker.max_load - worker.current_load) / worker.max_load
    return min(1.0, remaining_ratio)


def _calc_urgency_score(order: ServiceOrder) -> float:
    """根据紧急程度得分"""
    urgency_map = {"low": 0.3, "normal": 0.5, "high": 0.8, "urgent": 1.0}
    return urgency_map.get(order.urgency_level, 0.5)
