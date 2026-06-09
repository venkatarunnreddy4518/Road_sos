# Research: Roadside Help Implementation

This document resolves technical unknowns and validates design choices for the Roadside Help feature.

## 1. Hybrid Data Sync Strategy
**Goal**: Merge curated team-controlled data with third-party places data in a local cache.

- **Decision**: Implement a **Source-Priority Merge** strategy.
- **Rationale**: Curated data is authoritative. If a helper exists in both datasets, the curated version takes precedence.
- **Implementation**:
  - Local `helpers` table includes a `source` column (`curated` vs `third_party`).
  - During sync, `INSERT OR REPLACE` is used for curated data.
  - Third-party data is inserted only if no curated record exists for that specific location/entity.
  - A `last_synced_at` timestamp is maintained globally to notify users of data freshness.
- **Alternatives**:
  - *Separate Tables*: Rejected because it would complicate the "Find Nearest" query (would require a `UNION` and separate sorting logic).
  - *Real-time Merge*: Rejected as it violates the offline-first requirement.

## 2. Offline Distance Computation
**Goal**: Calculate straight-line distance from user coordinates to helpers without internet.

- **Decision**: Use the `geolocator` package's `distanceBetween` method.
- **Rationale**: It implements the Haversine formula, which is the standard for calculating the great-circle distance between two points on a sphere. It is computationally efficient and accurate for the ~15km scale of this feature.
- **Implementation**: 
  ```dart
  double distanceInMeters = Geolocator.distanceBetween(userLat, userLng, helperLat, helperLng);
  ```
- **Alternatives**: 
  - *Manual Haversine implementation*: Rejected as `geolocator` is a well-tested industry standard.
  - *Google Maps Distance Matrix*: Rejected as it requires an internet connection and is not offline-capable.

## 3. Local Storage Selection
**Goal**: Choose a local database for caching helpers.

- **Decision**: **SQLite** (via `sqflite` package).
- **Rationale**: The feature requires filtering by `problem_type` and sorting by `distance`. SQL is optimized for these relational queries.
- **Comparison**:
  - *Hive*: Faster for simple key-value lookups but lacks robust querying/sorting capabilities for lists of entities.
  - *Shared Preferences*: Only suitable for simple settings (like `language_preference`), not for a dataset of helpers.
- **Verdict**: SQLite provides the necessary query power and reliability for the helper cache.

## 4. Localization for Indian Languages
**Goal**: Implement a scalable system for English, Hindi, and other major Indian languages.

- **Decision**: Use the `flutter_localizations` package with `.arb` (Application Resource Bundle) files.
- **Rationale**: Standard Flutter approach that integrates with IDE tools for translation and supports dynamic language switching.
- **Implementation**:
  - Create separate `.arb` files for each supported language (e.g., `app_en.arb`, `app_hi.arb`).
  - Use `intl` for any date/number formatting.
  - Use Google Fonts (e.g., Noto Sans) to ensure consistent rendering across different Indian scripts.
- **Alternatives**: 
  - *Custom JSON maps*: Rejected because they lack the tooling and official support of ARB.
  - *Hardcoded strings*: Rejected as it's not scalable for multiple languages.

## Summary of Decisions

| Component | Choice | Key Rationale |
|-----------|--------|----------------|
| Sync | Source-Priority Merge | Curated data authority |
| Distance | Haversine (`geolocator`) | Standard, offline-capable |
| Database | SQLite (`sqflite`) | Efficient sorting and filtering |
| i18n | ARB Files (`intl`) | Industry standard, scalable |
