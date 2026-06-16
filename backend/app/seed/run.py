"""Seed service categories, category↔helper-type mappings, and demo helpers.

Run with: python -m app.seed.run
Idempotent: clears and reseeds categories + curated demo helpers.
"""

import random

from app.core.config import settings
from app.core.logging import get_logger
from app.db.session import SessionLocal
from app.models.enums import DataSource, HelperType
from app.models.helper import CategoryHelperType, HelperProfile, ServiceCategory
from sqlalchemy import select

log = get_logger("seed")

# key, name, icon, sort_order, base_fare (INR), helper types
CATEGORIES = [
    (
        "puncture",
        "Puncture Fix",
        "tire_repair",
        0,
        250,
        [HelperType.puncture_shop, HelperType.mechanic],
    ),
    ("fuel", "Out of Fuel", "local_gas_station", 1, 500, [HelperType.petrol_pump]),
    ("breakdown", "Mechanic / Breakdown", "build", 2, 400, [HelperType.mechanic]),
    ("towing", "Towing Service", "fire_truck", 3, 1200, [HelperType.towing]),
    (
        "battery",
        "Jump Start",
        "battery_charging_full",
        4,
        350,
        [HelperType.battery, HelperType.mechanic],
    ),
]

DEMO_NAMES = {
    HelperType.puncture_shop: ["Sri Sai Puncture Works", "Highway Tyre Care", "QuickFix Puncture"],
    HelperType.petrol_pump: ["Indian Oil Petrol Pump", "HP Fuel Station", "Bharat Petroleum"],
    HelperType.mechanic: ["RoadKing Auto Garage", "City Mechanic Point", "24x7 Auto Repairs"],
    HelperType.towing: ["Rapid Tow Services", "City Towing Co", "Highway Recovery"],
    HelperType.battery: ["Amaron Battery Care", "Exide Jumpstart Hub", "PowerOn Batteries"],
}


def _jitter(center: float, km_spread: float) -> float:
    return center + random.uniform(-km_spread, km_spread) / 111.0


def seed() -> None:
    db = SessionLocal()
    try:
        # Categories (upsert by key)
        existing = {c.key: c for c in db.scalars(select(ServiceCategory))}
        for key, name, icon, order, base_fare, types in CATEGORIES:
            cat = existing.get(key)
            if not cat:
                cat = ServiceCategory(
                    key=key, name=name, icon=icon, sort_order=order, base_fare=base_fare
                )
                db.add(cat)
                db.flush()
            else:
                cat.name, cat.icon, cat.sort_order = name, icon, order
                cat.base_fare = base_fare  # type: ignore[assignment]
                for m in list(cat.helper_types):
                    db.delete(m)
                db.flush()
            for t in types:
                db.add(CategoryHelperType(category_id=cat.id, helper_type=t))
        db.commit()

        # Demo helpers (only if none curated yet)
        if db.scalar(select(HelperProfile).where(HelperProfile.data_source == DataSource.curated)):
            log.info("curated helpers already present; skipping helper seed")
            return

        clat, clng = settings.seed_center_lat, settings.seed_center_lng
        rng = random.Random(42)
        random.seed(42)
        for htype, names in DEMO_NAMES.items():
            for i, name in enumerate(names):
                hours = None if i == 2 else {"open": "08:00", "close": "21:00"}
                db.add(
                    HelperProfile(
                        name=name,
                        helper_type=htype,
                        phone=f"+9198{rng.randint(10000000, 99999999)}",
                        sms_capable=(i != 1),
                        latitude=_jitter(clat, 6),
                        longitude=_jitter(clng, 6),
                        address=f"{name}, Hyderabad",
                        opening_hours=hours,
                        data_source=DataSource.curated,
                        is_verified=(i == 0),
                        rating_avg=round(rng.uniform(3.5, 4.9), 1),
                        rating_count=rng.randint(5, 120),
                    )
                )
        db.commit()
        log.info("seeded categories and demo helpers around (%.4f, %.4f)", clat, clng)
    finally:
        db.close()


if __name__ == "__main__":
    seed()
