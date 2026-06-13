from pydantic import BaseModel, EmailStr, Field

from app.schemas.user import UserOut


class TokenPair(BaseModel):
    access_token: str
    refresh_token: str


class AuthResult(TokenPair):
    user: UserOut


class EmailRegister(BaseModel):
    display_name: str = Field(min_length=1, max_length=120)
    email: EmailStr
    password: str = Field(min_length=6, max_length=128)


class EmailLogin(BaseModel):
    email: EmailStr
    password: str


class PhoneRequestOtp(BaseModel):
    phone: str = Field(min_length=6, max_length=20)


class OtpRequested(BaseModel):
    sent: bool = True
    dev_code: str | None = None  # only populated in SMS mock mode


class PhoneVerifyOtp(BaseModel):
    phone: str = Field(min_length=6, max_length=20)
    code: str = Field(min_length=4, max_length=8)
    display_name: str | None = None


class GoogleSignIn(BaseModel):
    id_token: str | None = None
    access_token: str | None = None  # web OAuth2 popup flow (token client)
    # dev/mock-mode fallback fields
    dev_email: EmailStr | None = None
    dev_name: str | None = None


class AppleSignIn(BaseModel):
    id_token: str | None = None
    # dev/mock-mode fallback fields
    dev_email: EmailStr | None = None
    dev_name: str | None = None


class RefreshIn(BaseModel):
    refresh_token: str


class LogoutIn(BaseModel):
    refresh_token: str
