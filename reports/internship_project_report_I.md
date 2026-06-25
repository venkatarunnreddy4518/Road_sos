# INTERNSHIP PROJECT REPORT I

## Cover Page

**Student Name:** [To be filled by student]  
**Roll Number:** [To be filled by student]  
**Branch & Year:** [To be filled by student]  
**Internship Company Name:** [To be filled by student]  
**Project Title:** Roadside SOS - Two-Sided Roadside Assistance Marketplace  
**Company Mentor Name:** [To be filled by student]  
**Faculty Mentor Name:** Joydeep Roy  
**Internship Duration:** [To be filled by student]  
**Date of Submission:** 19 June 2026

---

## 1. Introduction

### Brief Overview of the Company

The internship work was carried out in a software/product engineering environment focused on building practical digital solutions for real-world problems. The project belongs to the mobility and emergency-assistance domain, where technology is used to connect users in distress with nearby service providers through a mobile/web application and a backend API.

The exact company profile, registered company name, and business description should be filled using official company information before final submission.

### Department/Team Assigned

The work is aligned with the Full Stack Product Engineering / Application Development team. The project required coordination across mobile frontend development, backend API development, database design, testing, documentation, deployment preparation, and user-experience improvement.

### Project Domain

The project domain includes:

- Full Stack Web and Mobile Development
- Backend API Development
- Location-Based Services
- Database Design
- Cloud-Ready Application Development
- Testing and Quality Assurance
- Security and Authentication
- Multilingual User Interface Development

### Purpose of the Internship

The purpose of the internship was to gain practical experience in designing and developing a complete full-stack application. The project aimed to convert an offline-first roadside help application into a working two-sided marketplace prototype where stranded users can find nearby helpers, request assistance, track service progress, and rate completed jobs.

The internship also provided exposure to modern engineering practices such as REST API design, JWT-based authentication, PostgreSQL schema design, Flutter UI development, offline caching, geolocation, CI quality checks, and test-first implementation.

---

## 2. Project Overview

### Project Title

**Roadside SOS - Two-Sided Roadside Assistance Marketplace**

### Background of the Project

Vehicle breakdowns, flat tyres, empty fuel tanks, battery failures, and towing needs are common roadside problems. In many cases, stranded users do not know which nearby service provider is available, trustworthy, or closest to their current location. Traditional solutions depend on manual phone calls, search engines, static listings, or local knowledge, which may be slow and unreliable during emergencies.

The project began as an offline-first roadside help application and was extended into a two-sided marketplace prototype. The new version supports both seekers and providers. Seekers can search for nearby assistance and submit requests, while providers can register, view incoming requests, accept jobs, update job status, and share live location.

### Business Problem Being Addressed

The business problem is the lack of a fast, organized, and location-aware platform for connecting stranded vehicle users with nearby roadside service providers. Users need immediate help, but service discovery is often fragmented. Providers also need a simple way to receive local requests and manage jobs.

The application addresses this gap by creating a marketplace-like experience similar to ride-hailing apps, but focused on roadside assistance instead of transport.

### Objectives of the Project

The main objectives are:

- Build a cross-platform Flutter application for Android, iOS, and web.
- Provide user authentication through email/password, phone OTP, Google sign-in, Apple sign-in, and guest mode.
- Support two roles: seeker and helper/provider.
- Display service categories such as puncture, fuel, breakdown, towing, and battery assistance.
- Show nearby helpers sorted by Haversine distance.
- Provide call, SMS, and directions actions through native device capabilities.
- Allow authenticated users to create roadside assistance requests.
- Support request lifecycle states: requested, accepted, on the way, arrived, completed, and cancelled.
- Provide provider mode with open request listing, accept/decline actions, and live location posting.
- Store user, helper, request, location, and review data in a normalized backend database.
- Preserve offline helper discovery through a local SQLite cache.
- Provide multilingual support for English, Hindi, Telugu, and Tamil.
- Add testing, documentation, deployment configuration, and CI quality checks.

---

## 3. Literature Survey / Technology Study

### Technologies Studied Before Starting the Project

