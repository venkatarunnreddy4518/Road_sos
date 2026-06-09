# Feature Specification: Roadside Help — Find & Reach the Nearest Helper

**Feature Branch**: `001-roadside-help`

**Created**: 2026-06-09

**Status**: Draft

**Input**: User description: "Request help and route to the nearest helper. A user facing a roadside problem (puncture/flat tyre, out of fuel, or breakdown) opens the app, taps the type of problem, and immediately sees the nearest available helpers (puncture shop, petrol pump, mechanic) sorted by distance, each with a one-tap call button and directions. User stories: (1) a stranded user taps 'puncture' and sees the 3 nearest puncture shops with distance and a call button; (2) a user with no internet still sees helpers cached from their last sync, their GPS location on a map, and can call or SMS them; (3) a user can switch the app language at any time. Acceptance criteria and edge cases: no helpers within range shows the nearest available plus a clear message; GPS unavailable prompts the user to enable it or set location manually; fully offline degrades gracefully to the cached list plus call/SMS. Out of scope for this feature: helper registration, payments, and account management."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Find the nearest help for a problem (Priority: P1)

A user stranded by the roadside opens the app, taps the type of problem they have (puncture,
out of fuel, or breakdown), and immediately sees the nearest available helpers of the matching
type, sorted by distance. Each helper shows its distance and a one-tap button to call it, plus
the option to get directions.

**Why this priority**: This is the core value of the product — connecting a stranded person to
help fast. Without it there is no product. It is independently shippable as a minimum viable
product.

**Independent Test**: With location available and helper data present, tap "puncture" and confirm
the nearest puncture shops appear sorted by distance, each with a visible distance, a working
call button, and a directions option.

**Acceptance Scenarios**:

1. **Given** the user's location is known and puncture shops exist nearby, **When** the user taps
   "puncture", **Then** the 3 nearest puncture shops are shown, sorted nearest-first, each with
   its distance and a one-tap call button.
2. **Given** a list of helpers is shown, **When** the user taps a helper's call button, **Then**
   the device initiates a phone call to that helper.
3. **Given** a list of helpers is shown, **When** the user taps "directions" for a helper, **Then**
   navigation/directions to that helper's location are presented.
4. **Given** no helpers of the selected type exist within the normal range, **When** the user taps
   the problem type, **Then** the nearest available helper beyond the range is shown together with
   a clear message that nothing was found within the usual distance.

---

### User Story 2 - Get help while offline (Priority: P2)

A user with no internet connection still sees the helpers cached from their last successful sync,
sees their own GPS location on a map, and can reach helpers by phone call or SMS.

**Why this priority**: Roadside emergencies frequently happen exactly where connectivity is poor.
Offline resilience is what makes the app trustworthy in real conditions, but it builds on the
core list from Story 1.

**Independent Test**: Disable the network, open the app, and confirm the previously cached helper
list is shown, the user's GPS position appears on the map, and both call and SMS actions work for
a listed helper.

**Acceptance Scenarios**:

1. **Given** the device has no internet but a previous sync exists, **When** the user opens the app
   and selects a problem type, **Then** the cached list of helpers is shown along with their
   distances from the user's current GPS position.
2. **Given** the app is offline, **When** the user views the map, **Then** the user's current GPS
   location is displayed.
3. **Given** the app is offline and a helper is listed, **When** the user taps call or SMS, **Then**
   the device initiates the call or opens a pre-addressed SMS to that helper.
4. **Given** the app is fully offline with no usable network, **When** the user uses the app,
   **Then** it degrades gracefully to the cached list plus call/SMS without errors or blank screens.

---

### User Story 3 - Switch app language anytime (Priority: P3)

A user can change the app's display language at any time, and the interface updates accordingly.

**Why this priority**: Roadside help must be usable by people across languages, including in
stressful moments. It increases reach and accessibility but is not required for the core rescue
flow to function.

**Independent Test**: Change the language from the app's settings/controls and confirm that
interface text updates to the selected language without restarting or losing the current screen.

**Acceptance Scenarios**:

1. **Given** the app is open in any screen, **When** the user switches the language, **Then** the
   visible interface text changes to the selected language.
2. **Given** the user has selected a language, **When** the user reopens the app later, **Then**
   the previously selected language is still in effect.

---

### Edge Cases

