def test_email_register_and_login(client):
    r = client.post(
        "/api/v1/auth/email/register",
        json={"display_name": "Asha", "email": "asha@example.com", "password": "secret1"},
    )
    assert r.status_code == 201, r.text
    body = r.json()
    assert body["user"]["email"] == "asha@example.com"
    assert body["access_token"] and body["refresh_token"]

    # duplicate -> 409
    r2 = client.post(
        "/api/v1/auth/email/register",
        json={"display_name": "Asha2", "email": "asha@example.com", "password": "secret1"},
    )
    assert r2.status_code == 409

    r3 = client.post(
        "/api/v1/auth/email/login", json={"email": "asha@example.com", "password": "secret1"}
    )
    assert r3.status_code == 200
    r4 = client.post(
        "/api/v1/auth/email/login", json={"email": "asha@example.com", "password": "wrong"}
    )
    assert r4.status_code == 401


def test_phone_otp_dev_flow(client):
    r = client.post("/api/v1/auth/phone/request-otp", json={"phone": "+919800000001"})
    assert r.status_code == 200
    assert r.json()["dev_code"] == "000000"  # SMS mock mode

    r2 = client.post(
        "/api/v1/auth/phone/verify-otp",
        json={"phone": "+919800000001", "code": "000000", "display_name": "Ravi"},
    )
    assert r2.status_code == 200
    assert r2.json()["user"]["phone"] == "+919800000001"


def test_google_dev_flow_and_me(client):
    r = client.post(
        "/api/v1/auth/google", json={"dev_email": "g@example.com", "dev_name": "G User"}
    )
    assert r.status_code == 200, r.text
    token = r.json()["access_token"]

    me = client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer {token}"})
    assert me.status_code == 200
    assert me.json()["email"] == "g@example.com"

    assert client.get("/api/v1/auth/me").status_code == 401


def test_email_case_insensitive(client):
    # Register with one case
    r = client.post(
        "/api/v1/auth/email/register",
        json={"display_name": "Test User", "email": "TestUser@Example.COM", "password": "secret1"},
    )
    assert r.status_code == 201, r.text
    body = r.json()
    assert body["user"]["email"] == "testuser@example.com"  # stored in lowercase

    # Duplicate email with different case should fail
    r2 = client.post(
        "/api/v1/auth/email/register",
        json={
            "display_name": "Test User 2",
            "email": "testuser@example.com",
            "password": "secret1",
        },
    )
    assert r2.status_code == 409

    # Login with different case should work
    r3 = client.post(
        "/api/v1/auth/email/login", json={"email": "TESTUSER@EXAMPLE.COM", "password": "secret1"}
    )
    assert r3.status_code == 200


def test_phone_normalization(client):
    # Request OTP with different phone formats
    r1 = client.post("/api/v1/auth/phone/request-otp", json={"phone": "9800000001"})
    assert r1.status_code == 200

    # Verify with the same phone but in normalized form
    r2 = client.post(
        "/api/v1/auth/phone/verify-otp",
        json={"phone": "+91 9800000001", "code": "000000", "display_name": "User"},
    )
    assert r2.status_code == 200
    assert r2.json()["user"]["phone"] == "+919800000001"

    # Request OTP with different format should match the same user
    r3 = client.post("/api/v1/auth/phone/request-otp", json={"phone": "98-00000001"})
    assert r3.status_code == 200

    r4 = client.post(
        "/api/v1/auth/phone/verify-otp",
        json={"phone": "+919800000001", "code": "000000"},
    )
    # Should work because the phone is already registered
    assert r4.status_code == 200
