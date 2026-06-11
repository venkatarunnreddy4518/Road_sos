"""Authentication: email/password, phone OTP (mock fallback), Google (mock fallback)."""
import random
import uuid
from datetime import datetime, timedelta, timezone

import httpx
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.errors import AppError
from app.core.logging import get_logger
from app.core.security import (
    create_access_token,
    generate_token,
    hash_password,
    hash_token,
    verify_password,
)
from app.models.enums import AuthProvider
from app.models.user import AuthIdentity, OtpCode, RefreshToken, User
from app.services import sms

log = get_logger(__name__)
DEV_OTP = "000000"


def _now() -> datetime:
    return datetime.now(timezone.utc).replace(tzinfo=None)


def _issue_tokens(db: Session, user: User) -> dict:
    raw_refresh = generate_token()
    db.add(
        RefreshToken(
            user_id=user.id,
            token_hash=hash_token(raw_refresh),
            expires_at=_now() + timedelta(days=settings.refresh_ttl_days),
            created_at=_now(),
        )
    )
    db.commit()
    return {"access_token": create_access_token(str(user.id)), "refresh_token": raw_refresh}


def _result(db: Session, user: User) -> dict:
    return {"user": user, **_issue_tokens(db, user)}


# ---- Email + password ----

def register_email(db: Session, display_name: str, email: str, password: str) -> dict:
    if db.scalar(select(User).where(User.email == email)):
        raise AppError("conflict", "Email already registered. Please log in.", status_code=409)
    user = User(display_name=display_name, email=email)
    db.add(user)
    db.flush()
    db.add(
        AuthIdentity(
            user_id=user.id,
            provider=AuthProvider.email,
            provider_uid=email,
            password_hash=hash_password(password),
        )
    )
    db.commit()
    db.refresh(user)
    log.info("user registered via email user_id=%s", user.id)
    return _result(db, user)


def login_email(db: Session, email: str, password: str) -> dict:
    identity = db.scalar(
        select(AuthIdentity).where(
            AuthIdentity.provider == AuthProvider.email, AuthIdentity.provider_uid == email
        )
    )
    if not identity or not identity.password_hash or not verify_password(password, identity.password_hash):
        raise AppError("unauthenticated", "Invalid email or password.", status_code=401)
    user = db.get(User, identity.user_id)
    return _result(db, user)


# ---- Phone OTP (mock fallback when no SMS provider) ----

def request_otp(db: Session, phone: str) -> dict:
    code = DEV_OTP if settings.sms_mock_mode else f"{random.randint(0, 999999):06d}"
    db.add(
        OtpCode(
            phone=phone,
            code_hash=hash_token(code),
            expires_at=_now() + timedelta(minutes=5),
            created_at=_now(),
        )
    )
    db.commit()
    if settings.sms_mock_mode:
        log.info("OTP requested (dev mode) phone=%s", phone)  # never log the code in prod paths
        return {"sent": True, "dev_code": code}

    # Real delivery via the configured SMS provider (Twilio).
    sms.send_sms(phone, f"Your Roadside Help verification code is {code}. It expires in 5 minutes.")
    log.info("OTP requested phone=%s", phone)
    return {"sent": True, "dev_code": None}


def verify_otp(db: Session, phone: str, code: str, display_name: str | None) -> dict:
    otp = db.scalar(
        select(OtpCode)
        .where(OtpCode.phone == phone, OtpCode.consumed_at.is_(None))
        .order_by(OtpCode.created_at.desc())
    )
    valid = otp and otp.expires_at > _now() and otp.code_hash == hash_token(code)
    # Allow the fixed dev code in mock mode as a convenience.
    if not valid and not (settings.sms_mock_mode and code == DEV_OTP):
        raise AppError("unauthenticated", "Invalid or expired code.", status_code=401)
    if otp:
        otp.consumed_at = _now()

    user = db.scalar(select(User).where(User.phone == phone))
    if not user:
        user = User(display_name=display_name or f"User {phone[-4:]}", phone=phone)
        db.add(user)
        db.flush()
        db.add(AuthIdentity(user_id=user.id, provider=AuthProvider.phone, provider_uid=phone))
    db.commit()
    db.refresh(user)
    return _result(db, user)


# ---- Google (mock fallback when no client id) ----

_GOOGLE_ISSUERS = {"accounts.google.com", "https://accounts.google.com"}


def _verify_google_token(id_token: str) -> dict:
    """Verify a Google ID token server-side: signature/expiry via tokeninfo, then
    audience and issuer checks against the configured client id(s)."""
    try:
        resp = httpx.get(
            "https://oauth2.googleapis.com/tokeninfo", params={"id_token": id_token}, timeout=10
        )
    except httpx.HTTPError as e:
        raise AppError("unauthenticated", "Could not verify Google token.", status_code=401) from e
    if resp.status_code != 200:
        raise AppError("unauthenticated", "Invalid Google token.", status_code=401)
    data = resp.json()

    if data.get("aud") not in settings.google_client_ids:
        raise AppError("unauthenticated", "Google token audience mismatch.", status_code=401)
    if data.get("iss") not in _GOOGLE_ISSUERS:
        raise AppError("unauthenticated", "Google token issuer mismatch.", status_code=401)
    if data.get("email_verified") in ("false", False):
        raise AppError("unauthenticated", "Google email not verified.", status_code=401)

    return {"sub": data["sub"], "email": data.get("email"), "name": data.get("name", "Google User")}


def google_sign_in(db: Session, id_token: str | None, dev_email: str | None, dev_name: str | None) -> dict:
    if settings.google_mock_mode:
        if not dev_email:
            raise AppError("validation_error", "dev_email required in Google mock mode.", status_code=422)
        profile = {"sub": f"google-dev:{dev_email}", "email": dev_email, "name": dev_name or "Google User"}
    else:
        if not id_token:
            raise AppError("validation_error", "id_token required.", status_code=422)
        profile = _verify_google_token(id_token)

    identity = db.scalar(
        select(AuthIdentity).where(
            AuthIdentity.provider == AuthProvider.google, AuthIdentity.provider_uid == profile["sub"]
        )
    )
    if identity:
        user = db.get(User, identity.user_id)
    else:
        user = db.scalar(select(User).where(User.email == profile["email"])) if profile["email"] else None
        if not user:
            user = User(display_name=profile["name"], email=profile["email"])
            db.add(user)
            db.flush()
        db.add(AuthIdentity(user_id=user.id, provider=AuthProvider.google, provider_uid=profile["sub"]))
    db.commit()
    db.refresh(user)
    return _result(db, user)


# ---- Refresh / logout ----

def refresh(db: Session, raw_refresh: str) -> dict:
    token = db.scalar(select(RefreshToken).where(RefreshToken.token_hash == hash_token(raw_refresh)))
    if not token or token.revoked_at or token.expires_at < _now():
        raise AppError("unauthenticated", "Invalid or expired refresh token.", status_code=401)
    token.revoked_at = _now()  # rotate
    user = db.get(User, token.user_id)
    return _issue_tokens(db, user)


def logout(db: Session, raw_refresh: str) -> None:
    token = db.scalar(select(RefreshToken).where(RefreshToken.token_hash == hash_token(raw_refresh)))
    if token and not token.revoked_at:
        token.revoked_at = _now()
        db.commit()
