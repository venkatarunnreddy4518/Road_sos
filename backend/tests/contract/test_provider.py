"""Contract tests for the provider side (US3): helper upsert, open list, accept/decline."""

from app.core.config import settings
from app.services import request_service


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
    r = client.get(
        "/api/v1/requests/open",
        headers=seeker,
        params={"lat": settings.seed_center_lat, "lng": settings.seed_center_lng},
    )
    assert r.status_code == 403  # not a helper


def test_helper_upsert_sets_role_and_lists_open(client, seed_categories):
    helper = _make_helper(client, "prov@example.com")
    me = client.get("/api/v1/auth/me", headers=helper)
    assert me.json()["is_helper"] is True

    seeker = _register(client, "seekprov@example.com")
    cat = _category(client)
    rid = client.post(
        "/api/v1/requests",
        headers=seeker,
        json={
            "category_id": cat["id"],
            "pickup_lat": settings.seed_center_lat,
            "pickup_lng": settings.seed_center_lng,
        },
    ).json()["id"]

    open_list = client.get(
        "/api/v1/requests/open",
        headers=helper,
        params={"lat": settings.seed_center_lat, "lng": settings.seed_center_lng},
    )
    assert open_list.status_code == 200
    ids = [o["id"] for o in open_list.json()]
    assert rid in ids
    assert all("distance_km" in o for o in open_list.json())


def test_accept_then_status_and_location(client, seed_categories):
    helper = _make_helper(client, "acc@example.com")
    seeker = _register(client, "accseek@example.com")
    cat = _category(client)
    rid = client.post(
        "/api/v1/requests",
        headers=seeker,
        json={
            "category_id": cat["id"],
            "pickup_lat": settings.seed_center_lat,
            "pickup_lng": settings.seed_center_lng,
        },
    ).json()["id"]

    acc = client.post(f"/api/v1/requests/{rid}/accept", headers=helper)
    assert acc.status_code == 200 and acc.json()["status"] == "accepted"

    bad = client.post(f"/api/v1/requests/{rid}/status", headers=helper, json={"status": "arrived"})
    assert bad.status_code == 422  # must go on_the_way first

    ok = client.post(
        f"/api/v1/requests/{rid}/status", headers=helper, json={"status": "on_the_way"}
    )
    assert ok.status_code == 200

    loc = client.post(
        f"/api/v1/requests/{rid}/location",
        headers=helper,
        json={"latitude": 17.45, "longitude": 78.45},
    )
    assert loc.status_code == 202


def test_unanswered_request_escalates_to_other_helpers(client, seed_categories, monkeypatch):
    # Nearest helper (at the pickup) is targeted first; a second eligible helper
    # ~22 km away must not see it until the targeting window elapses.
    near = _make_helper(client, "near@example.com")  # at seed center → nearest
    far_hdr = _register(client, "far@example.com", "FarHelper")
    far_lat, far_lng = settings.seed_center_lat + 0.2, settings.seed_center_lng
    client.post(
        "/api/v1/helpers",
        headers=far_hdr,
        json={
            "name": "Far Service",
            "helper_type": "mechanic",
            "phone": "+919800000011",
            "latitude": far_lat,
            "longitude": far_lng,
        },
    )

    seeker = _register(client, "escseek@example.com")
    cat = _category(client)
    rid = client.post(
        "/api/v1/requests",
        headers=seeker,
        json={
            "category_id": cat["id"],
            "pickup_lat": settings.seed_center_lat,
            "pickup_lng": settings.seed_center_lng,
        },
    ).json()["id"]

    def far_open():
        return [
            o["id"]
            for o in client.get(
                "/api/v1/requests/open", headers=far_hdr, params={"lat": far_lat, "lng": far_lng}
            ).json()
        ]

    def near_open():
        return [
            o["id"]
            for o in client.get(
                "/api/v1/requests/open",
                headers=near,
                params={"lat": settings.seed_center_lat, "lng": settings.seed_center_lng},
            ).json()
        ]

    # Within the window: only the targeted (nearest) helper sees it.
    assert rid in near_open()
    assert rid not in far_open()

    # Past the window: it escalates to the other eligible helper.
    monkeypatch.setattr(request_service, "_TARGET_TIMEOUT_SECONDS", -1)
    assert rid in far_open()
    assert rid in near_open()
