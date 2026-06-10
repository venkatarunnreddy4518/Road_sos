"""Contract tests for /profile and /reviews (+ helper reviews aggregate) — US4."""
from app.core.config import settings


def _register(client, email, name="User"):
    r = client.post(
        "/api/v1/auth/email/register",
        json={"display_name": name, "email": email, "password": "secret1"},
    )
    return {"Authorization": f"Bearer {r.json()['access_token']}"}


def _make_helper(client, email):
    hdr = _register(client, email, "Helper")
    hid = client.post(
        "/api/v1/helpers",
        headers=hdr,
        json={
            "name": "Garage",
            "helper_type": "mechanic",
            "latitude": settings.seed_center_lat,
            "longitude": settings.seed_center_lng,
        },
    ).json()["id"]
    return hdr, hid


def _completed_request(client, seeker, helper_hdr):
    cat = next(c for c in client.get("/api/v1/categories").json() if c["key"] == "breakdown")
    rid = client.post(
        "/api/v1/requests",
        headers=seeker,
        json={"category_id": cat["id"], "pickup_lat": settings.seed_center_lat, "pickup_lng": settings.seed_center_lng},
    ).json()["id"]
    client.post(f"/api/v1/requests/{rid}/accept", headers=helper_hdr)
    for s in ("on_the_way", "arrived", "completed"):
        client.post(f"/api/v1/requests/{rid}/status", headers=helper_hdr, json={"status": s})
    return rid


def test_profile_get_and_patch(client, seed_categories):
    hdr = _register(client, "prof@example.com", "Asha")
    me = client.get("/api/v1/profile", headers=hdr)
    assert me.status_code == 200 and me.json()["display_name"] == "Asha"

    upd = client.patch("/api/v1/profile", headers=hdr,
                       json={"display_name": "Asha K", "vehicle_info": "Honda Activa", "preferred_language": "hi"})
    assert upd.status_code == 200
    body = upd.json()
    assert body["display_name"] == "Asha K"
    assert body["vehicle_info"] == "Honda Activa"
    assert body["preferred_language"] == "hi"


def test_review_rules_and_aggregate(client, seed_categories):
    seeker = _register(client, "rev_seeker@example.com")
    helper_hdr, hid = _make_helper(client, "rev_helper@example.com")
    rid = _completed_request(client, seeker, helper_hdr)

    # out-of-range rejected by schema (422)
    bad = client.post("/api/v1/reviews", headers=seeker, json={"request_id": rid, "rating": 6})
    assert bad.status_code == 422

    ok = client.post("/api/v1/reviews", headers=seeker, json={"request_id": rid, "rating": 4, "comment": "Good"})
    assert ok.status_code == 201

    # one review per request (409)
    dup = client.post("/api/v1/reviews", headers=seeker, json={"request_id": rid, "rating": 5})
    assert dup.status_code == 409

    agg = client.get(f"/api/v1/helpers/{hid}/reviews")
    assert agg.status_code == 200
    body = agg.json()
    assert body["rating_count"] == 1
    assert body["rating_avg"] == 4.0
    assert len(body["reviews"]) == 1


def test_only_seeker_can_review(client, seed_categories):
    seeker = _register(client, "rs@example.com")
    helper_hdr, _ = _make_helper(client, "rh@example.com")
    rid = _completed_request(client, seeker, helper_hdr)
    other = _register(client, "intruder@example.com")
    r = client.post("/api/v1/reviews", headers=other, json={"request_id": rid, "rating": 5})
    assert r.status_code == 403
