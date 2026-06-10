"""End-to-end seeker+helper request lifecycle, including live location and review."""
from sqlalchemy import select

from app.core.config import settings
from app.models.helper import HelperProfile


def _auth_header(client, email, name):
    r = client.post(
        "/api/v1/auth/email/register",
        json={"display_name": name, "email": email, "password": "secret1"},
    )
    return {"Authorization": f"Bearer {r.json()['access_token']}"}


def _make_helper_account(client, db, email, helper_type="mechanic"):
    hdr = _auth_header(client, email, "Helper")
    r = client.post(
        "/api/v1/helpers",
        headers=hdr,
        json={
            "name": "Test Garage",
            "helper_type": helper_type,
            "phone": "+919800000099",
            "latitude": settings.seed_center_lat,
            "longitude": settings.seed_center_lng,
        },
    )
    assert r.status_code == 201, r.text
    return hdr, r.json()["id"]


def test_full_lifecycle(client, seed_categories, db):
    seeker = _auth_header(client, "seeker@example.com", "Seeker")
    helper_hdr, helper_id = _make_helper_account(client, db, "helper@example.com")

    cat = client.get("/api/v1/categories").json()
    breakdown = next(c for c in cat if c["key"] == "breakdown")

    # create request
    r = client.post(
        "/api/v1/requests",
        headers=seeker,
        json={
            "category_id": breakdown["id"],
            "pickup_lat": settings.seed_center_lat,
            "pickup_lng": settings.seed_center_lng,
            "note": "Engine won't start",
        },
    )
    assert r.status_code == 201, r.text
    req_id = r.json()["id"]
    assert r.json()["status"] == "requested"

    # helper sees it open and accepts
    open_list = client.get(
        "/api/v1/requests/open",
        headers=helper_hdr,
        params={"lat": settings.seed_center_lat, "lng": settings.seed_center_lng},
    )
    assert open_list.status_code == 200
    assert any(o["id"] == req_id for o in open_list.json())

    acc = client.post(f"/api/v1/requests/{req_id}/accept", headers=helper_hdr)
    assert acc.status_code == 200
    assert acc.json()["status"] == "accepted"

    # second accept attempt fails (first-accept-wins)
    again = client.post(f"/api/v1/requests/{req_id}/accept", headers=helper_hdr)
    assert again.status_code == 409

    # advance statuses
    for status in ("on_the_way", "arrived", "completed"):
        s = client.post(f"/api/v1/requests/{req_id}/status", headers=helper_hdr, json={"status": status})
        assert s.status_code == 200, s.text
        assert s.json()["status"] == status

    # illegal transition after completion
    bad = client.post(f"/api/v1/requests/{req_id}/status", headers=helper_hdr, json={"status": "arrived"})
    assert bad.status_code == 422

    # seeker reviews
    rev = client.post(
        "/api/v1/reviews", headers=seeker, json={"request_id": req_id, "rating": 5, "comment": "Great"}
    )
    assert rev.status_code == 201, rev.text

    # duplicate review blocked
    dup = client.post("/api/v1/reviews", headers=seeker, json={"request_id": req_id, "rating": 4})
    assert dup.status_code == 409

    helper = db.scalar(select(HelperProfile).where(HelperProfile.id == helper_id))
    db.refresh(helper)
    assert helper.rating_count == 1
    assert float(helper.rating_avg) == 5.0


def test_live_location_during_active_request(client, seed_categories, db):
    seeker = _auth_header(client, "s2@example.com", "Seeker2")
    helper_hdr, _ = _make_helper_account(client, db, "h2@example.com")
    breakdown = next(c for c in client.get("/api/v1/categories").json() if c["key"] == "breakdown")
    req_id = client.post(
        "/api/v1/requests",
        headers=seeker,
        json={"category_id": breakdown["id"], "pickup_lat": 17.42, "pickup_lng": 78.47},
    ).json()["id"]
    client.post(f"/api/v1/requests/{req_id}/accept", headers=helper_hdr)
    client.post(f"/api/v1/requests/{req_id}/status", headers=helper_hdr, json={"status": "on_the_way"})

    loc = client.post(
        f"/api/v1/requests/{req_id}/location", headers=helper_hdr, json={"latitude": 17.43, "longitude": 78.48}
    )
    assert loc.status_code == 202

    seen = client.get(f"/api/v1/requests/{req_id}", headers=seeker).json()
    assert seen["helper_location"]["latitude"] == 17.43
