# Implementation Plan: Roadside Help — Two-Sided Marketplace

**Branch**: `002-roadside-marketplace` | **Date**: 2026-06-10 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/002-roadside-marketplace/spec.md`

## Summary

Evolve the existing offline-first roadside help app (feature 001) into a working two-sided
marketplace prototype. Add accounts (phone OTP, email+password, Google, guest) and two roles
(seeker, helper/provider); a service-request lifecycle with live helper tracking; search and a
service-category home; profiles, request history, and ratings; all on working OpenStreetMap maps
and multi-language UI. A new custom **FastAPI + PostgreSQL** backend owns accounts, helper data,
the request lifecycle, live location, search, and reviews via an HTTPS REST API. The Flutter app
talks to that API and keeps a local **SQLite cache** so the core find-helper flow still works
offline. The existing Clean Architecture in `lib/` is extended (not replaced).

## Technical Context

**Language/Version**: Frontend Flutter (Dart) 3.x; Backend Python 3.11+ (FastAPI).

**Primary Dependencies**:
- Frontend: `flutter_map` + `latlong2` (OSM maps), `geolocator` (GPS), `url_launcher` (call/SMS/
  directions), `sqflite` (offline cache), `http` (API client), `flutter_secure_storage` (token
  storage), `flutter_localizations`/`intl` (i18n), `provider` (state, already via app_state).
- Backend: `fastapi`, `uvicorn`, `sqlalchemy` 2.x, `alembic` (migrations), `psycopg[binary]`
  (PostgreSQL driver), `pydantic`/`pydantic-settings` (schemas/config), `passlib[bcrypt]` (password
  hashing), `python-jose` (JWT), `python-multipart`, `httpx` (Google token verification).

**Storage**:
- Remote: PostgreSQL (normalized schema; spatial queries via lat/long + Haversine, no PostGIS
  dependency for the prototype).
- Local: SQLite (`sqflite`) cache of helpers + language preference for offline discovery; auth
  token in secure storage.

**Testing**: Backend `pytest` (+ `httpx` TestClient) for unit/contract/integration; Flutter
`flutter_test` for unit (distance, parsing, request-state logic) and widget tests; contract tests
assert API responses match `contracts/`.

**Target Platform**: Android 10+, iOS 15+, and Flutter web (Chrome). Backend runs as a local
HTTP service (containerizable) for the prototype.

**Project Type**: Mobile + API (web application split: Flutter client + FastAPI backend).

**Performance Goals**: Nearest-helper results < 10 s; live status/position propagation to seeker
≤ 10 s; language switch ≤ 2 s; 60 fps UI.

**Constraints**: Offline-capable core discovery (cached list + GPS + call/SMS); online-only
features (request submit/track) must degrade with a clear message; HTTPS for all traffic; OTP and
Google have labelled mock/dev fallbacks when external credentials are absent.

**Scale/Scope**: Prototype scale (hundreds of seeded helpers, low concurrency). ~12 DB tables,
~25 REST endpoints, ~15 Flutter screens.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. Test-First (NON-NEGOTIABLE)**: ✅ `tasks.md` will order failing tests before implementation
  for auth, distance/sorting, request-state transitions, and contract tests for each endpoint.
- **II. Security by Default**: ✅ Passwords hashed with bcrypt; JWT bearer tokens over HTTPS;
  server-side authorization on every protected route; secrets via env vars (`.env`, gitignored);
  Pydantic validates all input; no secrets/PII in logs.
- **III. Simplicity & YAGNI**: ✅ Haversine + indexed lat/long instead of PostGIS; polling for
  live updates instead of websockets; mock OTP/OAuth fallbacks instead of standing up paid
  providers. Each is the simplest path meeting the requirement.
- **IV. Clear Contracts & Separation of Concerns**: ✅ Explicit OpenAPI contracts in `contracts/`;
  backend layered (api → services → models); Flutter keeps data/domain/presentation separation.
- **V. Observability & Maintainability**: ✅ Structured backend logging (request id, status
  transitions, auth failures w/o credentials); Flutter logger for GPS/permission/sync errors.

**Verdict**: PASS (no violations; see Complexity Tracking — none required).

## Project Structure

### Documentation (this feature)

```text
specs/002-roadside-marketplace/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (OpenAPI + endpoint contracts)
└── tasks.md             # Phase 2 output (/speckit-tasks)
```

### Source Code (repository root)

```text
backend/                         # NEW — FastAPI + PostgreSQL service
├── app/
│   ├── main.py                  # FastAPI app + router wiring
│   ├── core/                    # config, security (jwt/hashing), logging, deps
│   ├── db/                      # engine, session, base
│   ├── models/                  # SQLAlchemy ORM models (User, AuthIdentity, HelperProfile, ...)
│   ├── schemas/                 # Pydantic request/response schemas
│   ├── api/v1/                  # routers: auth, helpers, requests, locations, reviews, profile, search
│   ├── services/                # business logic (auth, discovery, request lifecycle, reviews)
│   └── seed/                    # seed categories + demo helpers
├── alembic/                     # migrations
├── tests/                       # contract / integration / unit (pytest)
├── pyproject.toml / requirements.txt
├── .env.example
└── README.md

lib/                             # EXISTING Flutter app — extended
├── core/
│   ├── constants/               # theme, api endpoints
│   ├── i18n/                    # localization (extended for new screens)
│   ├── network/                 # NEW api client, auth interceptor, token store
│   └── utils/                   # distance calc, logger
├── data/
│   ├── models/                  # User, AuthSession, ServiceRequest, Review, Category, Helper...
│   ├── providers/               # api clients (auth, helpers, requests, reviews)
│   └── repositories/            # auth, helper (remote+SQLite cache), request, review repos
├── domain/
│   ├── entities/                # business objects
│   └── usecases/                # SignIn, FindNearestHelpers, SubmitRequest, UpdateStatus, RateHelper...
└── presentation/
    ├── screens/                 # welcome, login/signup(otp/email/google), home, search, helper list,
    │                            #   helper detail, request tracking, provider inbox, profile, history, settings
    ├── widgets/                 # helper card, category grid, search bar, status timeline, rating stars
    └── state/                   # auth state, request state, app state (provider)

test/                            # Flutter tests (unit + widget)
```

**Structure Decision**: Mobile + API split. A new `backend/` FastAPI service owns the PostgreSQL
data and all online operations; the existing Flutter `lib/` Clean Architecture is extended with a
`core/network` layer and new data/domain/presentation pieces. The offline-first helper cache
(SQLite) is retained and fed by syncing from the backend, preserving feature 001's offline
behavior while adding the online marketplace.

## Complexity Tracking

No constitution violations; no justifications required. Notable simplifications recorded in
`research.md` (Haversine over PostGIS, polling over websockets, mock OTP/OAuth) are YAGNI-aligned
and reduce rather than add complexity.
