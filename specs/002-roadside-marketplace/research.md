# Phase 0 Research: Roadside Help — Two-Sided Marketplace

All Technical Context unknowns are resolved below. Format per decision: **Decision / Rationale /
Alternatives considered**.

## 1. Backend framework & PostgreSQL access

- **Decision**: FastAPI (Python 3.11+) with SQLAlchemy 2.x ORM, Alembic migrations, and the
  `psycopg` v3 driver against PostgreSQL.
- **Rationale**: FastAPI gives auto-generated OpenAPI docs (free, demonstrable contracts),
  Pydantic validation satisfies "validate all input", and async support is ample for prototype
  load. SQLAlchemy + Alembic gives a clean, versioned, normalized schema.
- **Alternatives considered**: Node/Express (less batteries-included validation/docs); Supabase
  (rejected by user — wanted a custom backend); Django (heavier than needed for an API-only
  prototype).

## 2. Geospatial "nearest helper" queries

- **Decision**: Store `latitude`/`longitude` as numeric columns; pre-filter candidates with a
  bounding-box WHERE clause (indexed on lat/long), then compute exact straight-line (Haversine)
  distance in the service layer and sort nearest-first. The Flutter client also computes Haversine
  locally for the offline cache.
- **Rationale**: Meets FR-010/FR-011 (straight-line distance, no fixed cut-off, flag > 15 km)
  without a PostGIS dependency — simpler to install and run for a prototype, and identical math is
  reused offline.
- **Alternatives considered**: PostGIS `ST_DWithin`/`ST_Distance` (more powerful, but adds an
  extension and setup friction not justified at prototype scale); DB-side trig (less portable).

## 3. Authentication strategy (4 methods)

- **Decision**: One canonical `User` with multiple linked `AuthIdentity` rows (provider ∈
  {phone, email, google}). Issue short-lived JWT access tokens + a longer-lived refresh token;
  store tokens on device in `flutter_secure_storage`.
  - **Email+password**: bcrypt via `passlib`; login verifies hash.
  - **Phone OTP**: server generates a 6-digit code with short TTL stored hashed; verifying the
    code logs in / creates the user. **Mock fallback**: when no SMS provider is configured, the
    API returns/logs the code (and accepts a fixed dev code `000000`), clearly flagged as dev mode.
  - **Google**: verify the Google ID token server-side via Google's tokeninfo/certs. **Mock
    fallback**: when no `GOOGLE_CLIENT_ID` is set, accept a signed dev payload `{email,name}` from
    a labelled dev button.
  - **Guest**: client-side ephemeral session with no token; gated actions trigger an auth prompt
    (FR-005).
- **Rationale**: Decoupling identities from the user record supports all four methods and future
  linking without schema churn; JWT is stateless and simple to verify on every protected route
  (Constitution II). Mock fallbacks keep the prototype fully demonstrable without paid services
  while never failing silently.
- **Alternatives considered**: Server-side sessions/cookies (works for web but awkward for mobile
  clients); third-party auth (Firebase/Auth0/Supabase) rejected with the custom-backend decision.

## 4. Live tracking transport

- **Decision**: HTTP polling. The assigned helper POSTs location every few seconds while a request
  is active; the seeker GETs the active request (status + latest helper location) on a short
  interval (~3–5 s). Store each ping as a `helper_location_update` row; expose the latest.
- **Rationale**: Satisfies SC-003 (≤ 10 s propagation) with the simplest possible mechanism
  (Constitution III). No websocket/server-push infrastructure to operate for a prototype.
- **Alternatives considered**: WebSockets / SSE (true push, lower latency) — unnecessary for a
  ~10 s freshness target and adds connection-management complexity; Firebase Realtime DB (external
  dependency, conflicts with custom-backend decision).

## 5. Request lifecycle & concurrency (first-accept-wins)

- **Decision**: `ServiceRequest.status` enum: `requested → accepted → on_the_way → arrived →
  completed`, plus terminal `cancelled`. Acceptance uses a conditional UPDATE (`SET helper_id, status='accepted' WHERE id=? AND status='requested' AND helper_id IS NULL`)
  inside a transaction; zero rows updated ⇒ already taken (FR-019). Allowed transitions enforced
  in the service layer.
- **Rationale**: The conditional update is an atomic, race-free first-accept-wins without locks or
  queues. Explicit transition validation keeps state machine correct and testable.
- **Alternatives considered**: Row locks / SELECT FOR UPDATE (heavier); optimistic version column
  (also fine, but the conditional update is simpler for this single transition).

## 6. Maps & directions

- **Decision**: Keep `flutter_map` + `latlong2` (OpenStreetMap tiles) for the in-app map (user
  position, helper markers, live assigned-helper marker). Delegate turn-by-turn directions to the
  device maps app via `url_launcher` (`geo:`/Google/Apple maps URL). Reuse existing `map_screen`.
- **Rationale**: No API key/billing, already integrated, works on mobile + web (FR-024). Directions
  delegation matches FR-012 and feature 001.
- **Alternatives considered**: Google Maps SDK (richer, needs key/billing — rejected by user).

## 7. Offline-first cache & sync

- **Decision**: Retain SQLite (`sqflite`) helper cache and language preference from feature 001.
  Add a sync that pulls helpers from `GET /helpers` into the cache with a `last_synced_at` stamp.
  Discovery reads cache first (works offline); online enriches with live data. Online-only actions
  (submit/track request, reviews) show a "needs connection" state when offline (FR-026/FR-027).
- **Rationale**: Preserves feature 001's offline guarantees while layering the online marketplace.
- **Alternatives considered**: Full offline write queue for requests (out of scope for prototype;
  emergencies needing a live helper inherently need connectivity).

## 8. Localization scaling

- **Decision**: Continue the existing `app_localization` approach with per-language string maps
  (ARB/JSON-style), extended to cover new auth/request/profile screens. Language preference stored
  locally (SQLite/prefs) and mirrored to the user profile when signed in.
- **Rationale**: Meets FR-029 (switch anytime, persist, scale without feature-logic changes).
- **Alternatives considered**: Server-driven translations (unnecessary network dependency for UI
  strings in a prototype).

## 9. Secrets & configuration

- **Decision**: Backend reads config from environment via `pydantic-settings` (`DATABASE_URL`,
  `JWT_SECRET`, `GOOGLE_CLIENT_ID`, optional `SMS_*`). Provide `.env.example`; real `.env` is
  gitignored. Flutter reads `API_BASE_URL` via `--dart-define` with a localhost default.
- **Rationale**: Constitution II — no committed secrets; environment-based config.
- **Alternatives considered**: Hard-coded config (violates constitution); secrets manager
  (overkill for prototype).

## Outstanding NEEDS CLARIFICATION

None. All items from Technical Context are resolved.
