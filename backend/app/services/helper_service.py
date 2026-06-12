"""Helper discovery, search, sync feed, and provider upsert."""
import math
import uuid
from datetime import datetime, time, timezone

from sqlalchemy import or_, select
from sqlalchemy.orm import Session

from app.core.errors import AppError
from app.models.enums import HelperType
from app.models.helper import CategoryHelperType, HelperProfile, ServiceCategory
from app.models.user import User
from app.services.geo import bounding_box, haversine_km, is_far

# Distance bands (km) used when scattering demo helpers around the user so the
# range selector / color bands have data at every radius.
_SPREAD_RADII_KM = [2.5, 4.0, 6.5, 9.0, 11.5, 14.0]


def _offset_latlng(lat: float, lng: float, dist_km: float, bearing_deg: float) -> tuple[float, float]:
    """Point [dist_km] away from (lat,lng) along [bearing_deg] (flat-earth approx)."""
    dlat = dist_km / 111.0 * math.cos(math.radians(bearing_deg))
    dlng = dist_km / (111.0 * max(math.cos(math.radians(lat)), 0.01)) * math.sin(math.radians(bearing_deg))
    return lat + dlat, lng + dlng


def spread_helpers_around(helpers: list[HelperProfile], lat: float, lng: float) -> None:
    """Reposition helpers deterministically across distance bands around (lat,lng).

    Cycles through [_SPREAD_RADII_KM] and fans them out by the golden angle so the
    same input always yields the same stable, well-distributed layout.
    """
    for i, h in enumerate(helpers):
        dist = _SPREAD_RADII_KM[i % len(_SPREAD_RADII_KM)]
        bearing = (i * 137.5) % 360.0  # golden-angle spacing avoids clustering
        h.latitude, h.longitude = _offset_latlng(lat, lng, dist, bearing)
        h.address = f"{h.name}, ~{dist:.0f} km away"


def compute_open_now(opening_hours: dict | None) -> bool | None:
    """opening_hours = {"open": "HH:MM", "close": "HH:MM"} (daily). None => unknown."""
    if not opening_hours or "open" not in opening_hours or "close" not in opening_hours:
        return None
    try:
        oh, om = map(int, opening_hours["open"].split(":"))
        ch, cm = map(int, opening_hours["close"].split(":"))
    except (ValueError, AttributeError):
        return None
    now = datetime.now(timezone.utc).time()
    open_t, close_t = time(oh, om), time(ch, cm)
    if open_t <= close_t:
        return open_t <= now <= close_t
    return now >= open_t or now <= close_t  # overnight


def _types_for_category(db: Session, category_key: str | None, helper_type: HelperType | None) -> list[HelperType]:
    if helper_type:
        return [helper_type]
    if category_key:
        cat = db.scalar(select(ServiceCategory).where(ServiceCategory.key == category_key))
        if not cat:
            return []
        return [m.helper_type for m in cat.helper_types]
    return []


def _with_distance(rows: list[HelperProfile], lat: float, lng: float) -> list[dict]:
    out = []
    for h in rows:
        dist = haversine_km(lat, lng, h.latitude, h.longitude)
        out.append(
            {
                **{c.name: getattr(h, c.name) for c in h.__table__.columns},
                "rating_avg": float(h.rating_avg),
                "distance_km": round(dist, 2),
                "is_far": is_far(dist),
                "open_now": compute_open_now(h.opening_hours),
            }
        )
    out.sort(key=lambda r: r["distance_km"])
    return out


def _ensure_helpers_nearby(db: Session, lat: float, lng: float) -> None:
    """Scatter curated helpers across distance bands around the user when the area
    is empty, so the range selector has shops at every radius (within 15 km)."""
    from app.models.enums import DataSource
    min_lat, max_lat, min_lng, max_lng = bounding_box(lat, lng, 15.0)
    exists_nearby = db.scalar(
        select(HelperProfile.id)
        .where(
            HelperProfile.is_active.is_(True),
            HelperProfile.latitude.between(min_lat, max_lat),
            HelperProfile.longitude.between(min_lng, max_lng),
        )
        .limit(1)
    )
    if not exists_nearby:
        curated_helpers = list(
            db.scalars(select(HelperProfile).where(HelperProfile.data_source == DataSource.curated))
        )
        if curated_helpers:
            spread_helpers_around(curated_helpers, lat, lng)
            db.commit()


def nearby(db: Session, lat: float, lng: float, category: str | None, helper_type: HelperType | None, limit: int) -> list[dict]:
    _ensure_helpers_nearby(db, lat, lng)
    types = _types_for_category(db, category, helper_type)
    # Coarse bounding-box pre-filter at progressively larger radii so we always return the nearest.
    for radius in (10, 25, 75, 250, 20000):
        min_lat, max_lat, min_lng, max_lng = bounding_box(lat, lng, radius)
        stmt = select(HelperProfile).where(
            HelperProfile.is_active.is_(True),
            HelperProfile.latitude.between(min_lat, max_lat),
            HelperProfile.longitude.between(min_lng, max_lng),
        )
        if types:
            stmt = stmt.where(HelperProfile.helper_type.in_(types))
        rows = list(db.scalars(stmt))
        if len(rows) >= limit or radius == 20000:
            return _with_distance(rows, lat, lng)[:limit]
    return []


def search(db: Session, q: str, lat: float | None, lng: float | None, limit: int) -> list[dict]:
    if lat is not None and lng is not None:
        _ensure_helpers_nearby(db, lat, lng)
    like = f"%{q.lower()}%"
    # Match free text against name/address, plus any helper_type whose value contains the query.
    matched_types = [t for t in HelperType if q.lower() in t.value]
    conditions = [HelperProfile.name.ilike(like), HelperProfile.address.ilike(like)]
    if matched_types:
        conditions.append(HelperProfile.helper_type.in_(matched_types))
    stmt = (
        select(HelperProfile)
        .where(HelperProfile.is_active.is_(True), or_(*conditions))
        .limit(limit)
    )
    rows = list(db.scalars(stmt))
    if lat is not None and lng is not None:
        return _with_distance(rows, lat, lng)
    return [
        {**{c.name: getattr(h, c.name) for c in h.__table__.columns}, "rating_avg": float(h.rating_avg),
         "distance_km": 0.0, "is_far": False, "open_now": compute_open_now(h.opening_hours)}
        for h in rows
    ]


def get_by_id(db: Session, helper_id: uuid.UUID) -> HelperProfile:
    h = db.get(HelperProfile, helper_id)
    if not h:
        raise AppError("not_found", "Helper not found.", status_code=404)
    return h


def sync_feed(db: Session, updated_since: datetime | None, limit: int) -> list[HelperProfile]:
    stmt = select(HelperProfile).where(HelperProfile.is_active.is_(True))
    if updated_since:
        stmt = stmt.where(HelperProfile.updated_at > updated_since)
    return list(db.scalars(stmt.order_by(HelperProfile.updated_at).limit(limit)))


def upsert_for_owner(db: Session, owner: User, data: dict) -> HelperProfile:
    existing = db.scalar(select(HelperProfile).where(HelperProfile.owner_user_id == owner.id))
    if existing:
        for k, v in data.items():
            setattr(existing, k, v)
        helper = existing
    else:
        helper = HelperProfile(owner_user_id=owner.id, **data)
        db.add(helper)
    if not owner.is_helper:
        owner.is_helper = True
    db.commit()
    db.refresh(helper)
    return helper
