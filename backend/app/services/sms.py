"""SMS delivery. Uses Twilio when configured, otherwise a logged dev fallback.

Real mode requires TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, and TWILIO_FROM_NUMBER.
"""
import httpx

from app.core.config import settings
from app.core.logging import get_logger

log = get_logger(__name__)


class SmsError(Exception):
    pass


def send_sms(to: str, body: str) -> bool:
    """Send an SMS. Returns True if dispatched via a real provider, False in mock mode."""
    if settings.sms_mock_mode:
        # Never log the message body in mock mode beyond a marker (it may carry the OTP).
        log.info("SMS mock mode: would send to %s", to)
        return False

    url = f"https://api.twilio.com/2010-04-01/Accounts/{settings.twilio_account_sid}/Messages.json"
    try:
        resp = httpx.post(
            url,
            data={"To": to, "From": settings.twilio_from_number, "Body": body},
            auth=(settings.twilio_account_sid, settings.twilio_auth_token),
            timeout=10,
        )
    except httpx.HTTPError as e:  # network failure
        log.error("SMS send failed (network) to=%s: %s", to, e.__class__.__name__)
        raise SmsError("Failed to reach SMS provider.") from e

    if resp.status_code >= 300:
        log.error("SMS send rejected to=%s status=%s", to, resp.status_code)
        raise SmsError("SMS provider rejected the request.")
    log.info("SMS sent to=%s", to)
    return True
