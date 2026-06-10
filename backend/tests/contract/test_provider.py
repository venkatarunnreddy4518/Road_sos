"""Contract tests for the provider side (US3): helper upsert, open list, accept/decline."""
from app.core.config import settings


def _register(client, email, name="User"):
    r = client.post(
        "/api/v1/auth/email/register",
        json={"display_name": name, "email": email, "password": "secret1"},
    )
    return {"Authorization": f"Bearer {r.json()['access_token']}"}


def _make_helper(client, email, helper_type="mechanic"):
    hdr = _register(client, email, "Helper")
    r = client.post(
        "/api/v1/helpers",
        headers=hdr,
        json={
            "name": "Test Service",
            "helper_type": helper_type,
            "phone": "+919800000010",
            "latitude": settings.seed_center_lat,
            "longitude": settings.seed_center_lng,
        },
    )
    assert r.status_code == 201, r.text
    return hdr


def _category(client, key="breakdown"):
    return next(c for c in client.get("/api/v1/categories").json() if c["key"] == key)


def test_open_requires_helper_role(client, seed_categories):
    seeker = _register(client, "plain@example.com")
    r = client.get("/api/v1/requests/open", headers=seeker,
                   params={"lat": settings.seed_center_lat, "lng": settings.seed_center_lng})
    assert r.status_code == 403  # not a helper


def test_helper_upsert_sets_role_and_lists_open(client, seed_categories):
    helper = _make_helper(client, "prov@example.com")
    me = client.get("/api/v1/auth/me", headers=helper)
    assert me.json()["is_helper"] is True

    seeker = _register(client, "seekprov@example.com")
    cat = _category(client)
    rid = client.post("/api/v1/requests", headers=seeker,
                      json={"category_id": cat["id"], "pickup_lat": settings.seed_center_lat,
                            "pickup_lng": settings.seed_center_lng}).json()["id"]

    open_list = client.get("/api/v1/requests/open", headers=helper,
                           params={"lat": settings.seed_center_lat, "lng": settings.seed_center_lng})
    assert open_list.status_code == 200
    ids = [o["id"] for o in open_list.json()]
    assert rid in ids
    assert all("distance_km" in o for o in open_list.json())


def test_accept_then_status_and_location(client, seed_categories):
    helper = _make_helper(client, "acc@example.com")
    seeker = _register(client, "accseek@example.com")
    cat = _category(client)
    rid = client.post("/api/v1/requests", headers=seeker,
                      json={"category_id": cat["id"], "pickup_lat": settings.seed_center_lat,
                            "pickup_lng": settings.seed_center_lng}).json()["id"]

    acc = client.post(f"/api/v1/requests/{rid}/accept", headers=helper)
    assert acc.status_code == 200 and acc.json()["status"] == "accepted"

    bad = client.post(f"/api/v1/requests/{rid}/status", headers=helper, json={"status": "arrived"})
    assert bad.status_code == 422  # must go on_the_way first

    ok = client.post(f"/api/v1/requests/{rid}/status", headers=helper, json={"status": "on_the_way"})
    assert ok.status_code == 200

    loc = client.post(f"/api/v1/requests/{rid}/location", headers=helper,
                      json={"latitude": 17.45, "longitude": 78.45})
    assert loc.status_code == 202
