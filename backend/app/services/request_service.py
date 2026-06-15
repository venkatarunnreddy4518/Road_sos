"""Service request lifecycle, assignment (first-accept-wins), and live location."""
import uuid
from datetime import datetime, timezone

from sqlalchemy import select, update
from sqlalchemy.orm import Session

from app.core.errors import AppError
from app.models.enums import RequestStatus
from app.models.helper import CategoryHelperType, HelperProfile, ServiceCategory
from app.models.request import HelperLocationUpdate, ServiceRequest
from app.models.user import User
from app.services.geo import haversine_km

# Allowed forward transitions performed by the assigned helper.
_TRANSITIONS = {
    RequestStatus.accepted: RequestStatus.on_the_way,
    RequestStatus.on_the_way: RequestStatus.arrived,
    RequestStatus.arrived: RequestStatus.completed,
}
_STATUS_TIMESTAMP = {
    RequestStatus.on_the_way: "on_the_way_at",
    RequestStatus.arrived: "arrived_at",
    RequestStatus.completed: "completed_at",
}
_TERMINAL = {RequestStatus.completed, RequestStatus.cancelled}

# Assumed average road speed used to turn straight-line distance into an ETA the
# seeker sees on their timeline once a helper is assigned.
_AVG_SPEED_KMH = 30.0

# A request is routed to the nearest helper first. If they don't accept within this
# window, it auto-escalates: other eligible nearby helpers start seeing it too.
_TARGET_TIMEOUT_SECONDS = 30


def _now() -> datetime:
    """Aware UTC. Columns are TIMESTAMPTZ, so storing naive datetimes would be
    misinterpreted in the server's local timezone instead of UTC."""
    return datetime.now(timezone.utc)


def _age_seconds(dt: datetime) -> float:
    # Tolerate naive datetimes (SQLite test DB) by assuming UTC.
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return (_now() - dt).total_seconds()


def _eta_minutes(distance_km: float) -> int:
    return max(1, round(distance_km / _AVG_SPEED_KMH * 60))


def _as_uuid(value) -> uuid.UUID | None:
    """Coerce an id attribute (str or UUID) to UUID for safe SQL binding."""
    if value is None or isinstance(value, uuid.UUID):
        return value
    return uuid.UUID(str(value))


def _eligible_helper_types(db: Session, category_id) -> list:
    return list(
        db.scalars(
            select(CategoryHelperType.helper_type).where(
                CategoryHelperType.category_id == _as_uuid(category_id)
            )
        )
    )


def _nearest_eligible_helper(db: Session, category_id, lat: float, lng: float) -> HelperProfile | None:
    """Closest active helper whose type serves this category (notify nearest first)."""
    types = _eligible_helper_types(db, category_id)
    if not types:
        return None
    candidates = list(
        db.scalars(
            select(HelperProfile).where(
                HelperProfile.helper_type.in_(types),
                HelperProfile.is_active.is_(True),
            )
        )
    )
    if not candidates:
        return None
    return min(candidates, key=lambda h: haversine_km(lat, lng, h.latitude, h.longitude))


def _helper_for_user(db: Session, user: User) -> HelperProfile:
    helper = db.scalar(select(HelperProfile).where(HelperProfile.owner_user_id == user.id))
    if not helper:
        raise AppError("forbidden", "No helper profile for this user.", status_code=403)
    return helper


def _latest_location(db: Session, request_id: uuid.UUID) -> HelperLocationUpdate | None:
    return db.scalar(
        select(HelperLocationUpdate)
        .where(HelperLocationUpdate.request_id == request_id)
        .order_by(HelperLocationUpdate.recorded_at.desc())
    )


