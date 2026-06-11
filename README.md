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

## How to run

You run **two things**: the backend API (Python + PostgreSQL) and the Flutter app (web).
Commands below are for **Windows PowerShell** (the project's primary environment).

### Prerequisites

| Tool | Version | Check |
|------|---------|-------|
| Flutter SDK | 3.x (Dart 3) | `flutter --version` |
| Python | 3.11+ | `python --version` |
| PostgreSQL | 14+ (running) | service `postgresql-x64-XX` Running |

Enable Flutter web once: `flutter config --enable-web`.

### Step 1 — Database (one time)

Create the database, using **your** PostgreSQL `postgres` password (set during install):

```powershell
# replace YOURPASS; this creates the app database
$env:PGPASSWORD="YOURPASS"
& "$env:ProgramFiles\PostgreSQL\18\bin\createdb.exe" -U postgres roadside_help
```

### Step 2 — Backend API

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt

Copy-Item .env.example .env       # then edit .env (see below)
alembic upgrade head              # create tables
python -m app.seed.run            # seed categories + ~15 demo helpers
uvicorn app.main:app --reload --port 8000
```

Edit **`backend/.env`** so `DATABASE_URL` has your real password, and set a `JWT_SECRET`:

```
DATABASE_URL=postgresql+psycopg://postgres:YOURPASS@localhost:5432/roadside_help
JWT_SECRET=any-long-random-string
```

Verify the API is up:
- Health: <http://localhost:8000/health>
- Swagger docs: <http://localhost:8000/docs>

> **Dev/mock auth** (no external accounts needed): phone OTP returns a `dev_code` and accepts
> `000000`; Google sign-in uses a demo identity. To wire **real** Twilio SMS and Google sign-in,
> follow [docs/PROVIDERS.md](docs/PROVIDERS.md) (put secrets in `backend/.env`; pass Google client
> ids to the app via `--dart-define`).

### Step 3 — Flutter app (web)

In a **second terminal** at the project root:

```powershell
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
```

The app opens in Chrome. Sign in (or **Continue as guest**), pick a category, and you'll see the
seeded helpers. To exercise the two-sided flow, run a second client and register it as a helper
(Profile → Provider mode).

### Run on a phone / emulator

Native `android/` and `ios/` are generated and pre-configured with the required permissions
(internet, location) and intent/URL-scheme entries for call/SMS/directions.

```powershell
flutter devices                                  # list connected devices/emulators
# Android emulator (10.0.2.2 = your host machine):
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8000
# Physical Android phone on the same Wi-Fi (use your PC's LAN IP):
flutter run -d <deviceId> --dart-define=API_BASE_URL=http://192.168.x.x:8000
# build an installable debug APK:
flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

> iOS requires macOS + Xcode to build/run. Cleartext HTTP to the local backend is enabled for
> dev on both platforms; use HTTPS in production.

### Troubleshooting

| Symptom | Fix |
|---------|-----|
| `password authentication failed for user "postgres"` | Wrong password in `DATABASE_URL` — use your real Postgres password. |
| App shows "Offline — showing cached helpers" | Backend not reachable; confirm `uvicorn` is running on :8000 and `API_BASE_URL` matches. |
| Browser blocks the API (CORS) | `CORS_ORIGINS=*` is set by default in `.env.example`; keep it for local dev. |
| Empty helper list | Run `python -m app.seed.run`. |

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