- **No helpers within range**: Show the nearest available helper beyond the normal range, with a
  clear message explaining none were found within the usual distance.
- **GPS unavailable or denied**: Prompt the user to enable location, or let them set their location
  manually so results can still be shown.
- **Fully offline**: Degrade gracefully to the last-synced cached list plus call/SMS actions; never
  show a blank or error-only screen.
- **No previous sync while offline**: Inform the user that no cached helpers are available and guide
  them to connect once to download data.
- **Helper has no phone number / no SMS capability**: Disable or hide the unavailable action and
  indicate why, rather than failing silently.
- **Stale cached data**: Indicate when the cached list was last updated so the user understands it
  may be out of date.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST let the user select a roadside problem type from at least: puncture/flat
  tyre, out of fuel, and breakdown.
- **FR-002**: System MUST determine the user's current location to find nearby helpers.
- **FR-003**: System MUST display helpers matching the selected problem type (puncture shop, petrol
  pump, mechanic), sorted by distance from the user, nearest first.
- **FR-004**: System MUST show, for each helper, the distance from the user and a one-tap action to
  call the helper.
- **FR-005**: System MUST provide a directions/navigation action to a selected helper's location.
- **FR-006**: System MUST show at least the 3 nearest helpers for the selected problem type when
  that many are available.
- **FR-007**: When no helpers exist within the normal range, System MUST show the nearest available
  helper beyond the range together with a clear message.
- **FR-008**: System MUST cache the most recent helper list from the last successful sync for
  offline use.
- **FR-009**: When offline, System MUST display the cached helper list and compute distances using
  the user's current GPS position.
- **FR-010**: System MUST display the user's current GPS location on a map, including while offline.
- **FR-011**: System MUST allow the user to contact a helper by phone call and by SMS.
- **FR-012**: When GPS is unavailable or permission is denied, System MUST prompt the user to enable
  location or allow them to set their location manually.
- **FR-013**: System MUST degrade gracefully when fully offline, presenting the cached list plus
  call/SMS without errors or blank screens.
- **FR-014**: System MUST allow the user to switch the app's display language at any time, with the
  interface updating to the selected language.
- **FR-015**: System MUST persist the user's selected language across sessions.
- **FR-016**: System MUST indicate when cached helper data was last updated so users can judge its
  freshness.

### Out of Scope

- Helper registration / onboarding of helpers.
- Payments or any in-app transactions.
- User account management (sign-up, login, profiles).

### Key Entities *(include if feature involves data)*

- **Helper**: A place or person that can assist, of a given type (puncture shop, petrol pump,
  mechanic). Key attributes: name, helper type, location (coordinates), phone number, optional SMS
  capability. Relationship: matched to a problem type.
- **Problem Type**: The category of roadside issue the user selects (puncture, out of fuel,
  breakdown), each mapping to one or more helper types.
- **User Location**: The user's current position (from GPS or set manually) used to sort helpers by
  distance and to render the map.
- **Cached Helper List**: The most recent set of helpers retrieved during the last successful sync,
  with a "last updated" timestamp, used for offline operation.
- **Language Preference**: The user's selected display language, persisted across sessions.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: From opening the app, a user can see the nearest relevant helpers for their problem in
  under 10 seconds when location and data are available.
- **SC-002**: A user can go from selecting a problem type to initiating a call to a helper in 3 taps
  or fewer.
- **SC-003**: When offline with a prior sync, 100% of core actions (view cached list, see own
  location on map, call, SMS) remain available.
- **SC-004**: For the selected problem type, the displayed helpers are correctly ordered by distance
  nearest-first in 100% of cases where location is known.
- **SC-005**: 95% of first-time users can find and contact a helper without external guidance.
- **SC-006**: Switching language updates all visible interface text within 2 seconds and persists on
  the next app launch.

## Assumptions

- Target users are on a mobile device with a phone dialer and SMS capability.
- Helper data (locations, phone numbers, types) is sourced from an existing dataset or service that
  the app syncs when online; sourcing and maintaining that data is assumed available and not defined
  here.
- "Nearest" is measured by distance from the user's current location; a reasonable default search
  range is used and the nearest-beyond-range fallback applies when nothing is within it.
- At least two languages are supported initially; the specific language set is a configuration
  detail outside this spec.
- Calling and messaging use the device's native phone and SMS capabilities.
- An initial online sync is required at least once before offline use is possible.