def serialize(db: Session, req: ServiceRequest) -> dict:
    data = {c.name: getattr(req, c.name) for c in req.__table__.columns}
    loc = _latest_location(db, req.id) if req.status not in _TERMINAL else None
    data["helper_location"] = (
        {"latitude": loc.latitude, "longitude": loc.longitude, "recorded_at": loc.recorded_at}
        if loc
        else None
    )
    # Once a helper is assigned, surface their details + a live ETA so the seeker's
    # tracking timeline can show "who is coming and when".
    helper = db.get(HelperProfile, _as_uuid(req.helper_id)) if req.helper_id else None
    if helper:
        data["helper_name"] = helper.name
        data["helper_phone"] = helper.phone
        data["helper_type"] = helper.helper_type.value
        data["helper_rating"] = float(helper.rating_avg)
        # Use the helper's latest live position when available, else their base location.
        h_lat = loc.latitude if loc else helper.latitude
        h_lng = loc.longitude if loc else helper.longitude
        dist = haversine_km(h_lat, h_lng, req.pickup_lat, req.pickup_lng)
        data["distance_km"] = round(dist, 2)
        if req.status not in _TERMINAL:
            data["eta_minutes"] = _eta_minutes(dist)
    else:
        data["helper_name"] = None
    seeker = db.get(User, req.seeker_user_id)
    data["seeker_name"] = seeker.display_name if seeker else None
    return data


def create(db: Session, seeker: User, payload) -> ServiceRequest:
    target_helper_id = payload.target_helper_id
    if target_helper_id and not db.get(HelperProfile, target_helper_id):
        raise AppError("not_found", "Target helper not found.", status_code=404)
    # No explicit target → route the alert to the nearest eligible helper first.
    # If they decline (see `decline`), the request reopens to all nearby helpers.
    if not target_helper_id:
        nearest = _nearest_eligible_helper(
            db, payload.category_id, payload.pickup_lat, payload.pickup_lng
        )
        if nearest:
            target_helper_id = nearest.id
    req = ServiceRequest(
        seeker_user_id=seeker.id,
        category_id=payload.category_id,
        target_helper_id=target_helper_id,
        pickup_lat=payload.pickup_lat,
        pickup_lng=payload.pickup_lng,
        note=payload.note,
        status=RequestStatus.requested,
        requested_at=_now(),
    )
    db.add(req)
    db.commit()
    db.refresh(req)
    return req


def _get_participant(db: Session, request_id: uuid.UUID, user: User) -> ServiceRequest:
    req = db.get(ServiceRequest, request_id)
    if not req:
        raise AppError("not_found", "Request not found.", status_code=404)
    is_seeker = req.seeker_user_id == user.id
    helper = db.scalar(select(HelperProfile).where(HelperProfile.owner_user_id == user.id))
    is_assigned_helper = helper and req.helper_id == helper.id
    is_target_helper = helper and req.target_helper_id == helper.id
    if not (is_seeker or is_assigned_helper or is_target_helper):
        raise AppError("forbidden", "Not a participant of this request.", status_code=403)
    return req


def get(db: Session, request_id: uuid.UUID, user: User) -> ServiceRequest:
    return _get_participant(db, request_id, user)


def list_mine(db: Session, user: User, role: str, status: RequestStatus | None, active_only: bool) -> list[ServiceRequest]:
    if role == "helper":
        helper = db.scalar(select(HelperProfile).where(HelperProfile.owner_user_id == user.id))
        if not helper:
            return []
        stmt = select(ServiceRequest).where(ServiceRequest.helper_id == helper.id)
    else:
        stmt = select(ServiceRequest).where(ServiceRequest.seeker_user_id == user.id)
    if status:
        stmt = stmt.where(ServiceRequest.status == status)
    if active_only:
        stmt = stmt.where(ServiceRequest.status.notin_(list(_TERMINAL)))
    return list(db.scalars(stmt.order_by(ServiceRequest.requested_at.desc())))


