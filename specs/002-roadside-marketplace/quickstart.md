# Quickstart — Roadside Help Marketplace (Prototype)

This runs the full prototype locally: FastAPI + PostgreSQL backend and the Flutter app
(mobile or web). OTP and Google use labelled dev/mock fallbacks unless real credentials are set.

## Prerequisites

- Python 3.11+, PostgreSQL 14+ running locally
- Flutter 3.x SDK (with web enabled: `flutter config --enable-web`)

## 1. Backend

```bash
cd backend
python -m venv .venv && . .venv/Scripts/activate   # Windows PowerShell: .venv\Scripts\Activate.ps1
pip install -r requirements.txt
cp .env.example .env        # set DATABASE_URL + JWT_SECRET (GOOGLE_CLIENT_ID/SMS_* optional)

# create the database (once)
createdb roadside_help        # or via psql: CREATE DATABASE roadside_help;

alembic upgrade head          # apply schema migrations
python -m app.seed.run        # seed service categories + demo helpers
uvicorn app.main:app --reload --port 8000
```

- API docs (OpenAPI/Swagger): http://localhost:8000/docs
- Dev mode: with no `SMS_*` set, `POST /auth/phone/request-otp` returns `dev_code` and accepts
  `000000`; with no `GOOGLE_CLIENT_ID`, `POST /auth/google` accepts `{dev_email, dev_name}`.

## 2. Flutter app

```bash
flutter pub get
# point the app at the backend (defaults to http://localhost:8000 if omitted)
flutter run --dart-define=API_BASE_URL=http://localhost:8000          # device/emulator
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000 # web
```

> Android emulator reaches the host backend at `http://10.0.2.2:8000`.

## 3. Demo walkthrough (maps to user stories)

1. **Welcome → sign in** (Story 1, FR-001): choose Email, Phone (dev code `000000`), Google
   (dev button), or **Continue as guest**.
2. **Home**: search bar + category grid (puncture, fuel, mechanic, towing, battery). Pick a
   category → nearest helpers sorted by distance, rating, open/closed, call button (FR-008/010/011).
3. **Request a helper** (Story 2): tap a helper → *Request help*. (As guest you're prompted to
   sign in first, FR-005.) Watch status timeline requested → accepted → on the way → arrived →
   completed, with the helper's live marker moving on the map (FR-013–FR-017).
4. **Provider mode** (Story 3): a helper-role account opens the request inbox, accepts a request,
   advances status, and shares location. Run two clients (e.g. web + emulator) to see both sides.
5. **Rate** (Story 4): after completion, leave 1–5 stars + comment; the helper's average updates
   (FR-022/FR-023). Open **History** and **Profile**; edit profile fields.
6. **Language** (Story 5): switch language in Settings/Profile; UI updates and persists.
7. **Offline** (FR-026/027): kill the backend / go offline → cached helper list + GPS + call/SMS
   still work; online-only actions show a "needs connection" state.

## 4. Tests

```bash
# backend
cd backend && pytest

# flutter
flutter test
```

Contract tests assert responses match `specs/002-roadside-marketplace/contracts/rest-api.md`.
Key unit tests: Haversine distance + nearest sorting + >15 km flag; request state-transition
validation; first-accept-wins; review aggregate recompute; auth token issue/verify.