| Area | Technology / Concept Studied | Purpose in Project |
| --- | --- | --- |
| Mobile app development | Flutter, Dart | Cross-platform application development |
| Backend development | FastAPI, Python 3.11+ | REST API development and OpenAPI documentation |
| Database | PostgreSQL, SQLAlchemy ORM, Alembic | Persistent relational data model and migrations |
| Local storage | SQLite through sqflite | Offline helper cache for discovery |
| Authentication | JWT, bcrypt, refresh tokens, OAuth concepts | Secure login and protected routes |
| Maps and location | OpenStreetMap, flutter_map, geolocator, Haversine formula | Nearby helper discovery and map-based tracking |
| State management | Provider | Managing UI state such as auth, role, theme, locale, and AI settings |
| Testing | pytest, flutter_test, contract/integration tests | Functional correctness and regression prevention |
| Security | Environment variables, secret management, CORS, Bandit, Gitleaks | Safer application configuration |
| Deployment | Docker, Vercel, Render, Neon PostgreSQL | Cloud-ready prototype deployment |

### Existing Tools, Frameworks, or Systems Reviewed

The project design was influenced by real-time marketplace applications such as Uber and Rapido, but adapted for emergency roadside help. The following technical systems and tools were reviewed:

- Flutter for mobile and web UI development.
- FastAPI for structured backend APIs and automatic API documentation.
- PostgreSQL for reliable relational storage.
- SQLAlchemy and Alembic for ORM modeling and schema migration.
- OpenStreetMap-based maps as a no-key alternative to paid map SDKs.
- JWT bearer authentication for stateless API access.
- Secure local token storage through `flutter_secure_storage`.
- CI-style quality tools such as Ruff, Mypy, Bandit, pytest, Flutter Analyze, and Flutter Test.

### Relevant Concepts Learned

The project required learning and applying the following concepts:

- Clean Architecture separation between presentation, domain, data, and infrastructure layers.
- REST API contract design and endpoint versioning.
- Role-based access control for seekers and providers.
- Atomic update logic for first-accept-wins request assignment.
- State machine validation for service request status transitions.
- Secure password hashing and refresh-token rotation.
- Offline-first mobile design through cache synchronization.
- Geospatial distance calculation using Haversine formula.
- Live tracking using periodic HTTP polling instead of WebSockets.
- Localization strategy using string maps and persisted language preferences.
- Backend testing through unit, contract, and integration tests.

### Summary of Findings

The study showed that a prototype-level marketplace can be built effectively using a Flutter frontend and FastAPI backend. FastAPI provides a clean REST layer, PostgreSQL supports normalized marketplace data, and Flutter can deliver a responsive cross-platform UI. For the current scale, Haversine distance with indexed latitude/longitude is simpler than adding PostGIS. Polling is sufficient for live tracking when the target freshness is within about 10 seconds. Mock fallbacks for OTP and social login are useful for demonstration, but real production deployment requires actual SMS and OAuth credentials.

---

## 4. Problem Statement

### Problem the Project Aims to Solve

The project aims to solve the problem of delayed and unreliable roadside assistance. When a vehicle user is stranded, it is difficult to quickly identify nearby helpers, compare service providers, contact them, and track the request progress. Service providers also lack a structured digital channel to receive and manage emergency requests from nearby users.

### Why the Problem Is Important

Roadside emergencies are time-sensitive. A stranded user may be in an unsafe location, under stress, or unable to move the vehicle. Delays in finding help can increase risk, cause inconvenience, and reduce user trust. A structured application can reduce uncertainty by showing nearby helpers, providing one-tap contact options, and allowing real-time request tracking.

### Expected Benefits of the Solution

The expected benefits are:

- Faster discovery of nearby roadside helpers.
- Improved safety through location-aware assistance and direct communication.
- Better trust through ratings, helper profiles, and request history.
- Clear request lifecycle visibility for both seeker and provider.
- Improved provider productivity through a dedicated provider mode.
- Continued basic discovery capability even when the internet connection is unavailable.
- Scalable foundation for future additions such as payments, notifications, verified onboarding, and production-level service management.

---

## 5. Work Completed So Far

### Requirements Gathering

The requirements were studied from the project specification and implementation plan in `specs/002-roadside-marketplace/`. The main functional requirements included authentication, helper discovery, search, request lifecycle, live location, provider mode, profile, history, ratings, maps, offline cache, and multilingual UI.

Key user stories identified:

- Sign in and find nearest help.
- Request a helper and track them live.
- Act as a helper/provider.
- Manage profile, history, and ratings.
- Switch language anytime.

### Design Activities

Design activities completed include:

