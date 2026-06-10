# Feature Specification: Roadside Help — Two-Sided Marketplace

**Feature Branch**: `002-roadside-marketplace`

**Created**: 2026-06-10

**Status**: Draft

**Input**: User description: "Evolve the existing offline-first roadside help app into a full working prototype: accounts and login/signup (phone OTP, email+password, Google, guest), two roles (seeker and helper/provider), a service-request flow with live tracking, search and service categories, profile/history/ratings, working maps, multi-language, backed by a cleanly designed PostgreSQL database via a custom backend. Uber/Rapido-style but cleaner and more interactive. Payments out of scope."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Sign in and find the nearest help (Priority: P1)

A new user opens the app and is greeted by a clean welcome screen. They sign up or log in
(by phone with a verification code, by email and password, with Google, or continue as a
guest to browse). Once in, they land on a home screen with a search bar and a grid of
service categories (puncture, out of fuel, mechanic/breakdown, towing, battery jumpstart).
They pick a category and immediately see the nearest helpers sorted by distance, each with a
distance, rating, open/closed status, and a one-tap call button.

**Why this priority**: This is the core rescue value plus the account gateway that everything
else builds on. It is independently shippable as the MVP: a user can authenticate and reach
a helper.

**Independent Test**: Launch the app, complete any one of the sign-in methods (or guest),
select a category, and confirm nearest helpers appear sorted by distance with a working call
action.

**Acceptance Scenarios**:

1. **Given** a first-time user on the welcome screen, **When** they choose a sign-in method
   and complete it successfully, **Then** they reach the home screen and their session
   persists on the next app launch.
2. **Given** an authenticated or guest user on the home screen, **When** they select a service
   category, **Then** the nearest helpers for that category are shown sorted nearest-first,
   each with distance, rating, open/closed status, and a one-tap call button.
3. **Given** a guest user viewing helpers, **When** they attempt to request a helper, **Then**
   they are prompted to authenticate before the request proceeds.
4. **Given** any helper in the list, **When** the user taps the directions action, **Then**
   navigation to that helper is presented via the device's maps app.

---

### User Story 2 - Request a helper and track them live (Priority: P1)

An authenticated seeker selects a helper (or broadcasts the request), submits a service
request describing the problem and their location, and watches the request progress through
clear states — requested → accepted → on the way → arrived → completed — with the assigned
helper's live position shown on the map. Either side can cancel before completion.

**Why this priority**: This is the on-demand marketplace experience that distinguishes the
product from a static directory; it is the second half of the core value and tightly coupled
to Story 1.

**Independent Test**: As a seeker, submit a request to a helper; as that helper, accept and
advance the status; confirm the seeker sees each status change and the helper's moving
position on the map, and that completion unlocks rating.

**Acceptance Scenarios**:

1. **Given** an authenticated seeker viewing a helper, **When** they submit a service request,
   **Then** the request is created in "requested" state and the assigned/targeted helper is
   notified of it.
2. **Given** an active request, **When** the helper accepts and updates status, **Then** the
   seeker sees the status change (accepted → on the way → arrived → completed) without manual
   refresh.
3. **Given** a request in "on the way" or "arrived", **When** the helper's location updates,
   **Then** the seeker sees the helper's current position move on the map.
4. **Given** an active request not yet completed, **When** either party cancels, **Then** the
   request moves to "cancelled" and both sides see the final state.
5. **Given** a completed request, **When** the seeker opens it, **Then** they are offered the
   option to rate and review the helper.

---

### User Story 3 - Act as a helper/provider (Priority: P2)

A user who is registered as a helper switches into provider mode, sees incoming service
requests near them with the problem type and seeker distance, and can accept or decline. After
accepting, they advance the request status and share their live location until completion.

**Why this priority**: A two-sided marketplace needs the supply side to be demonstrable; it
makes the live-tracking flow real, but the seeker experience (Stories 1–2) can be demoed with
seeded helpers first.

**Independent Test**: As a helper in provider mode, receive a seeker's request, accept it,
advance through statuses, and confirm the seeker side reflects each change.

