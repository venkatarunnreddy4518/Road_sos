# REST API Contract — Roadside Help Backend (v1)

Base URL: `{API_BASE_URL}/api/v1`. All traffic HTTPS. JSON request/response. Auth via
`Authorization: Bearer <access_token>` except where noted. Errors use:
`{ "error": { "code": string, "message": string, "details"?: object } }` with appropriate HTTP
status. IDs are UUID strings. Timestamps are ISO-8601 UTC.

Common status codes: `400` validation, `401` unauthenticated, `403` forbidden, `404` not found,
`409` conflict (e.g. duplicate identity, request already accepted), `422` semantic validation.

---

## Auth — `/auth`  (public unless noted)

### POST /auth/email/register
Req: `{ "display_name": str, "email": str, "password": str }`
Res `201`: `{ "user": User, "access_token": str, "refresh_token": str }`
Errors: `409` email already registered (→ login).

### POST /auth/email/login
Req: `{ "email": str, "password": str }` → `200` `{ user, access_token, refresh_token }`; `401` bad creds.

### POST /auth/phone/request-otp
Req: `{ "phone": str }` → `200` `{ "sent": true, "dev_code"?: str }`
Note: `dev_code` returned only in dev/mock mode (no SMS provider); flagged in response.

### POST /auth/phone/verify-otp
Req: `{ "phone": str, "code": str, "display_name"?: str }`
Res `200`: `{ user, access_token, refresh_token }` (creates user on first verify). `401` invalid/expired code.

### POST /auth/google
Req: `{ "id_token": str }`  *(or dev payload `{ "dev_email": str, "dev_name": str }` in mock mode)*
Res `200`: `{ user, access_token, refresh_token }`; `401` invalid token.

### POST /auth/refresh
Req: `{ "refresh_token": str }` → `200` `{ access_token, refresh_token }`; `401` invalid/revoked.

### POST /auth/logout  (auth)
Req: `{ "refresh_token": str }` → `204`. Revokes the refresh token (FR-002).

### GET /auth/me  (auth)
Res `200`: `User`.

---

## Profile — `/profile`  (auth)

### GET /profile → `200` `User`
### PATCH /profile
Req (any subset): `{ "display_name"?, "phone"?, "vehicle_info"?, "preferred_language"? }`
Res `200`: `User`. (FR-020)

---

## Categories — `/categories`  (public)

### GET /categories
Res `200`: `[ { id, key, name, icon, sort_order, helper_types: [helper_type] } ]` (FR-008).

---

## Helpers / Discovery & Search — `/helpers`  (public)

### GET /helpers/nearby
Query: `lat` (req), `lng` (req), `category` (key, optional), `helper_type` (optional),
`limit` (default 3, max 50).
Res `200`: `[ HelperWithDistance ]` sorted nearest-first; each includes `distance_km` and
`is_far` (true when > 15 km). No fixed cut-off (FR-010/FR-011).

### GET /helpers/search
Query: `q` (name/type/location text), `lat?`, `lng?`, `limit?`.
Res `200`: `[ HelperWithDistance ]` (FR-009).

### GET /helpers  (sync feed for offline cache)
Query: `updated_since?` (ISO ts), `limit?`, `cursor?`.
Res `200`: `{ "helpers": [Helper], "synced_at": ts, "next_cursor"?: str }` (FR-026/FR-028).

### GET /helpers/{id}
Res `200`: `HelperDetail` (profile + recent reviews + rating aggregate).

### POST /helpers  (auth, helper role) — register/update own helper profile
Req: `{ name, helper_type, phone?, sms_capable?, latitude, longitude, address?, opening_hours? }`
Res `201/200`: `Helper` (FR-007).

---

## Service Requests — `/requests`  (auth)

### POST /requests  (seeker)
Req: `{ "category_id": uuid, "pickup_lat": num, "pickup_lng": num, "target_helper_id"?: uuid, "note"?: str }`
Res `201`: `ServiceRequest` in `requested`. Broadcast when `target_helper_id` omitted (FR-013).

### GET /requests/mine
Query: `role` = `seeker|helper` (default seeker), `status?`, `active_only?`.
Res `200`: `[ ServiceRequest ]` — history + active (FR-021).

### GET /requests/open  (auth, helper role)
Query: `lat`, `lng`, `radius_km?`.
Res `200`: `[ ServiceRequestForHelper ]` — broadcastable/targeted open requests matching the
helper's type, with seeker distance (FR-009/Story 3).

### GET /requests/{id}  (auth, participant)
Res `200`: `ServiceRequest` incl. `status`, timestamps, and `helper_location` (latest live point
when active). Polled by seeker for live updates (FR-016/FR-017).

### POST /requests/{id}/accept  (auth, helper)
Res `200`: `ServiceRequest` (now `accepted`, assigned). `409` if already accepted (first-accept-
wins, FR-015/FR-019).

### POST /requests/{id}/decline  (auth, helper)
Res `200`: leaves request open to others (FR-015).

### POST /requests/{id}/status  (auth, assigned helper)
Req: `{ "status": "on_the_way" | "arrived" | "completed" }`
Res `200`: `ServiceRequest`. `422` on illegal transition (FR-014/FR-016).

### POST /requests/{id}/cancel  (auth, seeker or assigned helper)
Res `200`: `ServiceRequest` (`cancelled`) (FR-018). `422` if already terminal.

### POST /requests/{id}/location  (auth, assigned helper)
Req: `{ "latitude": num, "longitude": num }`
Res `202`: `{ "recorded_at": ts }`. Posted periodically while active (FR-017).

---

## Reviews — `/reviews`  (auth, seeker)

### POST /reviews
Req: `{ "request_id": uuid, "rating": 1..5, "comment"?: str }`
Res `201`: `Review`. Recomputes helper aggregate. `409` if request already reviewed; `422` if
request not completed, rating out of range, or self-review (FR-022/FR-023).

### GET /helpers/{id}/reviews
Res `200`: `{ rating_avg, rating_count, reviews: [Review] }`.

---

## Schemas (response shapes)

```jsonc
User = { id, display_name, email?, phone?, is_helper, preferred_language, vehicle_info? }

Helper = { id, name, helper_type, phone?, sms_capable, latitude, longitude, address?,
           opening_hours?, data_source, is_verified, rating_avg, rating_count }

HelperWithDistance = Helper & { distance_km: number, is_far: boolean, open_now: boolean|null }
// open_now = null ⇒ "hours unknown"

HelperDetail = Helper & { reviews: [Review] }

ServiceRequest = { id, seeker_user_id, category_id, target_helper_id?, helper_id?, status,
                   pickup_lat, pickup_lng, note?, requested_at, accepted_at?, on_the_way_at?,
                   arrived_at?, completed_at?, cancelled_at?, helper_location? }

helper_location = { latitude, longitude, recorded_at } | null

Review = { id, request_id, helper_id, seeker_user_id, rating, comment?, created_at }
```

## Authorization rules (server-side, Constitution II)

- All `/requests/*` (except none) require auth; participant check: only the seeker or the assigned/
  targeted helper may read/modify a request.
- `accept`/`decline`/`status`/`location` require the caller to be a helper; `status`/`location`
  require the caller to be the **assigned** helper.
- `POST /reviews` requires the caller to be the request's seeker and the request `completed`.
- Guests have no token ⇒ all `auth`-marked endpoints return `401`, driving the client auth prompt.