- Defined mobile-plus-API architecture.
- Designed normalized backend entities: users, auth identities, refresh tokens, OTP codes, service categories, helper profiles, service requests, location updates, and reviews.
- Prepared REST API contract for authentication, helper discovery, service requests, profile, and reviews.
- Designed request lifecycle as a state machine.
- Designed offline helper cache for Flutter.
- Designed provider mode workflow and first-accept-wins request assignment.
- Designed multilingual UI strategy.

### Development Work

Major development completed so far:

- FastAPI backend app with versioned API routes.
- PostgreSQL-targeted SQLAlchemy models and Alembic migrations.
- Email/password authentication with bcrypt password hashing.
- Phone OTP authentication with mock/dev fallback.
- Google and Apple sign-in support with mock/dev fallback.
- JWT access tokens and refresh-token rotation.
- Public category and helper discovery APIs.
- Helper search and sync feed for offline cache.
- Provider helper-profile registration/update API.
- Service request creation, acceptance, decline, cancellation, status update, and location update APIs.
- Review creation and helper rating aggregate recomputation.
- Flutter app shell with auth-gated routing.
- Welcome, login, home, map, helper list, helper detail, request tracking, provider inbox, provider job, profile, history, settings, and AI assistant screens.
- OpenStreetMap integration through `flutter_map`.
- GPS permission handling and saved/manual location support.
- Local SQLite helper cache for offline discovery.
- Theme, role, locale, auth, and AI configuration state management.
- User manual, README documentation, backend setup guide, and authentication setup guide.

### Testing Activities

The repository contains a structured test suite:

- Backend unit tests for geospatial calculations, request state transitions, SMS behavior, and AI proxy behavior.
- Backend contract tests for auth, helpers, requests, providers, profile, and reviews.
- Backend integration tests for full request lifecycle, live location updates, and first-accept-wins race handling.
- Flutter tests for offline data, helper sorting, location-distance logic, request status parsing, localization strings, theme switching, and AI settings persistence.

The project contains approximately:

- 43 backend application files.
- 81 Flutter source files.
- 25 test files.
- 53 discovered test cases.

### Documentation Prepared

Documentation prepared and reviewed includes:

- Root `README.md` for full-stack overview and quickstart.
- `backend/README.md` for backend stack, setup, and tests.
- `USER_MANUAL.md` for end-user workflows.
- `AUTHENTICATION_SETUP.md` for Google OAuth and SMS setup.
- `specs/002-roadside-marketplace/spec.md` for feature specification.
- `specs/002-roadside-marketplace/plan.md` for implementation plan.
- `specs/002-roadside-marketplace/data-model.md` for database schema.
- `specs/002-roadside-marketplace/contracts/rest-api.md` for API contract.
- `specs/002-roadside-marketplace/tasks.md` for implementation task tracking.

### Meetings, Training, and Knowledge Transfer

The project involved self-study and implementation across frontend, backend, database, testing, and deployment areas. Knowledge transfer topics included:

- Flutter application structure.
- FastAPI route and service design.
- PostgreSQL schema design and migrations.
- Secure authentication patterns.
- REST API testing.
- Offline cache strategy.
- Location and map integration.
- CI and quality tooling.

### Weekly Progress

| Week | Work Completed |
| --- | --- |
| Week 1 | Studied requirements, existing app structure, Spec Kit documents, and user stories. Identified core modules and project scope. |
| Week 2 | Created backend architecture, configuration, database session setup, models, migrations, and project skeleton. |
| Week 3 | Implemented authentication flows, JWT security, refresh tokens, OTP mock path, and social-login mock support. |
| Week 4 | Implemented service categories, helper discovery, search, Haversine sorting, helper cards, and call/SMS/directions actions. |
| Week 5 | Implemented service request creation, lifecycle states, cancellation, status timeline, and live helper location tracking. |
| Week 6 | Implemented provider mode, provider registration, incoming request listing, accept/decline actions, active job screen, and first-accept-wins logic. |
| Week 7 | Implemented profile, history, review/rating workflow, localization, theme settings, and offline/cache improvements. |
| Week 8 | Added tests, documentation, CI configuration, deployment guidance, user manual, and final project polish. |

---

## 6. Methodology / Approach

### Development Methodology Followed

The project followed an incremental Agile-style methodology. Work was divided into user stories and implementation phases. Each phase delivered a working part of the application that could be tested independently.