**Acceptance Scenarios**:

1. **Given** a user registered as a helper, **When** they enable provider mode, **Then** they
   see incoming/open requests relevant to their helper type, each with problem type and
   distance.
2. **Given** an incoming request, **When** the helper accepts, **Then** it becomes assigned to
   them and is removed from other helpers' open lists; when they decline, it remains available
   to others.
3. **Given** an assigned request, **When** the helper updates status or their location moves,
   **Then** the seeker sees those updates.
4. **Given** a helper profile, **When** seekers have submitted ratings, **Then** the helper's
   average rating and review count are visible to seekers.

---

### User Story 4 - Profile, history, and ratings (Priority: P3)

Any user can view and edit their profile (name, phone, vehicle info, language), see a history
of their past requests in both roles, and — after a completed service — leave a 1–5 star rating
with an optional comment that contributes to the helper's average rating.

**Why this priority**: Builds trust and retention and rounds out the prototype, but the rescue
loop works without it.

**Independent Test**: Edit profile fields and confirm they persist; open request history and
confirm past requests appear with their final status; submit a rating on a completed request
and confirm it updates the helper's average.

**Acceptance Scenarios**:

1. **Given** a signed-in user, **When** they edit profile fields and save, **Then** the changes
   persist across sessions.
2. **Given** a user with past requests, **When** they open history, **Then** their requests are
   listed with category, helper, date, and final status.
3. **Given** a completed request without an existing review, **When** the seeker submits a
   rating and comment, **Then** it is stored and the helper's average rating and count update.
4. **Given** a request the user already reviewed, **When** they open it, **Then** they cannot
   submit a second review for the same request.

---

### User Story 5 - Switch language anytime (Priority: P3)

A user can change the display language at any time from settings or the profile, and the whole
interface — including all new account, request, and profile screens — updates, persisting the
choice across sessions.

**Why this priority**: Accessibility and reach across India; carried forward from the existing
app and extended to new screens.

**Independent Test**: Switch language and confirm all visible text on every major screen updates
and the choice survives an app restart.

**Acceptance Scenarios**:

1. **Given** any screen, **When** the user switches language, **Then** visible interface text
   updates to the selected language within a couple of seconds.
2. **Given** a chosen language, **When** the app is reopened, **Then** that language is still in
   effect.

---

### Edge Cases

- **Guest hits a gated action**: Requesting a helper, viewing history, or editing a profile as a
  guest prompts authentication, then resumes the action.
- **OTP / Google unavailable in prototype**: When external SMS or OAuth credentials are absent,
  the flows use a clearly-labelled demo/mock path (e.g., a fixed dev code) so the experience is
  still fully demonstrable; this MUST be obvious and never silently fail.
- **Duplicate identity**: Signing up with a phone or email already linked to an account routes to
  login rather than creating a duplicate.
- **No helpers / only far helpers**: Always show the nearest available helpers with actual
  distance; flag any beyond ~15 km as "far away" rather than hiding them.
- **GPS unavailable or denied**: Prompt to enable location or let the user set it manually so
  results and requests still work.
- **Fully offline**: The find-helper discovery degrades to the last-synced cached list plus
  call/SMS; online-only features (submitting/tracking a live request) clearly indicate they need
  connectivity rather than failing silently.
- **Helper goes offline mid-request**: The seeker sees the last known status/position with a
  "last updated" indicator and may cancel.
- **Concurrent acceptance**: If two helpers try to accept the same broadcast request, only the
  first succeeds; the others are told it is no longer available.
- **Self-review / invalid rating**: A user cannot review their own request as the helper, and
  ratings outside 1–5 are rejected.
- **Stale cache**: The find-helper list shows when its data was last updated.

## Requirements *(mandatory)*

### Functional Requirements

#### Accounts & Authentication

- **FR-001**: System MUST let a user create an account and sign in via each of: phone number
  with a verification code, email with a password, and a Google account; and MUST let a user
  continue as a guest with limited access.
