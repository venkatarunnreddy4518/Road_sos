"""Profile read/update."""

from app.core.errors import AppError
from app.models.user import User
from sqlalchemy import select
from sqlalchemy.orm import Session


def update_profile(db: Session, user: User, data: dict) -> User:
    if "phone" in data and data["phone"]:
        existing = db.scalar(select(User).where(User.phone == data["phone"], User.id != user.id))
        if existing:
            raise AppError("conflict", "Phone already in use.", status_code=409)
    for key, value in data.items():
        if value is not None:
            setattr(user, key, value)
    db.commit()
    db.refresh(user)
    return user
