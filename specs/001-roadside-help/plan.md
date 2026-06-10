# Implementation Plan: Roadside Help — Find & Reach the Nearest Helper

**Branch**: `001-roadside-help` | **Date**: 2026-06-09 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-roadside-help/spec.md`

## Summary

Implement a roadside help feature allowing users to find the nearest helpers (puncture shops, petrol pumps, mechanics) based on problem type. The app will be offline-first, using a local SQLite cache for helper data and computing straight-line distances from the user's GPS coordinates. It will support multiple major Indian languages through a scalable localization system. Data will be synced from a hybrid source: a curated team-controlled backend supplemented by third-party places data.

## Technical Context

**Language/Version**: Flutter (Dart) 3.x

**Primary Dependencies**: 
- `sqflite`: Local persistent storage for helper cache.
- `geolocator`: Accessing device GPS and computing distances.
- `url_launcher`: For native phone calls, SMS, and opening maps.
- `flutter_localizations`: Standard i18n support.
- `http`: For helper data synchronization.

**Storage**: 
- Local: SQLite database to store `Helpers`, `ProblemTypes`, and `LanguagePreference`.
- Remote: REST API providing JSON data for helper synchronization.

**Testing**: 
- Flutter Unit Tests (for distance calculations, data parsing).
- Widget Tests (for UI language switching and helper lists).
- Integration Tests (for the full flow from location access to calling a helper).

**Target Platform**: iOS 15+, Android 10+

**Project Type**: mobile-app

**Performance Goals**: 
- Find nearest helpers in <10 seconds.
- Language switch UI update in <2 seconds.
- Consistent 60 fps UI.

**Constraints**: 
- Offline-capable: Must function with cached data and GPS when internet is unavailable.
- Hybrid Data: Merge curated team-controlled data with 3rd party sources.
- Multi-language: Support English, Hindi, and other major Indian languages.

**Scale/Scope**: Target users across India, requiring scalable localization.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. Test-First**: ✅ Implementation tasks in `tasks.md` will prioritize failing tests for distance logic and sync.
- **II. Security by Default**: ✅ All API traffic via HTTPS; input validation for manual location entry.
- **III. Simplicity & YAGNI**: ✅ SQLite chosen for structured query needs; simple periodic sync instead of complex real-time sockets.
- **IV. Clear Contracts**: ✅ Explicit API contracts for helper sync will be defined in `contracts/`.
- **V. Observability**: ✅ Structured logging for GPS permission denials and sync errors.

**Verdict**: PASS

## Project Structure

### Documentation (this feature)

```text
specs/001-roadside-help/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── constants/       # App constants & API endpoints
│   ├── i18n/            # Localization files and logic
│   └── utils/           # Distance calculators (Haversine)
├── data/
│   ├── models/          # Data entities (Helper, ProblemType)
│   ├── providers/       # API clients for sync
│   └── repositories/    # Hybrid data coordination (Remote + Local)
├── domain/
│   ├── entities/        # Business objects
│   └── usecases/        # "FindNearestHelpers", "SyncData"
└── presentation/
    ├── screens/         # Problem Selection, Helper List, Map View
    ├── widgets/         # HelperCard, LanguageSwitcher
    └── state/           # BLoC/Provider for state management
```

**Structure Decision**: Selected a modified Clean Architecture (Data -> Domain -> Presentation) to ensure strict separation of concerns, making the offline-first logic (Repository layer) easy to test and maintain.

## Complexity Tracking

No violations of the constitution; no justifications required.
