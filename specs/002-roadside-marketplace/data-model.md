# Phase 1 Data Model: Roadside Help — Two-Sided Marketplace

Normalized PostgreSQL schema. All tables use a UUID primary key (`id`) and `created_at` /
`updated_at` timestamptz unless noted. Names are `snake_case`. Enums are PostgreSQL enum types.

## Enums

- `user_role`: `seeker`, `helper`  *(a user may be both via role flags; seeker is default)*
- `auth_provider`: `phone`, `email`, `google`
- `helper_type`: `puncture_shop`, `petrol_pump`, `mechanic`, `towing`, `battery`
- `data_source`: `curated`, `third_party`
- `request_status`: `requested`, `accepted`, `on_the_way`, `arrived`, `completed`, `cancelled`

## Tables

### `users`
| column | type | notes |
|---|---|---|
| id | uuid PK | |
| display_name | text | not null |
| email | citext UNIQUE NULL | nullable; unique when present |
| phone | text UNIQUE NULL | E.164; unique when present |
| is_helper | boolean | default false (can act as provider) |
| preferred_language | text | default `'en'` |
| created_at / updated_at | timestamptz | |

Validation: at least one auth identity required for a persisted account; `email`/`phone` unique
when non-null (FR-004).

### `auth_identities`
| column | type | notes |
|---|---|---|
| id | uuid PK | |
| user_id | uuid FK → users.id | on delete cascade |
| provider | auth_provider | |
| provider_uid | text | google sub / phone / email |
| password_hash | text NULL | only for `email` provider (bcrypt) |
| UNIQUE | (provider, provider_uid) | one identity per provider uid |

Relationship: a `user` has many `auth_identities` (FR-001/FR-003). Passwords stored only hashed.

### `otp_codes`  *(phone OTP, prototype)*
| column | type | notes |
|---|---|---|
| id | uuid PK | |
| phone | text | |
| code_hash | text | hashed 6-digit code |
| expires_at | timestamptz | short TTL (e.g. 5 min) |
| consumed_at | timestamptz NULL | single-use |

### `refresh_tokens`
| column | type | notes |
|---|---|---|
| id | uuid PK | |
| user_id | uuid FK → users.id | cascade |
| token_hash | text | hashed refresh token |
| expires_at | timestamptz | |
| revoked_at | timestamptz NULL | logout (FR-002) |

### `service_categories`
| column | type | notes |
|---|---|---|
| id | uuid PK | |
| key | text UNIQUE | e.g. `puncture`, `fuel`, `breakdown`, `towing`, `battery` |
| name | text | display (localized client-side by key) |
| icon | text | icon identifier |
| sort_order | int | grid order |

### `category_helper_types`  *(many-to-many: category ↔ helper_type)*
| column | type | notes |
|---|---|---|
| category_id | uuid FK → service_categories.id | |
| helper_type | helper_type | |
| PK | (category_id, helper_type) | maps FR-008 |

### `helper_profiles`
| column | type | notes |
|---|---|---|
| id | uuid PK | |
| owner_user_id | uuid FK → users.id NULL | set when provider-run; null for curated/3rd-party |
| name | text | not null |
| helper_type | helper_type | |
| phone | text NULL | call action |
| sms_capable | boolean | default false |
| latitude | double precision | indexed |
| longitude | double precision | indexed |
| address | text NULL | |
| opening_hours | jsonb NULL | null ⇒ "hours unknown" (FR-003a/FR-010) |
| data_source | data_source | default `curated` |
| is_verified | boolean | default false |
| rating_avg | numeric(2,1) | default 0 (denormalized aggregate) |
| rating_count | int | default 0 |
| is_active | boolean | default true |

Index: `(latitude, longitude)` for bounding-box pre-filter; `(helper_type)`.

### `service_requests`
| column | type | notes |
|---|---|---|
| id | uuid PK | |
| seeker_user_id | uuid FK → users.id | not null |
| category_id | uuid FK → service_categories.id | |
| target_helper_id | uuid FK → helper_profiles.id NULL | direct request, null ⇒ broadcast |
| helper_id | uuid FK → helper_profiles.id NULL | assigned on accept |
| status | request_status | default `requested` |
| pickup_lat / pickup_lng | double precision | seeker location (FR-013) |
| note | text NULL | problem description |
| requested_at | timestamptz | |
| accepted_at / on_the_way_at / arrived_at / completed_at / cancelled_at | timestamptz NULL | per-state stamps (FR-014) |
| cancelled_by | uuid FK → users.id NULL | |

State machine (FR-014/FR-015/FR-018): `requested → accepted → on_the_way → arrived → completed`;
`cancelled` reachable from any non-terminal state. First-accept-wins via conditional UPDATE on
`status='requested' AND helper_id IS NULL` (FR-019).

### `helper_location_updates`
| column | type | notes |
|---|---|---|
| id | uuid PK | |
| request_id | uuid FK → service_requests.id | cascade; indexed |
| helper_id | uuid FK → helper_profiles.id | |
| latitude / longitude | double precision | |
| recorded_at | timestamptz | latest used for live marker (FR-017) |

Index: `(request_id, recorded_at desc)` to fetch latest position quickly.

### `reviews`
| column | type | notes |
|---|---|---|
| id | uuid PK | |
| request_id | uuid FK → service_requests.id UNIQUE | one review per request (FR-022) |
| helper_id | uuid FK → helper_profiles.id | |
| seeker_user_id | uuid FK → users.id | |
| rating | int CHECK (1..5) | FR-023 reject out-of-range |
| comment | text NULL | |
| created_at | timestamptz | |

Rule (FR-023): seeker cannot be the helper's owner (no self-review); writing a review recomputes
`helper_profiles.rating_avg` / `rating_count`.

## Relationships (summary)

```
users 1──* auth_identities
users 1──* refresh_tokens
users 1──0..1 helper_profiles (owner_user_id)
service_categories *──* helper_type (via category_helper_types)
users(seeker) 1──* service_requests *──1 service_categories
service_requests *──0..1 helper_profiles (helper_id, target_helper_id)
service_requests 1──* helper_location_updates
service_requests 1──0..1 reviews ──* helper_profiles
```

## Local SQLite cache (Flutter, offline)

- `cached_helpers`: id, name, helper_type, phone, sms_capable, latitude, longitude, opening_hours,
  rating_avg, rating_count, data_source, last_synced_at.
- `language_preference`: single-row selected language.
- Auth token + refresh token kept in `flutter_secure_storage` (not SQLite).

Distances (straight-line/Haversine) are computed at query time from the device's current GPS
position against cached/served coordinates — never stored — so they stay correct offline (FR-026).
