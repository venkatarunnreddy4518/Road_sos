"""First-accept-wins: two helpers race for one broadcast request; only one wins (FR-019)."""
from app.core.config import settings


def _register(client, email, name="User"):
    r = client.post(
        "/api/v1/auth/email/register",
        json={"display_name": name, "email": email, "password": "secret1"},
    )
    return {"Authorization": f"Bearer {r.json()['access_token']}"}


def _make_helper(client, email):
    hdr = _register(client, email, "Helper")
    r = client.post(
        "/api/v1/helpers",
        headers=hdr,
        json={
            "name": email,
            "helper_type": "mechanic",
            "latitude": settings.seed_center_lat,
            "longitude": settings.seed_center_lng,
        },
    )
    assert r.status_code == 201, r.text
    return hdr


def test_only_one_helper_can_accept(client, seed_categories):
    h1 = _make_helper(client, "race1@example.com")
    h2 = _make_helper(client, "race2@example.com")
    seeker = _register(client, "raceseeker@example.com")
    cat = next(c for c in client.get("/api/v1/categories").json() if c["key"] == "breakdown")

    rid = client.post(
        "/api/v1/requests",
        headers=seeker,
        json={
            "category_id": cat["id"],
            "pickup_lat": settings.seed_center_lat,
            "pickup_lng": settings.seed_center_lng,
        },
    ).json()["id"]

    r1 = client.post(f"/api/v1/requests/{rid}/accept", headers=h1)
    r2 = client.post(f"/api/v1/requests/{rid}/accept", headers=h2)

    statuses = sorted([r1.status_code, r2.status_code])
    assert statuses == [200, 409]  # exactly one winner

    # The request is assigned to exactly one helper and is in 'accepted'.
    final = client.get(f"/api/v1/requests/{rid}", headers=seeker).json()
    assert final["status"] == "accepted"
    assert final["helper_id"] is not None
