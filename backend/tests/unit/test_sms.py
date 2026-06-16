"""SMS provider behavior in mock mode (no network)."""

from app.core.config import settings
from app.services import sms


def test_send_sms_mock_mode_returns_false(monkeypatch):
    # Force mock mode regardless of environment.
    monkeypatch.setattr(settings, "twilio_account_sid", None)
    monkeypatch.setattr(settings, "twilio_auth_token", None)
    monkeypatch.setattr(settings, "twilio_from_number", None)
    assert settings.sms_mock_mode is True
    assert sms.send_sms("+919800000000", "code 123456") is False


def test_real_mode_detected_when_all_creds_set(monkeypatch):
    monkeypatch.setattr(settings, "twilio_account_sid", "ACxxxx")
    monkeypatch.setattr(settings, "twilio_auth_token", "tok")
    monkeypatch.setattr(settings, "twilio_from_number", "+10000000000")
    assert settings.sms_mock_mode is False