The major increments were:

1. Project setup and foundational architecture.
2. Authentication and helper discovery MVP.
3. Request lifecycle and live tracking.
4. Provider-side workflow.
5. Profile, history, reviews, and localization.
6. Testing, documentation, and deployment readiness.

### Project Workflow

The workflow followed was:

1. Read specification and implementation plan.
2. Define data model and API contract.
3. Implement backend models, services, and routers.
4. Implement Flutter models, API clients, state, and screens.
5. Add tests for unit, contract, and integration scenarios.
6. Improve UI states such as loading, empty, offline, and error screens.
7. Prepare documentation and setup guides.

### Design Approach

The system follows a mobile-plus-API architecture. The Flutter app is responsible for user interface, location permissions, maps, local cache, and device actions. The FastAPI backend is responsible for accounts, authorization, helper data, request lifecycle, live location records, profile data, and reviews.

**Figure 1: High-Level Architecture**

```text
Flutter App
  |
  |-- Presentation Layer
  |     Screens, widgets, maps, forms, status timeline
  |
  |-- State Layer
  |     AuthState, RoleState, ThemeState, LocaleController, AI settings
  |
  |-- Data Layer
  |     API clients, repositories, local SQLite cache
  |
  |-- Secure Storage
  |     JWT access token and refresh token
  |
  +---------------- HTTPS REST API ----------------+
                                                   |
FastAPI Backend                                    |
  |                                                |
  |-- API Routers                                  |
  |     auth, categories, helpers, requests,       |
  |     profile, reviews, ai                       |
  |                                                |
  |-- Service Layer                                |
  |     auth, helper discovery, request lifecycle, |
  |     profile, reviews, geo, SMS, AI             |
  |                                                |
  |-- ORM Layer                                    |
  |     SQLAlchemy models and Alembic migrations   |
  |                                                |
  +---------------- PostgreSQL --------------------+
```

### Implementation Strategy

The implementation strategy was to build the core rescue loop first and then add marketplace features. The core loop is:

1. User signs in or continues as guest.
2. User selects roadside issue category.
3. App displays nearest helpers sorted by distance.
4. Authenticated user requests help.
5. Provider accepts the request.
6. Seeker tracks status and helper location.
7. Job is completed.
8. Seeker gives rating and review.

**Figure 2: Request Lifecycle**

```text
requested
   |
   v
accepted
   |
   v
on_the_way
   |
   v
arrived
   |
   v
completed

cancelled can be reached from any non-terminal active state.
```

**Figure 3: Seeker-to-Provider Flow**

```text
Seeker opens app
      |
      v
Sign in / Guest mode
      |
      v
Choose category or search helper
      |
      v
View nearest helpers on list/map
      |
      v
Request help
      |
      v
Provider sees incoming request
      |
      v
Provider accepts first
      |
      v
Status and location updates
      |
      v
Completion and rating
```

---

## 7. Tools and Technologies Used

| Category | Tools / Technologies |
| --- | --- |
| Programming Languages | Dart, Python |
| Frontend Framework | Flutter |
| Backend Framework | FastAPI, Uvicorn |
| Database | PostgreSQL, SQLite local cache |
| ORM and Migrations | SQLAlchemy 2.x, Alembic |
| API Format | REST, JSON, OpenAPI |
| Authentication | JWT, bcrypt, refresh tokens, OAuth-style Google/Apple sign-in, OTP flow |
| Maps and Location | flutter_map, OpenStreetMap, latlong2, geolocator |
| State Management | Provider |
| Local Storage | sqflite, shared_preferences, flutter_secure_storage |
| Testing | pytest, httpx TestClient, flutter_test, sqflite_common_ffi |
| Quality Tools | Ruff, Mypy, Bandit, Gitleaks, pip-audit, Flutter Analyze |
| Development Tools | VS Code, PowerShell, Git |
| Version Control / CI | Git, GitLab CI configuration |
| Deployment-Ready Tools | Docker, Vercel configuration, Render-style backend deployment, Neon PostgreSQL as documented |
| Documentation | Markdown, Spec Kit design documents |

---

## 8. Results and Progress Status

### Modules Completed

