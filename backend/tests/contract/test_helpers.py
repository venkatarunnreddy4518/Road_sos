from app.core.config import settings


def test_categories_listed(client, seed_categories):
    r = client.get("/api/v1/categories")
    assert r.status_code == 200
    keys = {c["key"] for c in r.json()}
    assert {"puncture", "fuel", "breakdown", "towing", "battery"} <= keys


def test_nearby_sorted_with_distance_and_far_flag(client, seed_categories):
    r = client.get(
        "/api/v1/helpers/nearby",
        params={"lat": settings.seed_center_lat, "lng": settings.seed_center_lng, "limit": 5},
    )
    assert r.status_code == 200
    rows = r.json()
    assert len(rows) >= 1
    dists = [row["distance_km"] for row in rows]
    assert dists == sorted(dists)  # nearest first
    for row in rows:
        assert "is_far" in row and "open_now" in row
        assert row["is_far"] == (row["distance_km"] > 15)


def test_search_by_name(client, seed_categories):
    r = client.get("/api/v1/helpers/search", params={"q": "puncture"})
    assert r.status_code == 200
    assert isinstance(r.json(), list)