- **FR-002**: System MUST persist a signed-in session across app launches and MUST let the user
  log out, ending the session.
- **FR-003**: System MUST store passwords only in a securely hashed form and MUST transmit all
  credentials and tokens over an encrypted channel.
- **FR-004**: System MUST prevent duplicate accounts for the same verified phone or email,
  routing an existing identity to login.
- **FR-005**: Guests MUST be able to browse categories and view helpers, but System MUST require
  authentication before submitting a service request, leaving a review, or editing a profile.

#### Roles

- **FR-006**: System MUST support two roles, seeker and helper/provider, and MUST allow an
  account that is a registered helper to switch into provider mode and back.
- **FR-007**: System MUST associate a helper/provider account with a helper profile (type,
  location, contact, opening hours).

#### Discovery, Search & Categories

- **FR-008**: System MUST present service categories (at minimum: puncture/flat tyre, out of
  fuel, mechanic/breakdown, towing, battery jumpstart) and MUST map each to the helper type(s)
  that serve it.
- **FR-009**: System MUST provide a search that filters helpers by name, type, and location.
- **FR-010**: System MUST display helpers matching the selected category/search, sorted by
  straight-line distance from the user, nearest first, each showing distance, open/closed (or
  "hours unknown") status, average rating, and a one-tap call action.
- **FR-011**: System MUST always show the nearest helpers with their actual distance with no
  fixed cut-off range, and MUST visually flag any helper beyond approximately 15 km as "far
  away" while still showing it.
- **FR-012**: System MUST provide a directions/navigation action that hands off to the device's
  maps app, and call and SMS actions that use the device's native dialer and messaging.

#### Service Requests & Live Tracking

- **FR-013**: An authenticated seeker MUST be able to submit a service request specifying the
  category/problem, their location, and a target helper (or a broadcast to nearby helpers of the
  matching type).
- **FR-014**: System MUST model a request lifecycle with the states requested, accepted,
  on-the-way, arrived, completed, and cancelled, and MUST record timestamps for state changes.
- **FR-015**: A targeted/assigned helper MUST be able to accept or decline a request; on accept,
  the request becomes exclusively assigned to that helper and is no longer offerable to others.
- **FR-016**: The assigned helper MUST be able to advance the request status and the seeker MUST
  see status changes without manually refreshing.
- **FR-017**: During an active request, System MUST accept periodic location updates from the
  assigned helper and MUST show the helper's current position to the seeker on the map, with a
  "last updated" indication.
- **FR-018**: Either party MUST be able to cancel a request before completion, after which the
  request is in the cancelled state for both.
- **FR-019**: System MUST prevent two helpers from both being assigned the same request
  (first-accept wins).

#### Profile, History & Ratings

- **FR-020**: System MUST let an authenticated user view and edit a profile including name,
  phone, vehicle information, and preferred language, persisting changes.
- **FR-021**: System MUST show each user a history of their past requests (in both seeker and
  helper roles) with category, counterpart, date, and final status.
- **FR-022**: After a completed request, the seeker MUST be able to submit exactly one rating
  (1–5 stars) with an optional comment for the assigned helper.
- **FR-023**: System MUST compute and display each helper's average rating and review count, and
  MUST reject self-reviews and out-of-range ratings.

#### Maps & Location

- **FR-024**: System MUST display the user's current location on a map and MUST render helper
  markers and, during an active request, the assigned helper's live position.
- **FR-025**: When GPS is unavailable or denied, System MUST prompt the user to enable location
  or let them set their location manually so discovery and requests still function.

#### Offline & Data Freshness (carried from prior scope)

- **FR-026**: System MUST cache the most recent helper list for offline discovery and, when
  offline, MUST show the cached list with distances from the current GPS position plus call/SMS,
  without blank or error-only screens.
- **FR-027**: System MUST indicate when cached helper data was last updated, and MUST clearly
  indicate when an online-only action is unavailable due to lack of connectivity.
- **FR-028**: System MUST source helper data primarily from the curated team-controlled dataset
  and MAY supplement it from a third-party places source where coverage is sparse.

#### Localization