| Module | Status | Description |
| --- | --- | --- |
| Authentication | Completed for prototype | Email/password, phone OTP mock, Google mock/real pathway, Apple mock/real pathway, guest mode, JWT, refresh tokens |
| Category and Helper Discovery | Completed | Service categories, nearby helper sorting, search, helper details, ratings, open/closed state |
| Maps and Location | Completed for prototype | OpenStreetMap display, current/saved location, helper markers, live helper marker |
| Offline Discovery | Completed for core flow | SQLite helper cache and offline discovery support |
| Service Requests | Completed for prototype | Create, view, accept, decline, cancel, update status, post location |
| Provider Mode | Completed for prototype | Provider registration, inbox, active job management, status updates |
| Reviews and Ratings | Completed | One review per completed request, rating validation, aggregate helper rating |
| Profile and History | Completed | Profile edit, preferred language, vehicle information, request history |
| Localization | Completed for supported prototype languages | English, Hindi, Telugu, Tamil string support |
| Testing | Completed at repository level | Unit, contract, integration, and Flutter tests available |
| Documentation | Completed | README, backend README, user manual, auth setup, specs, API contract |
| AI Assistant Enhancement | Completed as supplementary feature | AI roadside mechanic chat route and frontend screen with multiple provider configuration |

### Features Implemented

- Clean welcome and authentication flow.
- Guest access with gated actions for protected features.
- Role switch between seeker and helper/provider.
- Service category grid.
- Search by helper/service/location-related text.
- Nearby helper listing with distance and far-away flag.
- Native call, SMS, and directions actions.
- Request help flow with pickup location.
- Status timeline for request progress.
- Live helper location polling and display.
- Provider inbox for open requests.
- First-accept-wins assignment.
- Provider job screen for status updates.
- Profile editing and request history.
- Rating and review submission after completion.
- Multilingual UI and persisted language preference.
- Dark/light/system theme setting.
- AI roadside diagnostic assistant as an additional feature.

### Testing Completed / Available

The project includes test coverage for:

- Authentication contracts.
- Helper discovery and sorting.
- Haversine distance logic.
- Request lifecycle transitions.
- Live helper location updates.
- First-accept-wins acceptance race.
- Profile update and review validation.
- Offline local data behavior.
- Localization string fallback.
- Theme persistence.
- AI settings persistence and AI proxy behavior.

### Screenshots of Developed Application

The following screenshots should be attached in the final submitted report:

| Screenshot No. | Screen / Feature | Purpose |
| --- | --- | --- |
| 1 | Welcome and sign-in screen | Shows entry point and authentication options |
| 2 | Home screen with map and categories | Shows main seeker workflow |
| 3 | Helper list/search results | Shows nearest helpers, ratings, distance, and contact actions |
| 4 | Helper detail screen | Shows request action and helper profile |
| 5 | Request tracking screen | Shows map, live marker, and status timeline |
| 6 | Provider inbox | Shows incoming/open service requests |
| 7 | Provider active job screen | Shows status update and live location workflow |
| 8 | Profile/history screen | Shows account management and request records |
| 9 | Rating dialog | Shows post-completion review workflow |
| 10 | Settings/language screen | Shows multilingual support |

### Current Percentage of Project Completion

**Project Completion Status: 85%**

The core prototype is largely complete. The remaining work is mainly production hardening, real third-party credential setup, user acceptance testing, deployment verification, screenshot capture, and final documentation/presentation preparation.

---

## 9. Challenges Faced and Solutions

| Challenge | Description | Solution Applied |
| --- | --- | --- |
| Designing a two-sided marketplace flow | The application had to support both seekers and helpers without confusing the user journey. | Role-based screens and provider mode were added, with seeker and helper workflows separated clearly. |
| Secure authentication | Multiple sign-in methods required safe credential handling and session persistence. | JWT access tokens, refresh-token rotation, bcrypt password hashing, hashed OTP codes, and secure token storage were implemented. |
| Working without production OTP/OAuth credentials | Real SMS and OAuth services may not be available in a prototype environment. | Clearly labelled mock/dev fallback paths were added for phone OTP and social login. |
| Nearest helper discovery | Helpers needed to be sorted by distance without adding complex GIS infrastructure. | Haversine distance calculation with bounding-box filtering was used. |
| Offline discovery | Users should still see helper data when network is unavailable. | A local SQLite cache stores helper information for offline discovery, while online-only actions show connection-required states. |
| Live tracking without heavy infrastructure | Real-time updates were required, but WebSockets would add complexity. | Periodic HTTP polling and helper location update endpoints were implemented to meet prototype freshness requirements. |
| Request assignment race condition | Two providers could try to accept the same request. | An atomic conditional update was used so only the first helper can accept successfully. |
| Request status correctness | Invalid transitions could break the service workflow. | A backend state machine enforces allowed transitions. |
| Multilingual UI | The app needed to support multiple Indian languages and persist language preference. | A string-map localization system and persisted locale controller were implemented. |
| Location permissions and inaccurate web GPS | Users may deny permissions or receive unstable browser-based location estimates. | Permission states, saved/manual location, and session location stabilization were added. |
| Testing many user flows | The project includes backend, frontend, and integration behavior. | Unit, contract, integration, and Flutter tests were created around the highest-risk flows. |

