---
description: "Task list template for feature implementation"
---

# Tasks: Roadside Help — Find & Reach the Nearest Helper

**Input**: Design documents from `/specs/001-roadside-help/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/sync-api.md, quickstart.md

**Tests**: Implementation follows the project's "Test-First" constitution. Tests are required for core distance logic and sync mechanisms.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Mobile**: Paths follow the Clean Architecture structure defined in `plan.md` under `lib/`.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [x] T001 Create project structure (core, data, domain, presentation) per implementation plan in `lib/`
- [x] T002 Initialize Flutter project and add dependencies (`sqflite`, `geolocator`, `url_launcher`, `flutter_localizations`, `http`) in `pubspec.yaml`
- [x] T003 [P] Configure linting and formatting tools in `analysis_options.yaml`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 Setup SQLite database schema for `helpers`, `problem_types`, and `config` tables in `lib/data/repositories/local_db.dart`
- [x] T005 [P] Implement base `Helper` and `ProblemType` entities in `lib/domain/entities/`
- [x] T006 [P] Setup base API client for helper synchronization in `lib/data/providers/api_client.dart`
- [x] T007 Create distance calculation utility (Haversine) in `lib/core/utils/distance_calculator.dart`
- [x] T008 [P] Configure localization infrastructure and generate initial `.arb` files in `lib/core/i18n/`
- [x] T009 Implement global error handling and logging infrastructure in `lib/core/utils/logger.dart`

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Find the nearest help for a problem (Priority: P1) 🎯 MVP

**Goal**: Users can select a problem type and see the 3 nearest helpers sorted by distance with a call button.

**Independent Test**: With location available and helper data present, tap "puncture" and confirm the nearest puncture shops appear sorted by distance, each with a visible distance, a working call button, and a directions option.

### Tests for User Story 1

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T010 [P] [US1] Unit test for `FindNearestHelpers` use case in `test/domain/usecases/find_nearest_test.dart`
- [x] T011 [P] [US1] Integration test for helper list sorting and distance display in `test/integration/helper_list_test.dart`

### Implementation for User Story 1

- [x] T012 [P] [US1] Create `HelperRepository` for local caching and retrieval in `lib/data/repositories/helper_repository.dart`
- [x] T013 [US1] Implement `FindNearestHelpers` use case in `lib/domain/usecases/find_nearest_helpers.dart` (depends on T010)
- [x] T014 [P] [US1] Implement `ProblemSelectionScreen` UI in `lib/presentation/screens/problem_selection_screen.dart`
- [x] T015 [P] [US1] Implement `HelperListScreen` UI with distance sorting in `lib/presentation/screens/helper_list_screen.dart`
- [x] T016 [US1] Implement `HelperCard` widget with one-tap call and directions in `lib/presentation/widgets/helper_card.dart` (depends on T015)
- [x] T017 [US1] Integrate `url_launcher` for native call and maps actions in `lib/presentation/widgets/helper_card.dart`
- [x] T018 [US1] Implement logic to visually flag helpers beyond 15km as "far away" in `lib/presentation/widgets/helper_card.dart`

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 2 - Get help while offline (Priority: P2)

**Goal**: Users can still access cached helpers and their GPS location on a map without internet.

**Independent Test**: Disable the network, open the app, and confirm the previously cached helper list is shown, the user's GPS position appears on the map, and both call and SMS actions work for a listed helper.

### Tests for User Story 2

- [x] T019 [P] [US2] Integration test for offline data retrieval from SQLite in `test/integration/offline_data_test.dart`
- [x] T020 [P] [US2] Unit test for GPS coordinate updates while offline in `test/domain/usecases/location_test.dart`

### Implementation for User Story 2

- [x] T021 [P] [US2] Implement `SyncData` use case to pull data from `/v1/helpers/sync` in `lib/domain/usecases/sync_data.dart`
- [x] T022 [US2] Implement Source-Priority Merge logic in `lib/data/repositories/helper_repository.dart` (depends on T021)
- [x] T023 [P] [US2] Implement `MapScreen` with current GPS location marker in `lib/presentation/screens/map_screen.dart`
- [x] T024 [US2] Implement "Last Updated" timestamp indicator in `lib/presentation/screens/helper_list_screen.dart`
- [x] T025 [US2] Add SMS contact capability via `url_launcher` in `lib/presentation/widgets/helper_card.dart`
- [x] T026 [US2] Implement graceful degradation (no-network warnings) in `lib/presentation/state/app_state.dart`

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently

---

## Phase 5: User Story 3 - Switch app language anytime (Priority: P3)

**Goal**: Users can change the app's display language, and the interface updates immediately.

**Independent Test**: Change the language from the app's settings/controls and confirm that interface text updates to the selected language without restarting or losing the current screen.

### Tests for User Story 3

- [x] T027 [P] [US3] Widget test for dynamic language switching in `test/presentation/i18n_test.dart`

### Implementation for User Story 3

- [x] T028 [P] [US3] Implement `LanguagePreference` persistence in `lib/data/repositories/local_db.dart`
- [x] T029 [US3] Implement `LanguageSwitcher` widget in `lib/presentation/widgets/language_switcher.dart`
- [x] T030 [US3] Integrate `LanguageSwitcher` with Flutter's `Locale` state management in `lib/presentation/state/app_state.dart`
- [x] T031 [US3] Populate all interface strings in `.arb` files for English, Hindi, and other major Indian languages in `lib/core/i18n/`

**Checkpoint**: All user stories should now be independently functional

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [x] T032 [P] Implement manual location entry prompt for GPS-unavailable scenarios in `lib/presentation/screens/location_prompt_screen.dart`
- [x] T033 [P] Add "Hours Unknown" labels for helpers with missing opening hours in `lib/presentation/widgets/helper_card.dart`
- [x] T034 [P] Perform final UI/UX polish for accessibility and consistent 60fps performance
- [x] T035 [P] Run `quickstart.md` validation and finalize documentation
- [x] T036 Security review: Verify HTTPS enforcement and API key handling

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3)
- **Polish (Final Phase)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - Depends on US1 for the list display, but the sync logic is independent.
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - No dependencies on other stories.

### Within Each User Story

- Tests MUST be written and FAIL before implementation
- Models before services
- Services before endpoints
- Core implementation before integration
- Story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] can run in parallel (within Phase 2)
- Once Foundational phase completes, all user stories can start in parallel
- All tests for a user story marked [P] can run in parallel
- Models/UI screens within a story marked [P] can run in parallel

---

## Parallel Example: User Story 1

```bash
# Launch all tests for User Story 1 together:
Task: "Unit test for FindNearestHelpers use case in test/domain/usecases/find_nearest_test.dart"
Task: "Integration test for helper list sorting and distance display in test/integration/helper_list_test.dart"

# Launch UI screens for User Story 1 together:
Task: "Implement ProblemSelectionScreen UI in lib/presentation/screens/problem_selection_screen.dart"
Task: "Implement HelperListScreen UI with distance sorting in lib/presentation/screens/helper_list_screen.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Test User Story 1 independently
5. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational $\rightarrow$ Foundation ready
2. Add User Story 1 $\rightarrow$ Test independently $\rightarrow$ Deploy/Demo (MVP!)
3. Add User Story 2 $\rightarrow$ Test independently $\rightarrow$ Deploy/Demo
4. Add User Story 3 $\rightarrow$ Test independently $\rightarrow$ Deploy/Demo
5. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1
   - Developer B: User Story 2
   - Developer C: User Story 3
3. Stories complete and integrate independently