- **FR-029**: System MUST let the user switch the display language at any time across all
  screens, MUST persist the choice across sessions, and the localization approach MUST scale to
  add languages (English, Hindi, and other major Indian languages) without changing feature
  logic.

### Key Entities *(include if data involved)*

- **User**: An account holder. Attributes: display name, optional email, optional phone,
  preferred language, role capabilities (seeker always; helper if registered), and links to one
  or more authentication identities. A guest is a session without a persisted account.
- **Auth Identity**: A way a user proves who they are — phone, email+password, or Google —
  linked to exactly one user; a user may have several.
- **Helper Profile**: The supply-side entity for a helper/provider. Attributes: name, helper
  type (puncture shop, petrol pump, mechanic, towing, battery), location coordinates, phone,
  SMS capability, opening hours (may be unknown), data source (curated vs third-party),
  verification flag, and aggregate rating (average + count). Linked to a user when provider-run.
- **Service Category**: A user-facing category shown on the home grid/search, mapping to one or
  more helper types.
- **Problem Type**: The roadside issue a seeker selects; maps to a service category / helper
  types.
- **Service Request**: A seeker's request for help. Attributes: seeker, category/problem,
  pickup location, optional target helper, assigned helper, status, and per-state timestamps.
- **Helper Location Update**: A timestamped position reported by an assigned helper during an
  active request, used for live tracking.
- **Review**: A seeker's 1–5 star rating with optional comment tied to one completed request and
  one helper; contributes to the helper's aggregate rating.
- **Language Preference**: The user's selected display language, persisted across sessions.
- **Cached Helper List**: The most recent helpers retrieved during the last successful sync, with
  a "last updated" timestamp, used for offline discovery.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A first-time user can go from app launch to a completed sign-in (any method,
  including guest) in under 60 seconds.
- **SC-002**: From the home screen, a user can go from selecting a category to initiating a call
  to a helper in 3 taps or fewer.
- **SC-003**: After a helper updates request status or position, the seeker sees the change
  within 10 seconds without manually refreshing.
- **SC-004**: For a selected category with known location, helpers are correctly ordered nearest
  first in 100% of cases, with any beyond ~15 km flagged "far away".
- **SC-005**: When offline with a prior sync, 100% of core discovery actions (view cached list,
  see own location on map, call, SMS) remain available.
- **SC-006**: A returning user's session and chosen language both persist across app restarts in
  100% of cases.
- **SC-007**: A completed request can be rated exactly once, and the helper's displayed average
  reflects the new rating immediately after submission.
- **SC-008**: 95% of first-time users can sign in, find, and contact a helper without external
  guidance.

## Assumptions

- The app remains a Flutter application targeting mobile and web; maps use an OpenStreetMap-based
  renderer requiring no paid map key.
- A custom backend service with a relational (PostgreSQL) database provides accounts, helper
  discovery, request lifecycle, live location updates, search, profile, and reviews over an
  HTTPS REST API; the Flutter app keeps a local cache of helpers for offline discovery.
- This is a prototype: where external SMS (OTP) or Google OAuth credentials are unavailable, the
  corresponding flows use a clearly-labelled demo/mock path while keeping the full UI and
  navigation intact.
- "Nearest" is straight-line distance from the user's current location; turn-by-turn directions
  are delegated to an external maps app.
- Live tracking is achieved by the assigned helper periodically reporting location while a
  request is active; sub-second real-time precision is not required (updates within ~10s).
- Payments and in-app transactions are out of scope.
- Calling and messaging use the device's native phone and SMS capabilities.
- Supported languages include English, Hindi, and other major Indian languages; exact translated
  strings are supplied as localization content while the UI accommodates the full set.

## Out of Scope

- Payments, fares, or any in-app transactions.
- Helper onboarding/verification workflows beyond a basic registered-helper flag (full KYC is
  out of scope for the prototype).
- Background/real-time push notifications infrastructure beyond in-app status polling/refresh
  (a notification may be simulated in-app).
- Production-grade fraud, abuse, and rate-limiting systems.
