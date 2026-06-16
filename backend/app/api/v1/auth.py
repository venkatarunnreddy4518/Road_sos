from app.core.deps import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.auth import (
    AppleSignIn,
    AuthResult,
    EmailLogin,
    EmailRegister,
    GoogleSignIn,
    LogoutIn,
    OtpRequested,
    PhoneRequestOtp,
    PhoneVerifyOtp,
    RefreshIn,
    TokenPair,
)
from app.schemas.user import UserOut
from app.services import auth_service
from fastapi import APIRouter, Depends, Response
from sqlalchemy.orm import Session

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/email/register", response_model=AuthResult, status_code=201)
def email_register(body: EmailRegister, db: Session = Depends(get_db)):
    return auth_service.register_email(db, body.display_name, body.email, body.password)


@router.post("/email/login", response_model=AuthResult)
def email_login(body: EmailLogin, db: Session = Depends(get_db)):
    return auth_service.login_email(db, body.email, body.password)


@router.post("/phone/request-otp", response_model=OtpRequested)
def request_otp(body: PhoneRequestOtp, db: Session = Depends(get_db)):
    return auth_service.request_otp(db, body.phone)


@router.post("/phone/verify-otp", response_model=AuthResult)
def verify_otp(body: PhoneVerifyOtp, db: Session = Depends(get_db)):
    return auth_service.verify_otp(db, body.phone, body.code, body.display_name)


@router.post("/google", response_model=AuthResult)
def google(body: GoogleSignIn, db: Session = Depends(get_db)):
    return auth_service.google_sign_in(
        db, body.id_token, body.dev_email, body.dev_name, body.access_token
    )


@router.post("/apple", response_model=AuthResult)
def apple(body: AppleSignIn, db: Session = Depends(get_db)):
    return auth_service.apple_sign_in(db, body.id_token, body.dev_email, body.dev_name)


@router.post("/refresh", response_model=TokenPair)
def refresh(body: RefreshIn, db: Session = Depends(get_db)):
    return auth_service.refresh(db, body.refresh_token)


@router.post("/logout", status_code=204)
def logout(body: LogoutIn, db: Session = Depends(get_db), _: User = Depends(get_current_user)):
    auth_service.logout(db, body.refresh_token)
    return Response(status_code=204)


@router.get("/me", response_model=UserOut)
def me(user: User = Depends(get_current_user)):
    return user
