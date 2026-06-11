---
description: "Task list for Roadside Help — Two-Sided Marketplace"
---

# Tasks: Roadside Help — Two-Sided Marketplace

**Input**: Design documents from `/specs/002-roadside-marketplace/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/rest-api.md, quickstart.md

**Tests**: Included — the project constitution mandates Test-First (NON-NEGOTIABLE). Each story
has focused contract/unit tests written before implementation.

**Organization**: Grouped by user story (US1–US5) for independent implementation and testing.
Paths follow plan.md: backend in `backend/`, Flutter client in `lib/` + `test/`.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no incomplete dependencies)
- **[Story]**: US1–US5 (user story phases only)

---

## Phase 1: Setup (Shared Infrastructure)

- [x] T001 Create `backend/` skeleton (`app/`, `app/core`, `app/db`, `app/models`, `app/schemas`, `app/api/v1`, `app/services`, `app/seed`, `alembic/`, `tests/`) per plan.md
- [x] T002 Add backend deps in `backend/requirements.txt` (fastapi, uvicorn, sqlalchemy, alembic, psycopg[binary], pydantic, pydantic-settings, passlib[bcrypt], python-jose, python-multipart, httpx) and `backend/pyproject.toml` (ruff/pytest config)
- [x] T003 [P] Create `backend/.env.example` (DATABASE_URL, JWT_SECRET, ACCESS_TTL, REFRESH_TTL, GOOGLE_CLIENT_ID?, SMS_*?) and add `backend/.env` to `.gitignore`
- [x] T004 [P] Configure `backend/app/core/config.py` (pydantic-settings) and `backend/app/core/logging.py` (structured logging, no secrets/PII)
- [x] T005 [P] Add Flutter deps to `pubspec.yaml` (flutter_secure_storage, provider) and verify existing (flutter_map, latlong2, geolocator, url_launcher, sqflite, http, intl); run `flutter pub get`
- [x] T006 [P] Configure backend test harness in `backend/tests/conftest.py` (pytest fixtures: test DB/session, FastAPI TestClient)

---

## Phase 2: Foundational (Blocking Prerequisites)

**⚠️ CRITICAL**: Must complete before any user story.

- [x] T007 Configure SQLAlchemy engine/session/base in `backend/app/db/session.py` and `backend/app/db/base.py`
- [x] T008 Initialize Alembic in `backend/alembic/` wired to `config.DATABASE_URL` and `db.base` metadata
- [x] T009 Define PostgreSQL enum types and all ORM models per data-model.md in `backend/app/models/` (`user.py`, `auth_identity.py`, `otp_code.py`, `refresh_token.py`, `service_category.py`, `category_helper_type.py`, `helper_profile.py`, `service_request.py`, `helper_location_update.py`, `review.py`)
- [x] T010 Generate initial Alembic migration (all tables, enums, indexes on helper lat/long and `(request_id, recorded_at)`) in `backend/alembic/versions/`
- [x] T011 [P] Implement security core in `backend/app/core/security.py` (bcrypt hash/verify, JWT encode/decode, token TTLs)
- [x] T012 [P] Implement auth dependencies in `backend/app/core/deps.py` (`get_current_user`, `require_helper`, participant checks) returning 401/403
- [x] T013 Implement global error handler + error envelope `{error:{code,message,details}}` in `backend/app/core/errors.py` and wire into `backend/app/main.py`
- [x] T014 Create FastAPI app + v1 router wiring + `/docs` in `backend/app/main.py`
- [x] T015 [P] Implement seed script in `backend/app/seed/run.py` (service categories + category↔helper_type map + ~20 demo helpers around a default city with varied types/hours/ratings)
- [x] T016 [P] Implement Haversine + bounding-box helper in `backend/app/services/geo.py` (distance_km, is_far >15km)
- [x] T017 Flutter network layer: `lib/core/network/api_client.dart` (base URL via `API_BASE_URL` dart-define, JSON, error mapping) + `lib/core/network/token_store.dart` (flutter_secure_storage) + auth header interceptor
- [x] T018 [P] Flutter app shell/router in `lib/main.dart` + `lib/presentation/state/app_state.dart` (auth-gated routing: welcome → home; guest allowed) reusing existing theme/i18n
- [x] T019 [P] Extend localization scaffolding in `lib/core/i18n/app_localization.dart` with keys for new auth/request/profile screens (en + hi placeholders)

**Checkpoint**: Backend boots, migrations apply, seed runs; Flutter shell launches and reaches the API.

---

## Phase 3: User Story 1 — Sign in and find the nearest help (Priority: P1) 🎯 MVP

**Goal**: Auth (phone OTP, email+password, Google, guest) + home (search + category grid) +
nearest-helper discovery with call/directions.

**Independent Test**: Complete any sign-in method (or guest), pick a category, see nearest helpers
sorted by distance with working call/directions.

### Tests for User Story 1 ⚠️ (write first, must fail)

- [x] T020 [P] [US1] Contract tests for `/auth/*` in `backend/tests/contract/test_auth.py` (email register/login, phone request/verify-otp dev path, google dev path, refresh, me, logout)
- [x] T021 [P] [US1] Contract tests for `/categories` and `/helpers/nearby|search|{id}` in `backend/tests/contract/test_helpers.py` (sorting, distance_km, is_far>15km, open_now null when hours unknown)
- [x] T022 [P] [US1] Unit test Haversine + nearest sort + far flag in `backend/tests/unit/test_geo.py`
- [x] T023 [P] [US1] Flutter unit test distance/sort in `test/unit/distance_test.dart` and auth-gate logic in `test/unit/auth_gate_test.dart`

### Backend implementation for User Story 1

- [x] T024 [P] [US1] Pydantic schemas in `backend/app/schemas/auth.py`, `schemas/user.py`, `schemas/helper.py`, `schemas/category.py`
- [x] T025 [US1] Auth service in `backend/app/services/auth_service.py` (register/login email, OTP issue/verify with hashed code + dev fallback `000000`, Google verify via httpx + dev fallback, refresh/rotate, logout/revoke, dedupe identities → 409)
- [x] T026 [US1] Auth router in `backend/app/api/v1/auth.py` implementing all `/auth/*` per contract
- [x] T027 [P] [US1] Category service + router in `backend/app/services/category_service.py` and `backend/app/api/v1/categories.py`
- [x] T028 [US1] Helper discovery service in `backend/app/services/helper_service.py` (nearby, search by name/type/location, get-by-id, `GET /helpers` sync feed) using `geo.py`
- [x] T029 [US1] Helpers router in `backend/app/api/v1/helpers.py` (`/helpers/nearby`, `/helpers/search`, `/helpers`, `/helpers/{id}`)

### Flutter implementation for User Story 1

- [x] T030 [P] [US1] Client models in `lib/data/models/` (`user.dart`, `auth_session.dart`, `category.dart`, extend `helper.dart` with rating/source/open_now/distance)
- [x] T031 [P] [US1] API providers in `lib/data/providers/` (`auth_api.dart`, `helper_api.dart`, `category_api.dart`)
- [x] T032 [US1] Auth repository `lib/data/repositories/auth_repository.dart` + token persistence; `lib/presentation/state/auth_state.dart` (signed-in/guest, session restore on launch)
- [x] T033 [US1] Extend `lib/data/repositories/helper_repository.dart` to fetch from API and upsert SQLite cache (`lib/data/repositories/local_db.dart`) with `last_synced_at`
- [x] T034 [P] [US1] Use cases `lib/domain/usecases/sign_in.dart`, `find_nearest_helpers.dart` (extend existing), `search_helpers.dart`
- [x] T035 [US1] Welcome screen `lib/presentation/screens/welcome_screen.dart` (Uber/Rapido-style, method buttons + guest)
- [x] T036 [US1] Auth screens: `lib/presentation/screens/auth/email_auth_screen.dart`, `phone_otp_screen.dart`, `google_signin_screen.dart` (dev button) with validation + error states
- [x] T037 [US1] Home screen `lib/presentation/screens/home_screen.dart` (search bar + `lib/presentation/widgets/category_grid.dart`) — interactive Uber-style grid
- [x] T038 [US1] Helper list/search results reusing/extending `lib/presentation/screens/helper_list_screen.dart` + `lib/presentation/widgets/helper_card.dart` (distance, rating, open/closed/“hours unknown”, far-away flag, one-tap call)
- [x] T039 [US1] Wire call/SMS/directions via `url_launcher` (reuse existing helper actions) and guest→auth prompt on gated actions
- [x] T040 [US1] Add logging for GPS/permission/sync errors (Flutter) and auth failures (backend, no creds in logs)

**Checkpoint**: A user can sign in (any method/guest), browse categories, and reach a helper. MVP shippable.

---

## Phase 4: User Story 2 — Request a helper and track them live (Priority: P1)

**Goal**: Seeker submits a request and watches status + live helper position to completion; cancel
supported; completion unlocks rating.

**Independent Test**: Submit a request; advance it (via helper or test harness); seeker sees each
status change and the moving live marker; completion offers rating.

### Tests for User Story 2 ⚠️

- [x] T041 [P] [US2] Contract tests for `/requests/*` in `backend/tests/contract/test_requests.py` (create, mine, get, status transitions, cancel, location)
- [x] T042 [P] [US2] Unit test request state machine + illegal-transition rejection in `backend/tests/unit/test_request_state.py`
- [x] T043 [P] [US2] Integration test seeker lifecycle (requested→…→completed + live location) in `backend/tests/integration/test_request_flow.py`
- [x] T044 [P] [US2] Flutter unit test status-timeline mapping in `test/unit/request_status_test.dart`

### Backend implementation for User Story 2

- [x] T045 [P] [US2] Schemas in `backend/app/schemas/request.py` (create, status update, location, response with `helper_location`)
- [x] T046 [US2] Request service in `backend/app/services/request_service.py` (create requested, get/mine with participant auth, status transition validation + timestamps, cancel, record location + latest fetch)
- [x] T047 [US2] Requests router in `backend/app/api/v1/requests.py` (`POST /requests`, `/requests/mine`, `/requests/{id}`, `/requests/{id}/status`, `/requests/{id}/cancel`, `/requests/{id}/location`)

### Flutter implementation for User Story 2

- [x] T048 [P] [US2] `lib/data/models/service_request.dart` + `lib/data/providers/request_api.dart` + `lib/data/repositories/request_repository.dart`
- [x] T049 [P] [US2] Use cases `lib/domain/usecases/submit_request.dart`, `track_request.dart`; `lib/presentation/state/request_state.dart` (poll active request ~3–5s)
- [x] T050 [US2] Helper detail screen `lib/presentation/screens/helper_detail_screen.dart` with “Request help” (guest→auth gate)
- [x] T051 [US2] Request tracking screen `lib/presentation/screens/request_tracking_screen.dart` with `lib/presentation/widgets/status_timeline.dart` and live helper marker on map (extend `lib/presentation/screens/map_screen.dart`)
- [x] T052 [US2] Cancel action + offline/“needs connection” state for online-only request actions (FR-027)

**Checkpoint**: Seeker can request and live-track a helper end to end; cancel works; completion unlocks rating.

---

## Phase 5: User Story 3 — Act as a helper/provider (Priority: P2)

**Goal**: Helper toggles provider mode, sees nearby open requests, accepts/declines, advances
status, and shares live location (first-accept-wins).

**Independent Test**: As a helper, receive a request, accept it, advance statuses, post location;
seeker side reflects all changes; a second helper cannot accept the same request.

### Tests for User Story 3 ⚠️

- [x] T053 [P] [US3] Contract tests for `/requests/open`, `/requests/{id}/accept|decline`, `POST /helpers` in `backend/tests/contract/test_provider.py`
- [x] T054 [P] [US3] Integration test first-accept-wins concurrency in `backend/tests/integration/test_accept_race.py`

### Backend implementation for User Story 3

- [x] T055 [US3] Extend `request_service.py` with open-requests query (by helper type + distance) and atomic accept (conditional UPDATE `status='requested' AND helper_id IS NULL` → 409 if taken) + decline
- [x] T056 [US3] Add `/requests/open`, `/requests/{id}/accept`, `/requests/{id}/decline` to requests router; helper-profile upsert `POST /helpers` in `backend/app/api/v1/helpers.py` + `helper_service.py`

### Flutter implementation for User Story 3

- [x] T057 [P] [US3] Provider state `lib/presentation/state/provider_state.dart` + `request_api.dart` open/accept/decline/location methods
- [x] T058 [US3] Provider mode toggle + inbox screen `lib/presentation/screens/provider/provider_inbox_screen.dart` (incoming requests with type + seeker distance, accept/decline)
- [x] T059 [US3] Active job screen `lib/presentation/screens/provider/provider_job_screen.dart` (advance status, periodic location posting from device GPS while active)

**Checkpoint**: Two-sided flow demonstrable across two clients; race handled.

---

## Phase 6: User Story 4 — Profile, history, and ratings (Priority: P3)

**Goal**: View/edit profile, see request history (both roles), rate completed requests (one each),
helper aggregate updates.

**Independent Test**: Edit profile and confirm persistence; open history; submit a rating and see
the helper average update; cannot review twice or self-review.

### Tests for User Story 4 ⚠️

- [x] T060 [P] [US4] Contract tests for `/profile` (get/patch) and `/reviews` + `/helpers/{id}/reviews` in `backend/tests/contract/test_profile_reviews.py`
- [x] T061 [P] [US4] Unit test review rules (one-per-request, 1–5 range, no self-review, aggregate recompute) in `backend/tests/unit/test_reviews.py`

### Backend implementation for User Story 4

- [x] T062 [P] [US4] Schemas `backend/app/schemas/review.py` + profile patch in `schemas/user.py`
- [x] T063 [US4] Profile service/router `backend/app/services/profile_service.py` + `backend/app/api/v1/profile.py` (GET/PATCH, vehicle_info, preferred_language)
- [x] T064 [US4] Review service/router `backend/app/services/review_service.py` + `backend/app/api/v1/reviews.py` (create with validation, list, recompute `rating_avg`/`rating_count`)

### Flutter implementation for User Story 4

- [x] T065 [P] [US4] `lib/data/models/review.dart` + `lib/data/providers/review_api.dart` + `profile`/`review` repositories
- [x] T066 [US4] Profile screen `lib/presentation/screens/profile_screen.dart` (view/edit, persist) and history screen `lib/presentation/screens/history_screen.dart` (seeker/helper toggle)
- [x] T067 [US4] Rating widget `lib/presentation/widgets/rating_stars.dart` + post-completion review sheet wired from request tracking; show helper average on cards/detail

**Checkpoint**: Profiles, history, and ratings complete; trust signals visible.

---

## Phase 7: User Story 5 — Switch language anytime (Priority: P3)

**Goal**: Language switch from settings/profile updates all screens and persists; mirrors to
profile when signed in.

**Independent Test**: Switch language; all major screens update; persists across restart.

### Tests for User Story 5 ⚠️

- [x] T068 [P] [US5] Flutter widget test language switch updates text + persists in `test/widget/language_switch_test.dart`

### Implementation for User Story 5

- [x] T069 [US5] Settings screen `lib/presentation/screens/settings_screen.dart` with `lib/presentation/widgets/language_switcher.dart` (extend existing) covering all new screens
- [x] T070 [US5] Persist language locally (SQLite/prefs) and PATCH `preferred_language` to profile when authenticated; complete en + hi strings (and stubs for additional Indian languages) in `lib/core/i18n/`

**Checkpoint**: Localization spans the full app and persists.

---

## Phase 8: Polish & Cross-Cutting Concerns

- [x] T071 [P] Backend README + run instructions in `backend/README.md`; verify `/docs` reflects all contracts
- [x] T072 [P] Update root `README.md` with full-stack run steps (mirror quickstart.md)
- [x] T073 Security pass: confirm bcrypt, HTTPS-only assumptions, server-side authz on every protected route, input validation, no secrets/PII in logs (Constitution II)
- [x] T074 [P] Offline resilience pass: cached discovery + call/SMS work with backend down; “needs connection” on online-only actions; “last updated” freshness shown
- [x] T075 [P] UI/UX polish pass across screens (consistent theme, loading/empty/error states, responsive mobile + web)
- [x] T076 Run `backend/` `pytest` and `flutter test`; fix failures
- [x] T077 Execute `quickstart.md` end-to-end (two clients for two-sided flow) and capture demo screenshots

---

## Dependencies & Execution Order

- **Setup (P1)** → **Foundational (P2)** blocks all stories.
- **US1 (P1)** is the MVP; **US2 (P1)** depends on US1 auth + helper data; **US3 (P2)** depends on
  US2 request model; **US4 (P3)** depends on completed requests (US2); **US5 (P3)** is largely
  independent (touches all screens, do after they exist).
- **Polish (P8)** last.

### Within each story
- Tests first (must fail) → models/schemas → services → endpoints/UI → integration.

### Parallel opportunities
- Setup: T003–T006 in parallel. Foundational: T011, T012, T015, T016, T018, T019 in parallel.
- Within a story, [P] tasks (distinct files) run together; backend and Flutter tracks for the same
  story can proceed in parallel once that story's schemas/contracts are fixed.

---

## Implementation Strategy

- **MVP**: Phases 1–3 (Setup + Foundational + US1) → sign in + find/call a helper. Stop & validate.
- **Increment 2**: US2 live request tracking (completes the core marketplace loop).
- **Increment 3**: US3 provider side (true two-sided demo).
- **Increment 4**: US4 profile/history/ratings, then US5 localization, then Polish.

## Notes
- [P] = different files, no incomplete dependencies. [US#] maps task to its story.
- Verify tests fail before implementing (Constitution: Test-First, NON-NEGOTIABLE).
- Commit after each task or logical group.
