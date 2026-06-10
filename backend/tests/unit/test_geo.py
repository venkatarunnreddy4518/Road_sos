from app.services.geo import FAR_THRESHOLD_KM, haversine_km, is_far


def test_haversine_known_distance():
    # Hyderabad Charminar -> Hitech City ~ 11-13 km
    d = haversine_km(17.3616, 78.4747, 17.4435, 78.3772)
    assert 8 < d < 16


def test_zero_distance():
    assert haversine_km(17.4, 78.4, 17.4, 78.4) == 0


def test_far_flag():
    assert is_far(FAR_THRESHOLD_KM + 0.1) is True
    assert is_far(FAR_THRESHOLD_KM - 0.1) is False


def test_nearest_sort_orders_by_distance():
    origin = (17.42, 78.47)
    pts = [(17.50, 78.55), (17.43, 78.48), (17.60, 78.70)]
    dists = sorted(haversine_km(*origin, lat, lng) for lat, lng in pts)
    assert dists == sorted(dists)
    assert dists[0] < dists[-1]
