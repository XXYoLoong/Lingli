"""站点路由"""

import uuid
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.user import UserAccount, RoleEnum
from app.models.station import ServiceStation
from app.schemas.station import StationCreate, StationResponse, StationUpdate
from app.services.dependencies import get_current_user, require_role

router = APIRouter(prefix="/stations", tags=["站点"])


@router.post("/", response_model=StationResponse, status_code=status.HTTP_201_CREATED)
def create_station(
    station_data: StationCreate,
    db: Session = Depends(get_db),
    current_user: UserAccount = Depends(require_role(RoleEnum.ADMIN)),
):
    """创建服务站点（仅管理员）"""
    existing = db.query(ServiceStation).filter(ServiceStation.code == station_data.code).first()
    if existing:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="站点编码已存在")

    station = ServiceStation(
        name=station_data.name,
        code=station_data.code,
        address=station_data.address,
        contact_phone=station_data.contact_phone,
        longitude=int(station_data.longitude * 1000000) if station_data.longitude else None,
        latitude=int(station_data.latitude * 1000000) if station_data.latitude else None,
        service_radius=station_data.service_radius,
        description=station_data.description,
    )
    db.add(station)
    db.commit()
    db.refresh(station)
    return station


@router.get("/", response_model=list[StationResponse])
def list_stations(
    status_filter: str | None = Query(None, alias="status"),
    db: Session = Depends(get_db),
    current_user: UserAccount = Depends(get_current_user),
):
    """获取站点列表"""
    query = db.query(ServiceStation)
    if status_filter:
        query = query.filter(ServiceStation.status == status_filter)
    return query.all()


@router.get("/{station_id}", response_model=StationResponse)
def get_station(
    station_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: UserAccount = Depends(get_current_user),
):
    """获取站点详情"""
    station = db.query(ServiceStation).filter(ServiceStation.id == station_id).first()
    if not station:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="站点不存在")
    return station


@router.patch("/{station_id}", response_model=StationResponse)
def update_station(
    station_id: uuid.UUID,
    station_data: StationUpdate,
    db: Session = Depends(get_db),
    current_user: UserAccount = Depends(require_role(RoleEnum.ADMIN, RoleEnum.STATION_MANAGER)),
):
    """更新站点信息"""
    station = db.query(ServiceStation).filter(ServiceStation.id == station_id).first()
    if not station:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="站点不存在")

    for field, value in station_data.model_dump(exclude_unset=True).items():
        if field in ("longitude", "latitude") and value is not None:
            value = int(value * 1000000)
        setattr(station, field, value)
    db.commit()
    db.refresh(station)
    return station
