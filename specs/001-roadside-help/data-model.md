# Data Model: Roadside Help

This document defines the data entities, relationships, and validation rules for the Roadside Help feature.

## Entities

### 1. Helper
Represents a service provider (e.g., puncture shop, mechanic).

| Field | Type | Description | Validation / Notes |
|-------|------|-------------|-------------------|
| `id` | String | Unique identifier (UUID) | Primary Key |
| `name` | String | Display name of the helper | Mandatory |
| `type` | Enum | `PUNCTURE_SHOP`, `PETROL_PUMP`, `MECHANIC` | Mandatory |
| `latitude` | Double | GPS latitude | -90.0 to 90.0 |
| `longitude` | Double | GPS longitude | -180.0 to 180.0 |
| `phoneNumber` | String | Primary contact number | E.164 format recommended |
| `smsCapable` | Boolean | Whether SMS is a valid contact method | Default: `true` |
| `openingHours` | String | Opening hours description (e.g., "24/7", "09:00-18:00") | Nullable; "Hours Unknown" if null |
| `source` | Enum | `CURATED`, `THIRD_PARTY` | `CURATED` overrides `THIRD_PARTY` |
| `lastUpdated` | Timestamp | Last time this record was synced | Used for freshness indicator |

### 2. ProblemType
The category of issue the user selects.

| Field | Type | Description | Notes |
|-------|------|-------------|--------|
| `id` | String | Unique identifier (e.g., `puncture`) | Primary Key |
| `label` | LocalizedString | Display name (e.g., "Puncture / Flat Tyre") | Handled via i18n ARB files |
| `mappedTypes` | List\<Enum\> | The `Helper.type` values this problem maps to | e.g., `puncture` -> `[PUNCTURE_SHOP]` |

### 3. UserLocation
The current reference point for distance calculations.

| Field | Type | Description | Notes |
|-------|------|-------------|--------|
| `latitude` | Double | User's latitude | From GPS or manual entry |
| `longitude` | Double | User's longitude | From GPS or manual entry |
| `timestamp` | Timestamp | When the location was acquired | To judge location staleness |
| `isManual` | Boolean | Whether the user set this location manually | If `true`, skip GPS prompts |

### 4. AppConfig
Persisted app settings.

| Field | Type | Description | Notes |
|-------|------|-------------|--------|
| `languageCode` | String | ISO 639-1 code (e.g., `en`, `hi`) | Persisted across sessions |
| `lastSyncTime` | Timestamp | The last successful sync with the backend | Displayed as "Updated X mins ago" |

## Relationships

- **ProblemType $\rightarrow$ Helper**: A `ProblemType` maps to one or more `Helper.type` values. The UI filters `Helpers` based on the selected `ProblemType`.
- **UserLocation $\rightarrow$ Helper**: A 1:N relationship where distance is computed from one `UserLocation` to many `Helpers`.

## State Transitions & Validation

### Location Acquisition
1. **Request Permission** $\rightarrow$ (Granted) $\rightarrow$ **Fetch GPS** $\rightarrow$ **Update `UserLocation`**.
2. **Request Permission** $\rightarrow$ (Denied/Disabled) $\rightarrow$ **Prompt Manual Entry** $\rightarrow$ **Update `UserLocation`**.

### Sync Process
1. **Fetch Remote Data** $\rightarrow$ **Parse JSON** $\rightarrow$ **Apply Source-Priority Merge** $\rightarrow$ **Update SQLite Cache**.
2. **Update `AppConfig.lastSyncTime`**.

## Storage Strategy (SQLite)

- `Table: helpers` (id, name, type, lat, lng, phone, sms_capable, hours, source, last_updated)
- `Table: problem_types` (id, mapped_types_csv)
- `Table: config` (key, value)
