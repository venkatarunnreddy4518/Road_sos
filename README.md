# Roadside SOS — Two-Sided Assistance Marketplace

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.100%2B-009688?logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-14%2B-4169E1?logo=postgresql&logoColor=white)](https://www.postgresql.org)
[![SQLite](https://img.shields.io/badge/SQLite-3-003B57?logo=sqlite&logoColor=white)](https://www.sqlite.org)
[![Code Style: Ruff](https://img.shields.io/badge/code%20style-ruff-000000.svg)](https://github.com/astral-sh/ruff)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

An Uber-style, two-sided marketplace prototype for roadside emergencies. Stranded users (seekers) can locate nearby help (puncture shops, petrol pumps, mechanics, towing, battery jump-starts), submit real-time assistance requests, and track helper location live on interactive maps. Active helpers (providers) can log in to a dedicated **Provider Mode** to receive local requests, accept jobs (first-accept-wins), and update their status/location.

---

## 🌐 Live Demo

The prototype is deployed end-to-end and publicly reachable:

| Tier | Service | URL |
| --- | --- | --- |
| Frontend | Flutter Web on **Vercel** | <https://help-ashy.vercel.app> |
| Backend | FastAPI (Docker) on **Render** | <https://roadside-help-api.onrender.com> · [`/docs`](https://roadside-help-api.onrender.com/docs) |
| Database | **Neon** serverless PostgreSQL (Singapore) | — |

> The Render backend runs on a free tier and sleeps after ~15 min of inactivity, so the first request after idle may take ~30–50 s to cold-start. Auth works out of the box: Google/phone fall back to sandboxed dev mocks when third-party keys are absent.

---

## 🏗️ System Architecture

The application is built on a decoupled, mobile-and-API split architecture:
- **Frontend Client**: A multi-platform Flutter app running on iOS, Android, and Web, using `provider` state management, `flutter_map` for OpenStreetMap integration, and an offline-first SQLite cache.
- **Backend API**: A high-performance, asynchronous FastAPI service powered by SQLAlchemy 2.0 and PostgreSQL.
- **Offline Sync**: In offline-only conditions, the client automatically degrades to use cached nearest-helper lists and executes direct local call/SMS fallbacks based on the device's GPS coordinates.

### High-Level Architectural Flow

```mermaid
graph TD
    subgraph Client ["Flutter Client App (Dart 3 / Flutter 3)"]
        UI["Presentation Layer (Screens/Widgets)"]
        State["State Management (Provider)"]
        Domain["Domain Usecases & Entities"]
        Repo["Repositories (Data Sync & Auth)"]
        LocalCache["SQLite Cache (sqflite)"]
        SecureStorage["Secure Token Store"]
    end

    subgraph Backend ["FastAPI Backend (Python 3.11+)"]
        API["REST API Router (FastAPI)"]
        Service["Business Logic Service Layer"]
        ORM["SQLAlchemy 2.0 ORM Engine"]
    end

    subgraph Database ["Data Store"]
        Postgres[(PostgreSQL 14+)]
    end

    UI --> State
    State --> Domain
    Domain --> Repo
    Repo --> LocalCache
    Repo --> SecureStorage
    Repo -- "HTTPS REST API (JWT)" --> API
    API --> Service
    Service --> ORM
    ORM --> Postgres
```

---

## 🔄 Marketplace Lifecycle (Sequence Flow)

The following sequence diagram outlines the end-to-end request submission, assignment (first-accept-wins), real-time tracking, and reviews loop:

```mermaid
sequenceDiagram
    autonumber
    actor Seeker as Stranded User
    participant App as Seeker App
    participant BE as FastAPI Backend
    participant DB as PostgreSQL
    actor Helper as Roadside Mechanic
    participant ProvApp as Provider App

    Seeker->>App: Tap Emergency Category (e.g. Puncture)
    App->>BE: GET /api/v1/helpers/nearby?lat=...&lng=...
    BE->>DB: Query helpers with Haversine distance
    DB-->>BE: Return active helper list
    BE-->>App: Return nearby helpers (or cache if offline)
    App->>Seeker: Display helpers on OSM Map

    Seeker->>App: Tap "Request Help Now" (SOS)
    App->>BE: POST /api/v1/requests (lat, lng, note)
    BE->>DB: Insert request (status: REQUESTED)
    BE-->>App: Return Request ID
    App->>Seeker: Transition to Tracking Screen

    Note over ProvApp, Helper: Provider Mode Active
    BE->>ProvApp: Poll / Long-Poll / Push notification
    ProvApp->>Helper: Alert: New Request Nearby!
    Helper->>ProvApp: Tap "Accept Request"
    ProvApp->>BE: POST /api/v1/requests/{id}/accept
    BE->>DB: Check & update status (ACCEPTED - First Accept Wins)
    BE-->>ProvApp: Accept successful (Assign Helper)
    
    loop Real-time Tracking
        ProvApp->>BE: POST /api/v1/locations/update (lat, lng)
        BE->>DB: Save helper position
        App->>BE: GET /api/v1/requests/{id}/status
        BE-->>App: Return current status + helper coordinates
        App->>Seeker: Move helper marker on map & update timeline
    end

    Helper->>ProvApp: Tap "Mark Arrived" & "Complete Service"
    ProvApp->>BE: POST /api/v1/requests/{id}/status (ARRIVED -> COMPLETED)
    BE->>DB: Finalize status & stamp fare_amount from category base_fare
    App->>Seeker: Show rating & review dialog
    Seeker->>App: Rate 1-5 Stars + Comment
    App->>BE: POST /api/v1/reviews
    BE->>DB: Update helper rolling average rating
```

---

## ✨ Key Features

- **Decoupled Auth Systems**: Native support for Phone OTP sign-in, Google sign-in, Email+Password, and immediate Guest access. Features pre-built sandboxed development mocks when third-party OAuth/SMS API keys are missing.
- **Premium Premium-Notch Navbar**: Custom-built bottom navigation system including a center-docked premium SOS FAB nestled inside a geometric notch cutout with dynamic theme support (matching iOS/Android navigation guidelines).
- **Haversine Distance Mapping**: Real-time server-side geospatial query processing using indexing and mathematical coordinate distance (Haversine) without heavy GIS dependencies.
- **Live Tracking Panel**: Draggable, glassmorphic bottom sheets displaying status timelines, pickup pointers, and active tracking markers on OpenStreetMap.
- **Localization Integration**: Dynamic locale selector (supporting **English, हिन्दी, తెలుగు, தமிழ்**) that completes a full-app language update under 2 seconds and persists preferences across launches.
- **Provider Console & Onboarding**: A self-service **Provider registration** flow (service type, contact, GPS-stamped location) that turns any user into a helper, plus a live inbox of open local requests with quick directions and status triggers.
- **Transactional Fares**: Each service category carries a base fee; when a helper completes a job the request is stamped with a final `fare_amount`, surfaced on the seeker's **My SOS Requests** history (seeker/helper tabs, status chips, and per-job pricing).
- **Redesigned Profile Suite**: Native-feeling Profile, Payments, Safety Guidelines, Emergency Contacts, Refer & Earn, Settings, and Help & Support screens with one-tap helpline calling.

---

## 🗄️ Database Model (PostgreSQL)

The backend schema features six core normalized tables representing the marketplace entities (plus supporting tables for OTP codes, refresh tokens, and helper location history). Schema changes are managed with **Alembic** — migration `0002` introduces the `base_fare` / `fare_amount` pricing columns shown below:

```
                  ┌──────────────────────┐
                  │        users         │◄────────────────┐
                  ├──────────────────────┤                 │
                  │ id (PK)              │                 │
                  │ email, phone, role   │                 │
                  └──────────┬───────────┘                 │
                             │ 1                           │ 1
                             ▼ *                           │
                  ┌──────────────────────┐        ┌────────┴─────────────┐
                  │   auth_identities    │        │   helper_profiles    │
                  ├──────────────────────┤        ├──────────────────────┤
                  │ provider, uid        │        │ id (PK)              │
                  │ user_id (FK)         │        │ user_id (FK)         │
                  └──────────────────────┘        │ rating_avg, lat, lng │
                                                  └────────▲─────────────┘
                                                           │ 1
                                                           ▼ *
┌──────────────────────┐ *                        ┌────────┴─────────────┐
│  service_categories  │◄─────────────────────────┤   service_requests   │
├──────────────────────┤                          ├──────────────────────┤
│ id (PK)              │ 1                        │ id (PK), status      │
│ name, helper_types   │                          │ seeker_id (FK:user)  │
│ base_fare            │                          │ helper_id (FK:profile│
└──────────────────────┘                          │ fare_amount          │
                                                  └────────▲─────────────┘
                                                           │ 1
                                                           ▼ *
                                                  ┌────────┴─────────────┐
                                                  │       reviews        │
                                                  ├──────────────────────┤
                                                  │ request_id (FK)      │
                                                  │ rating (1-5), note   │
                                                  └──────────────────────┘
```

---

## 🚀 Local Quickstart & Build Configuration

All commands are prepared for **Windows PowerShell** (the primary development environment).

### Prerequisites
- Flutter SDK (v3.x / Dart 3.x) with Web enabled (`flutter config --enable-web`)
- Python (v3.11+)
- PostgreSQL (v14+ running locally)

---

### Step 1: Initialize PostgreSQL Database
Create the database and set up a user/role with your local PostgreSQL password:
```powershell
# Set PostgreSQL password for createdb access
$env:PGPASSWORD="YOUR_POSTGRES_PASSWORD"

# Create the primary application database
& "$env:ProgramFiles\PostgreSQL\18\bin\createdb.exe" -U postgres roadside_help
```

---

### Step 2: Spin up the FastAPI Backend API
1. Navigate to the backend folder and create a Python virtual environment:
   ```powershell
   cd backend
   python -m venv .venv
   .\.venv\Scripts\Activate.ps1
   ```
2. Install Python packages and create your environment file:
   ```powershell
   pip install -r requirements.txt
   Copy-Item .env.example .env
   ```
3. Update `backend/.env` with your Postgres password and a random secret:
   ```env
   DATABASE_URL=postgresql+psycopg://postgres:YOUR_POSTGRES_PASSWORD@localhost:5432/roadside_help
   JWT_SECRET=super-secure-key-string-change-this
   ```
4. Run Alembic schema migrations and seed database with categories and demo mechanics:
   ```powershell
   alembic upgrade head
   python -m app.seed.run
   ```
5. Launch the live Uvicorn API server:
   ```powershell
   uvicorn app.main:app --reload --port 8000
   ```
   - OpenAPI Docs: <http://localhost:8000/docs>
   - Server Health Check: <http://localhost:8000/health>

---

### Step 3: Run or Build the Flutter App (Web/Local)
Start a new terminal session at the project root folder.

#### Running locally in Chrome:
```powershell
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
```

#### Compiling static assets for web deployment (e.g. Vercel hosting):
Because Vercel serves the app statically via precompiled assets defined in `vercel.json`'s `outputDirectory: "build/web"`, any new local code edits must be built and committed back to the repository:
```powershell
# Compile production-ready web assets
flutter build web

# Add new compiled builds (bypassing generic gitignore rules)
git add -f build/web/
git commit -m "build: compile web assets for production"
git push github
```

---

## 🧪 Running the Quality Suite

Strict coding style, security scans, and code coverage checks are automatically validated in the CI pipeline:

### FastAPI Backend Checks
```powershell
cd backend
.\.venv\Scripts\Activate.ps1

# Formatter and Code Linter
ruff check .
ruff format --check .

# Static Type Checking
mypy app/

# Security Scan (Secret leaks and CVEs)
bandit -r app/ -ll

# Integration & Contract Tests with Coverage Threshold (>=80%)
pytest --cov=app --cov-fail-under=80
```

### Flutter Frontend Checks
```powershell
# Analyze Dart codebase for compiler/static warnings
flutter analyze

# Run Flutter widget and unit tests
flutter test
```

