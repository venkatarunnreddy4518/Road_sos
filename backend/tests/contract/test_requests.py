"""Contract tests for /requests/* endpoints (US2)."""


def _register(client, email, name="User"):
    r = client.post(
        "/api/v1/auth/email/register",
        json={"display_name": name, "email": email, "password": "secret1"},
    )
    return {"Authorization": f"Bearer {r.json()['access_token']}"}


def _category(client, key="breakdown"):
    return next(c for c in client.get("/api/v1/categories").json() if c["key"] == key)


def test_create_requires_auth(client, seed_categories):
    cat = _category(client)
    r = client.post(
        "/api/v1/requests",
        json={"category_id": cat["id"], "pickup_lat": 17.4, "pickup_lng": 78.4},
    )
    assert r.status_code == 401


def test_create_and_get_as_seeker(client, seed_categories):
    seeker = _register(client, "seek1@example.com")
    cat = _category(client)
    r = client.post(
        "/api/v1/requests",
        headers=seeker,
        json={
            "category_id": cat["id"],
            "pickup_lat": 17.4,
            "pickup_lng": 78.4,
            "note": "flat tyre",
        },
    )
    assert r.status_code == 201
    body = r.json()
    assert body["status"] == "requested"
    assert body["helper_location"] is None

    got = client.get(f"/api/v1/requests/{body['id']}", headers=seeker)
    assert got.status_code == 200
    assert got.json()["note"] == "flat tyre"


def test_non_participant_cannot_read(client, seed_categories):
    seeker = _register(client, "owner@example.com")
    other = _register(client, "stranger@example.com")
    cat = _category(client)
    rid = client.post(
        "/api/v1/requests",
        headers=seeker,
        json={"category_id": cat["id"], "pickup_lat": 17.4, "pickup_lng": 78.4},
    ).json()["id"]
    assert client.get(f"/api/v1/requests/{rid}", headers=other).status_code == 403


def test_mine_lists_seeker_requests(client, seed_categories):
    seeker = _register(client, "mine@example.com")
    cat = _category(client)
    client.post(
        "/api/v1/requests",
        headers=seeker,
        json={"category_id": cat["id"], "pickup_lat": 17.4, "pickup_lng": 78.4},
    )
    r = client.get("/api/v1/requests/mine", headers=seeker, params={"role": "seeker"})
    assert r.status_code == 200
    assert len(r.json()) == 1


def test_seeker_can_cancel(client, seed_categories):
    seeker = _register(client, "cancel@example.com")
    cat = _category(client)
    rid = client.post(
        "/api/v1/requests",
        headers=seeker,
        json={"category_id": cat["id"], "pickup_lat": 17.4, "pickup_lng": 78.4},
    ).json()["id"]
    r = client.post(f"/api/v1/requests/{rid}/cancel", headers=seeker)
    assert r.status_code == 200
    assert r.json()["status"] == "cancelled"
    # cancelling again is rejected
    assert client.post(f"/api/v1/requests/{rid}/cancel", headers=seeker).status_code == 422
