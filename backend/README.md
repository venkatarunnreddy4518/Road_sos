# Roadside Help — Backend (FastAPI + PostgreSQL)

Custom REST backend for the two-sided roadside-assistance marketplace. Owns accounts, helper
data, the service-request lifecycle, live location, search, profiles, and reviews.

Spec: [`specs/002-roadside-marketplace`](../specs/002-roadside-marketplace) ·
Contract: [`contracts/rest-api.md`](../specs/002-roadside-marketplace/contracts/rest-api.md)

## Stack

- **FastAPI** + **Uvicorn** (auto OpenAPI docs at `/docs`)
- **SQLAlchemy 2.x** ORM + **Alembic** migrations
- **PostgreSQL** (`psycopg` v3 driver)
- **JWT** bearer auth (`python-jose`) + **bcrypt** password hashing (`passlib`)
- Phone OTP and Google sign-in have **dev/mock fallbacks** when no external creds are set

## Run

```bash
cd backend
python -m venv .venv
.venv\Scripts\Activate.ps1        # Windows PowerShell  (Linux/mac: . .venv/bin/activate)
pip install -r requirements.txt
copy .env.example .env            # set DATABASE_URL + JWT_SECRET

# create the database once
psql -U postgres -c "CREATE DATABASE roadside_help;"

alembic upgrade head              # apply schema
python -m app.seed.run            # seed categories + demo helpers
uvicorn app.main:app --reload --port 8000
```

- Health: `GET http://localhost:8000/health` (reports mock-mode flags)
- Swagger UI: `http://localhost:8000/docs`

### Dev/mock auth (no external providers)

- **Phone OTP**: `POST /api/v1/auth/phone/request-otp` returns `dev_code`; the fixed code
  `000000` is also accepted by `verify-otp`.
- **Google**: `POST /api/v1/auth/google` accepts `{ "dev_email": ..., "dev_name": ... }`.

## Tests

Requires a reachable PostgreSQL. Point tests at a throwaway DB:

```bash
set TEST_DATABASE_URL=postgresql+psycopg://postgres:postgres@localhost:5432/roadside_help_test
pytest
```

`tests/unit` (geo math), `tests/contract` (auth + discovery), `tests/integration`
(full request lifecycle, first-accept-wins, live location, reviews).

## Layout

```
app/
├── main.py              # FastAPI app + CORS + error handlers + router
├── core/                # config, security (jwt/bcrypt), logging, deps, errors
├── db/                  # engine/session, declarative base
├── models/              # SQLAlchemy ORM (users, auth, helpers, requests, reviews)
├── schemas/             # Pydantic request/response models
├── services/            # business logic (auth, helpers, requests, reviews, geo)
├── api/v1/              # routers: auth, profile, categories, helpers, requests, reviews
└── seed/                # demo data
alembic/                 # migrations
```