---

## 10. Learning Outcomes

### Technical Skills Gained

- Flutter screen, widget, and state management using Provider.
- REST API consumption from Flutter using an authenticated API client.
- Secure local token handling through `flutter_secure_storage`.
- FastAPI route, schema, dependency, and error-envelope design.
- SQLAlchemy ORM modeling and Alembic database migrations.
- JWT authentication, refresh tokens, bcrypt password hashing, and OTP flow design.
- PostgreSQL relational schema planning for marketplace entities.
- Haversine distance calculation and nearest-helper sorting.
- Offline-first design using SQLite cache.
- Map integration with OpenStreetMap and Flutter Map.
- Backend unit, contract, and integration testing using pytest.
- Flutter unit/integration testing using flutter_test.
- CI-oriented quality checks, security scans, and documentation practices.

### Professional Skills Gained

- Requirement analysis from formal specification documents.
- Breaking a large project into incremental user stories.
- Writing technical documentation and user manuals.
- Understanding trade-offs between prototype simplicity and production readiness.
- Debugging across frontend, backend, and database layers.
- Communicating project progress using weekly milestones.
- Designing user flows from the perspective of real emergency scenarios.

### Communication, Teamwork, and Project Management Exposure

The project encouraged structured communication through specifications, plans, task lists, API contracts, README documents, and user manuals. It also provided exposure to project planning, task prioritization, testing discipline, and preparing a prototype for review/demo.

---

## 11. Work Plan for Remaining Internship Period

### Pending Tasks

- Fill final report cover-page details with official student/company information.
- Capture and insert actual application screenshots.
- Verify deployed frontend and backend URLs in a live environment.
- Configure production Google OAuth and SMS provider credentials if required.
- Run complete backend and Flutter quality suites in the target environment.
- Perform user acceptance testing with seeker and provider demo scenarios.
- Improve accessibility and responsive UI polish where needed.
- Prepare final presentation, demo script, and final internship report.

### Milestones and Expected Completion Dates

| Date / Period | Planned Work | Expected Output |
| --- | --- | --- |
| 19-21 June 2026 | Capture screenshots and verify main user flows | Screenshot appendix and demo checklist |
| 22-24 June 2026 | Configure/verify real OAuth and SMS credentials where available | Production-ready auth setup notes |
| 25-27 June 2026 | Run complete quality checks and fix important issues | Test and analysis summary |
| 28-30 June 2026 | Perform end-to-end demo testing with seeker and provider accounts | Final demo-ready build |
| 1-3 July 2026 | Prepare final documentation, presentation, and final report | Final internship submission package |

### Final Deliverables

- Flutter mobile/web application source code.
- FastAPI backend source code.
- PostgreSQL database migrations.
- API contract and OpenAPI documentation.
- User manual and setup documentation.
- Test suite and quality-check configuration.
- Final internship project report.
- Presentation/demo material with screenshots.

---

## 12. Conclusion

The internship project successfully developed a full-stack roadside assistance marketplace prototype. The system provides a practical seeker-provider workflow where users can sign in, find nearby helpers, request assistance, track live progress, and submit ratings. Providers can register, view incoming requests, accept jobs, and update service status.

The project demonstrates the use of Flutter for cross-platform frontend development, FastAPI for backend API development, PostgreSQL for structured data storage, and SQLite for offline helper discovery. It also includes important engineering practices such as secure authentication, request lifecycle validation, test coverage, documentation, CI configuration, and multilingual UI support.