def list_open_for_helper(db: Session, user: User, lat: float, lng: float, radius_km: float) -> list[dict]:
    helper = _helper_for_user(db, user)
    # categories that map to this helper's type
    cat_ids = list(
        db.scalars(
            select(CategoryHelperType.category_id).where(
                CategoryHelperType.helper_type == helper.helper_type
            )
        )
    )
    stmt = select(ServiceRequest).where(
        ServiceRequest.status == RequestStatus.requested,
        ServiceRequest.helper_id.is_(None),
    )
    reqs = list(db.scalars(stmt.order_by(ServiceRequest.requested_at.desc())))
    out = []
    for r in reqs:
        # After the timeout an unanswered targeted request escalates: drop the
        # exclusive target so any eligible nearby helper can see (and grab) it.
        expired = _age_seconds(r.requested_at) > _TARGET_TIMEOUT_SECONDS
        effective_target = None if expired else r.target_helper_id
        targeted_other = effective_target and effective_target != helper.id
        if targeted_other:
            continue
        if effective_target != helper.id and r.category_id not in cat_ids:
            continue
        dist = haversine_km(lat, lng, r.pickup_lat, r.pickup_lng)
        if dist > radius_km:
            continue
        data = {c.name: getattr(r, c.name) for c in r.__table__.columns}
        data["distance_km"] = round(dist, 2)
        seeker = db.get(User, r.seeker_user_id)
        data["seeker_name"] = seeker.display_name if seeker else None
        out.append(data)
    out.sort(key=lambda d: d["distance_km"])
    return out


def accept(db: Session, request_id: uuid.UUID, user: User) -> ServiceRequest:
    helper = _helper_for_user(db, user)
    # Atomic first-accept-wins: only updates if still unassigned & requested.
    result = db.execute(
        update(ServiceRequest)
        .where(
            ServiceRequest.id == request_id,
            ServiceRequest.status == RequestStatus.requested,
            ServiceRequest.helper_id.is_(None),
        )
        .values(helper_id=helper.id, status=RequestStatus.accepted, accepted_at=_now())
    )
    db.commit()
    if result.rowcount == 0:
        raise AppError("conflict", "Request is no longer available.", status_code=409)
    return db.get(ServiceRequest, request_id)


def decline(db: Session, request_id: uuid.UUID, user: User) -> ServiceRequest:
    req = db.get(ServiceRequest, request_id)
    if not req:
        raise AppError("not_found", "Request not found.", status_code=404)
    # Declining a targeted request reopens it as a broadcast for others.
    helper = _helper_for_user(db, user)
    if req.target_helper_id == helper.id and req.status == RequestStatus.requested:
        req.target_helper_id = None
        db.commit()
        db.refresh(req)
    return req


def update_status(db: Session, request_id: uuid.UUID, user: User, new_status: RequestStatus) -> ServiceRequest:
    helper = _helper_for_user(db, user)
    req = db.get(ServiceRequest, request_id)
    if not req or req.helper_id != helper.id:
        raise AppError("forbidden", "Only the assigned helper can update status.", status_code=403)
    if _TRANSITIONS.get(req.status) != new_status:
        raise AppError(
            "validation_error",
            f"Illegal transition {req.status.value} -> {new_status.value}.",
            status_code=422,
        )
    req.status = new_status
    setattr(req, _STATUS_TIMESTAMP[new_status], _now())
    # Finalize the fare from the category's base fee when the job completes.
    if new_status == RequestStatus.completed and req.fare_amount is None:
        base = db.scalar(
            select(ServiceCategory.base_fare).where(ServiceCategory.id == _as_uuid(req.category_id))
        )
        if base:
            req.fare_amount = base
    db.commit()
    db.refresh(req)
    return req


def cancel(db: Session, request_id: uuid.UUID, user: User) -> ServiceRequest:
    req = _get_participant(db, request_id, user)
    if req.status in _TERMINAL:
        raise AppError("validation_error", "Request already finished.", status_code=422)
    req.status = RequestStatus.cancelled
    req.cancelled_at = _now()
    req.cancelled_by = user.id
    db.commit()
    db.refresh(req)
    return req


def record_location(db: Session, request_id: uuid.UUID, user: User, lat: float, lng: float) -> datetime:
    helper = _helper_for_user(db, user)
    req = db.get(ServiceRequest, request_id)
    if not req or req.helper_id != helper.id:
        raise AppError("forbidden", "Only the assigned helper can post location.", status_code=403)
    if req.status in _TERMINAL:
        raise AppError("validation_error", "Request is not active.", status_code=422)
    now = _now()
    db.add(
        HelperLocationUpdate(
            request_id=request_id, helper_id=helper.id, latitude=lat, longitude=lng, recorded_at=now
        )
    )
    db.commit()
    return now
