"""Service category listing."""

from app.models.helper import ServiceCategory
from sqlalchemy import select
from sqlalchemy.orm import Session


def list_categories(db: Session) -> list[dict]:
    cats = db.scalars(select(ServiceCategory).order_by(ServiceCategory.sort_order))
    return [
        {
            "id": c.id,
            "key": c.key,
            "name": c.name,
            "icon": c.icon,
            "sort_order": c.sort_order,
            "helper_types": [m.helper_type for m in c.helper_types],
        }
        for c in cats
    ]
