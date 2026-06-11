# Changelog

All notable changes to Roadside Help are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versions follow [Semantic Versioning](https://semver.org/).
Changelog is auto-generated from [Conventional Commits](https://www.conventionalcommits.org/) via [git-cliff](https://git-cliff.org/).

---

## [Unreleased]

## [0.1.0] — 2026-06-11

### Added
- Two-sided marketplace: Seeker and Provider modes for roadside assistance
- Four authentication methods: Phone OTP, Email/Password, Google Sign-In, Guest mode
- Real-time helper discovery with OpenStreetMap (flutter_map) and live GPS tracking
- Service categories: Puncture/Tyre, Fuel/Petrol, Mechanic, Towing, Battery
- Request lifecycle: Pending → Accepted → En Route → On Site → Completed
- Live helper location sharing during active requests
- 1–5 star ratings with helper averages
- Request history for both seeker and provider roles
- Multi-language UI: English, Hindi, Telugu, Tamil — persisted across sessions
- Offline-first helper discovery via SQLite cache
- Profile management: personal info, vehicle details, provider settings
- FastAPI + PostgreSQL backend with JWT authentication and bcrypt password hashing
- Alembic database migrations
- Demo seed data (~15 helpers across categories)
- Dev/mock fallbacks for OTP and Google sign-in (no external accounts needed)
- Flutter web, Android, and iOS support
- Spec Kit spec-driven development workflow with full design artifacts

[Unreleased]: https://gitlab.com/teamcenturions/roadside-help/-/compare/v0.1.0...HEAD
[0.1.0]: https://gitlab.com/teamcenturions/roadside-help/-/tags/v0.1.0
