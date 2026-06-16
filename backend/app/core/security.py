"""Password hashing (bcrypt) and JWT token issue/verify (Constitution II)."""

import hashlib
import secrets
from datetime import datetime, timedelta, timezone

import bcrypt
from app.core.config import settings
from jose import JWTError, jwt

# bcrypt operates on bytes and only considers the first 72 bytes of the secret.
_BCRYPT_MAX = 72


def _prepare(password: str) -> bytes:
    return password.encode("utf-8")[:_BCRYPT_MAX]


def hash_password(password: str) -> str:
    return bcrypt.hashpw(_prepare(password), bcrypt.gensalt()).decode("utf-8")


def verify_password(password: str, password_hash: str) -> bool:
    try:
        return bcrypt.checkpw(_prepare(password), password_hash.encode("utf-8"))
    except ValueError:
        return False


def hash_token(raw: str) -> str:
    """Deterministic hash for storing refresh tokens / OTP codes at rest."""
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()


def generate_token(nbytes: int = 32) -> str:
    return secrets.token_urlsafe(nbytes)


def create_access_token(user_id: str) -> str:
    now = datetime.now(timezone.utc)
    payload = {
        "sub": str(user_id),
        "type": "access",
        "iat": int(now.timestamp()),
        "exp": int((now + timedelta(minutes=settings.access_ttl_minutes)).timestamp()),
    }
    return jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)


def decode_access_token(token: str) -> str | None:
    try:
        payload = jwt.decode(token, settings.jwt_secret, algorithms=[settings.jwt_algorithm])
    except JWTError:
        return None
    if payload.get("type") != "access":
        return None
    return payload.get("sub")
