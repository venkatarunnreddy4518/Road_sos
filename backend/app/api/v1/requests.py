import uuid

from fastapi import APIRouter, Depends, Query, Response
from sqlalchemy.orm import Session

from app.core.deps import get_current_user, require_helper
from app.db.session import get_db
from app.models.enums import RequestStatus
from app.models.user import User
from app.schemas.request import (
    LocationIn,
    OpenRequestForHelper,
    RequestCreate,
    ServiceRequestOut,
    StatusUpdate,
)
from app.services import request_service

router = APIRouter(prefix="/requests", tags=["requests"])


@router.post("", response_model=ServiceRequestOut, status_code=201)
def create(body: RequestCreate, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    req = request_service.create(db, user, body)
    return request_service.serialize(db, req)


@router.get("/mine", response_model=list[ServiceRequestOut])
def mine(
    role: str = Query("seeker", pattern="^(seeker|helper)$"),
    status: RequestStatus | None = None,
    active_only: bool = False,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    reqs = request_service.list_mine(db, user, role, status, active_only)
    return [request_service.serialize(db, r) for r in reqs]


@router.get("/open", response_model=list[OpenRequestForHelper])
def open_requests(
    lat: float = Query(...),
    lng: float = Query(...),
    radius_km: float = Query(50, ge=1, le=500),
    db: Session = Depends(get_db),
    user: User = Depends(require_helper),
):
    return request_service.list_open_for_helper(db, user, lat, lng, radius_km)


@router.get("/{request_id}", response_model=ServiceRequestOut)
def get(request_id: uuid.UUID, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    req = request_service.get(db, request_id, user)
    return request_service.serialize(db, req)


@router.post("/{request_id}/accept", response_model=ServiceRequestOut)
def accept(request_id: uuid.UUID, db: Session = Depends(get_db), user: User = Depends(require_helper)):
    req = request_service.accept(db, request_id, user)
    return request_service.serialize(db, req)


@router.post("/{request_id}/decline", response_model=ServiceRequestOut)
def decline(request_id: uuid.UUID, db: Session = Depends(get_db), user: User = Depends(require_helper)):
    req = request_service.decline(db, request_id, user)
    return request_service.serialize(db, req)


@router.post("/{request_id}/status", response_model=ServiceRequestOut)
def update_status(
    request_id: uuid.UUID,
    body: StatusUpdate,
    db: Session = Depends(get_db),
    user: User = Depends(require_helper),
):
    req = request_service.update_status(db, request_id, user, body.status)
    return request_service.serialize(db, req)


@router.post("/{request_id}/cancel", response_model=ServiceRequestOut)
def cancel(request_id: uuid.UUID, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    req = request_service.cancel(db, request_id, user)
    return request_service.serialize(db, req)


@router.post("/{request_id}/location", status_code=202)
def post_location(
    request_id: uuid.UUID,
    body: LocationIn,
    db: Session = Depends(get_db),
    user: User = Depends(require_helper),
):
    recorded_at = request_service.record_location(db, request_id, user, body.latitude, body.longitude)
    return {"recorded_at": recorded_at.isoformat()}