The main learning outcome was understanding how a real-world product is designed across multiple layers: user interface, API, database, security, testing, and deployment. By the end of the internship, the expected outcome is a polished demo-ready application with final screenshots, verified deployment, and complete project documentation.

---

## 13. References

[1] Flutter Documentation. "Flutter documentation." Available: https://docs.flutter.dev/  
[2] FastAPI Documentation. "FastAPI framework, high performance, easy to learn." Available: https://fastapi.tiangolo.com/  
[3] PostgreSQL Global Development Group. "PostgreSQL Documentation." Available: https://www.postgresql.org/docs/  
[4] SQLAlchemy. "SQLAlchemy Documentation." Available: https://docs.sqlalchemy.org/  
[5] Alembic. "Alembic documentation." Available: https://alembic.sqlalchemy.org/  
[6] OpenStreetMap. "About OpenStreetMap." Available: https://www.openstreetmap.org/about  
[7] JWT.io. "Introduction to JSON Web Tokens." Available: https://jwt.io/introduction  
[8] Google Identity. "Authentication and authorization documentation." Available: https://developers.google.com/identity  
[9] Twilio. "Programmable Messaging documentation." Available: https://www.twilio.com/docs/messaging  
[10] Project repository documentation: `README.md`, `backend/README.md`, `USER_MANUAL.md`, and `AUTHENTICATION_SETUP.md`.  
[11] Project specification documents: `specs/002-roadside-marketplace/spec.md`, `plan.md`, `data-model.md`, `contracts/rest-api.md`, `research.md`, and `tasks.md`.

---

## 14. Appendix

### Appendix A: Important Project Files Reviewed

| Area | File / Folder |
| --- | --- |
| Main Flutter entry point | `lib/main.dart` |
| Flutter screens | `lib/presentation/screens/` |
| Flutter widgets | `lib/presentation/widgets/` |
| Flutter state | `lib/presentation/state/` |
| Flutter API clients | `lib/data/api/` |
| Flutter local cache | `lib/data/repositories/local_db.dart` |
| Backend entry point | `backend/app/main.py` |
| Backend API routes | `backend/app/api/v1/` |
| Backend services | `backend/app/services/` |
| Backend models | `backend/app/models/` |
| Backend schemas | `backend/app/schemas/` |
| Database migrations | `backend/alembic/versions/` |
| Backend tests | `backend/tests/` |
| Flutter tests | `test/` |
| Project specification | `specs/002-roadside-marketplace/` |

### Appendix B: Main REST API Endpoints

| Module | Endpoint Examples |
| --- | --- |
| Authentication | `POST /api/v1/auth/email/register`, `POST /api/v1/auth/email/login`, `POST /api/v1/auth/phone/request-otp`, `POST /api/v1/auth/google`, `GET /api/v1/auth/me` |
| Profile | `GET /api/v1/profile`, `PATCH /api/v1/profile` |
| Categories | `GET /api/v1/categories` |
| Helpers | `GET /api/v1/helpers/nearby`, `GET /api/v1/helpers/search`, `GET /api/v1/helpers`, `POST /api/v1/helpers` |
| Requests | `POST /api/v1/requests`, `GET /api/v1/requests/mine`, `GET /api/v1/requests/open`, `POST /api/v1/requests/{id}/accept`, `POST /api/v1/requests/{id}/status`, `POST /api/v1/requests/{id}/location` |
| Reviews | `POST /api/v1/reviews`, `GET /api/v1/helpers/{id}/reviews` |
| AI Assistant | `POST /api/v1/ai/chat` |

### Appendix C: Screenshot Placement

Insert application screenshots after this section in the final printed/submitted copy:

1. Welcome / Login screen.
2. Home screen with map and categories.
3. Nearby helper list.
4. Helper detail screen.
5. Request tracking screen.
6. Provider inbox.
7. Provider active job screen.
8. Profile and request history.
9. Rating and review dialog.
10. Language/settings screen.

### Appendix D: Sample State Machine Logic

```text
Allowed provider-driven transitions:

accepted -> on_the_way
on_the_way -> arrived
arrived -> completed

Terminal states:
completed, cancelled

Any invalid transition is rejected by the backend service layer.
```

### Appendix E: Sample Database Entities

```text
User
AuthIdentity
RefreshToken
OtpCode
ServiceCategory
CategoryHelperType
HelperProfile
ServiceRequest
HelperLocationUpdate
Review
```
