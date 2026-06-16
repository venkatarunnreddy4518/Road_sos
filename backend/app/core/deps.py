"""Auth dependencies: resolve current user and enforce roles (Constitution II)."""

import uuid

from app.core.errors import AppError
from app.core.security import decode_access_token
from app.db.session import get_db
from app.models.user import User
from fastapi import Depends, Header
from sqlalchemy.orm import Session


def get_current_user(
    authorization: str | None = Header(default=None),
    db: Session = Depends(get_db),
) -> User:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise AppError("unauthenticated", "Authentication required.", status_code=401)
    token = authorization.split(" ", 1)[1].strip()
    user_id = decode_access_token(token)
    if not user_id:
        raise AppError("unauthenticated", "Invalid or expired token.", status_code=401)
    user = db.get(User, uuid.UUID(user_id))
    if not user:
        raise AppError("unauthenticated", "User no longer exists.", status_code=401)
    return user


def require_helper(user: User = Depends(get_current_user)) -> User:
    if not user.is_helper:
        raise AppError("forbidden", "Helper/provider role required.", status_code=403)
    return user
