# Roadside Help — Two-Sided Marketplace (Prototype)

An Uber/Rapido-style roadside-assistance app: a stranded user finds the nearest helper
(puncture shop, petrol pump, mechanic, towing, battery), requests them, and tracks them live —
while helpers receive and fulfil requests in a provider mode. Offline-first discovery, working
OpenStreetMap maps, multi-language UI, accounts, and ratings.

Built entirely with the **Spec Kit** workflow. See
[`specs/002-roadside-marketplace`](specs/002-roadside-marketplace) for the spec, plan, data model,
API contract, and task list.

## Architecture

```
Flutter app (lib/)  ──HTTPS REST──▶  FastAPI backend (backend/)  ──▶  PostgreSQL
   │  flutter_map / OSM, geolocator, url_launcher                        (normalized schema)
   └─ SQLite cache for offline-first helper discovery
```

- **Frontend**: Flutter (mobile + web), `provider` state, `flutter_map`/OSM, `flutter_secure_storage`.
- **Backend**: FastAPI + SQLAlchemy + Alembic + PostgreSQL, JWT auth, bcrypt hashing.
- **Auth**: phone OTP, email+password, Google, and guest (OTP/Google have dev mocks).

## Quick start

**1) Backend** — see [backend/README.md](backend/README.md):

```bash
cd backend && pip install -r requirements.txt
copy .env.example .env            # set DATABASE_URL + JWT_SECRET
alembic upgrade head && python -m app.seed.run
uvicorn app.main:app --reload --port 8000
```

**2) App**:

```bash
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000      # web
# device/emulator: use http://10.0.2.2:8000 on Android emulator
```

Full demo walkthrough: [specs/002-roadside-marketplace/quickstart.md](specs/002-roadside-marketplace/quickstart.md).

## Features (by user story)

| Story | What it delivers |
|-------|------------------|
| US1 | Sign in (4 methods) · home with search + category grid · nearest helpers · call/SMS/directions |
| US2 | Submit a request · live status timeline + moving helper marker · cancel · rate on completion |
| US3 | Provider mode: register, see open requests, accept (first-accept-wins), advance status, share location |
| US4 | Profile (name/phone/vehicle), request history (both roles), 1–5★ reviews with helper averages |
| US5 | Switch language anytime (English, हिन्दी, తెలుగు, தமிழ்), persisted across launches |

## Tests

```bash
flutter test                      # client unit/widget tests
cd backend && pytest              # backend unit/contract/integration (needs PostgreSQL)
```

## Project layout

```
backend/                          FastAPI + PostgreSQL service
lib/
├── core/        network (api client, token store), i18n, utils (geo, location)
├── data/        models, api clients
└── presentation/ screens (welcome, auth, home, search, helper detail, tracking,
                  provider, profile, history, settings), widgets, state
specs/002-roadside-marketplace/   spec · plan · research · data-model · contracts · tasks
```

> Payments are out of scope for this prototype. OTP/Google sign-in use clearly-labelled dev
> fallbacks unless real provider credentials are configured.
