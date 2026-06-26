# Roadside SOS — Week-wise Progress Report (with Git History)

**Project:** Roadside SOS — a two-sided roadside-assistance marketplace (Uber-style)
**Repository:** https://code.swecha.org/arunn009/help  (mirror: github.com/venkatarunnreddy4518/Road_sos)
**Live demo:** Frontend (Vercel) `https://help-ashy.vercel.app` · Backend (Render) `https://roadside-help-api.onrender.com`
**Stack:** Flutter (Dart) · FastAPI (Python 3.11) · PostgreSQL (Neon) · SQLAlchemy + Alembic · Ollama / Llama 3.2 · GitLab CI · Docker
**Period covered:** 9 June 2026 – 26 June 2026  ·  **146 commits across 3 weeks**

> Each week below has (a) a theme-grouped summary and (b) the **actual git commit log** for that week (date · short SHA · message).

---

## Week 1 — 9–14 June 2026  ·  ~116 commits
### Foundation & full MVP build

**Spec-driven kickoff** — initialised the **Spec Kit** workflow; authored the feature **specification**, **implementation plan**, **design artifacts**, and an actionable **task list**.

**Backend (FastAPI + PostgreSQL)** — two-sided marketplace API (seekers, helpers, SOS requests, reviews, location history); **auth** (Phone OTP, Google, Email+Password, Guest) with JWT + bcrypt; live tracking + first-accept-wins; nearest-helper (Haversine); Twilio SMS + Google sign-in wiring; Alembic migrations; PostgreSQL with SQLite fallback; race-condition & datetime fixes; backend test suite.

**Frontend (Flutter — Android / iOS / Web)** — full screen flow (welcome → auth → home → search → tracking → provider → profile → history → settings); **offline-first** SQLite cache with call/SMS fallback; **localization** (English, Hindi, Telugu, Tamil); native Android/iOS platforms.

**AI assistant** — **AI mechanic assistant** with local/cloud config (backend proxy → **local Ollama / Llama 3.2** + offline fallback).

**UI / UX** — premium monochrome theme (light/dark) + monochrome maps; light-green **Bento** layout with animated markers; multilingual **welcome landing page**; React→Flutter redesigns of timeline, carousel, AI, profile, payments, safety, Refer & Earn, settings, Help & Support, Provider Mode; **My SOS Requests** history (seeker/helper tabs); fare + helper name on cards.

**Deploy & compliance** — **Vercel** static config + pre-built web assets; **Render** auto-seed; AGPL-3.0 license; `.env.example`; `.gitlab-ci.yml`; 8 quality-tool configs; detailed **README** with architecture/flowcharts/DB models.

**Git commit log — Week 1:**
```
2026-06-09 c147948  Initial commit from Specify template
2026-06-09 c60dff6  initialising spec kit
2026-06-09 eb2e4ac  Add roadside-help feature specification
2026-06-09 cbb284a  spec clarified step 5
2026-06-09 102e7ae  feat(roadside-help): generate implementation plan and design artifacts
2026-06-09 350d401  feat(roadside-help): generate actionable task list
2026-06-09 9370bcd  Merge branch '001-roadside-help' into 'main'
2026-06-09 dc0e45e  feat(roadside-help): complete final polish and cross-cutting concerns
2026-06-09 791d4fa  Merge branch '001-roadside-help' into 'main'
2026-06-09 e4057ec  all phases finished
2026-06-09 d3c837c  Merge branch '001-roadside-help' into 'main'
2026-06-09 3b6ea8f  fix: resolve analysis errors and missing dependencies
2026-06-09 18684fd  added main.dart in lib/main.dart
2026-06-09 11ea37f  Merge branch '001-roadside-help' into 'main'
2026-06-09 a4c638b  codex
2026-06-10 3bb616d  feat(roadside-marketplace): two-sided marketplace prototype (auth, FastAPI/PostgreSQL, live tracking)
2026-06-10 ae49213  adding ui and features
2026-06-10 a01f413  Merge pull request #1 (001-roadside-help)
2026-06-10 f67381d  Merge pull request #2 (002-roadside-marketplace)
2026-06-10 80c1349  new features
2026-06-10 15827e7  test(backend): add accept-race + profile/reviews tests; gitignore server logs
2026-06-10 14f70ad  Merge main into integrated marketplace prototype
2026-06-10 10cec72  feat: offline-first cache, full localization, green test suite
2026-06-10 cbd4805  fix(backend): use bcrypt directly (passlib incompatible with bcrypt 4.x); full run guide
2026-06-10 904befd  build: add native Android/iOS platforms with permissions for phone runs
2026-06-10 3fe4b16  docs+feat: production wiring for Twilio SMS & Google sign-in
2026-06-10 195389d  Implement premium black-and-white monochrome UI with light/dark toggles and monochrome maps
2026-06-10 0671f68  fix(web): fix web geolocation by bypassing unsupported platform checks
2026-06-11 ec1178d  feat: premium light-green Bento UI, map marker animations, custom rails, backend category seeds sync
2026-06-10 668d4fa  Merge branch 'feature/black-and-white-ui' into 'main'
2026-06-11 d82209a  changes loginpage and profile section
2026-06-11 3359f99  resolve some features
2026-06-11 aeb31a2  Merge branch 'feature/uifix' into 'main'
2026-06-11 ff5ca5b  added backend files
2026-06-11 ffb6dbd  Merge pull request #3 (feature/uifix)
2026-06-11 79f9e96  fix: SQLite fallback for zero-config Render deploy, sync helpers nearby, UI/scroll fixes
2026-06-11 801e1a6  Merge branch 'feature/uifix'
2026-06-11 989210b  Merge branch 'feature/uifix' into 'main'
2026-06-11 256bad2  fix: resolve offset-naive/aware datetime comparisons in SQLite (refresh, requests, reviews)
2026-06-11 6fbbb98  Merge branch 'feature/uifix'
2026-06-11 86ea1b7  fix: auto-convert postgresql:// to postgresql+psycopg:// for standard DB URLs
2026-06-11 fe2e670  Merge branch 'feature/uifix'
2026-06-11 c36a41d  added files
2026-06-11 f8e2e22  Merge branch 'main' into feature/uifix
2026-06-11 ba935ca  chore: add AGPLv3 license, .env.example, .gitlab-ci.yml, tool config files
2026-06-11 656fa53  Merge branch 'feature/uifix'
2026-06-11 0d9b738  ci: allow quality verification failures to ensure pipeline completion
2026-06-11 4face5a  Merge branch 'feature/uifix'
2026-06-11 4fb8902  chore: add vercel entrypoint to pyproject.toml
2026-06-11 785c96d  Merge branch 'feature/uifix'
2026-06-11 c4b5a1e  deploy: add vercel.json static config and pre-built flutter web assets
2026-06-11 78c13d8  Merge feature/uifix for Vercel static deploy
2026-06-11 0318f52  chore: add pylint, flake8, semgrep, pyupgrade configs
2026-06-11 4f2a3cc  Merge: add all 8 quality tools for compliance
2026-06-11 89d5b39  fix: force vercel static site mode, skip Python auto-detection
2026-06-11 dba9780  Merge: fix Vercel static deploy config
2026-06-11 c793625  feat: multilingual welcome landing page with animated greetings
2026-06-11 1ba722a  Merge: add welcome landing page
2026-06-11 3956f2d  fix: add Flutter app.html (welcome page Get Started)
2026-06-11 86091ce  Merge: add app.html
2026-06-11 b5625d1  fix(ui): Stack layout for non-wide bento cards (prevent overlap/overflow)
2026-06-11 d4538a6  deploy: compiled web assets with category bento grid fixes
2026-06-11 e98bbb4  Merge branch 'feature/uifix'
2026-06-11 77ce1e4  fix(auth): desktop-friendly welcome, pass credentials to sub-screens, auto-trigger OTP
2026-06-11 3f915bb  feat: Flutter web init template + backend SQLite WAL file
2026-06-11 579fe25  feat(web): multilingual welcome page with session redirect
2026-06-11 9539ee3  Merge pull request #4 (feature/uifix)
2026-06-11 717faa4  fix some backend issues
2026-06-11 69aa6c8  Merge pull request #5 (feature/uifix)
2026-06-11 97ae927  added backend
2026-06-11 054bb94  fix(auth): improve login on all options with database and API key fixes
2026-06-12 5894753  added some features and resolve bugs
2026-06-12 213cba7  Merge pull request #6 (003-login-auth-fix)
2026-06-12 0a8d2af  feat: add AI mechanic assistant and local/cloud configurations
2026-06-12 5a0723e  Merge pull request #7 (ai-assistance)
2026-06-12 748e093  deploy: compiled web assets with AI Mechanic Assistant
2026-06-12 a053bc4  Merge remote-tracking branch 'github/main'
2026-06-12 ee384c0  deploy: update flutter bootstrap asset
2026-06-12 2a3910e  added localize upto profile
2026-06-12 46a0929  Merge pull request #8 (localize)
2026-06-12 05b0b29  feat(localization): fix hardcoded strings in HomeScreen, HelperResults, MarketplaceHelperCard
2026-06-12 348f5a5  feat(localization,theme): localize helper/provider/auth/AI pages; dynamic theme mode
2026-06-13 02c891b  google auth added
2026-06-13 e10a833  modify navbar
2026-06-13 81564a8  Merge pull request #9 (google_auth)
2026-06-13 e7f1531  build: rebuild web files for custom bottom navigation bar
2026-06-13 5f32954  docs: update README with system architecture, flowcharts, DB models
2026-06-13 5561928  build: update AI system prompt and recompile web assets
2026-06-13 ca5d9d4  feat: interactive provider alerts and persistent profile options
2026-06-13 9ef9c6b  recheck merge
2026-06-13 3f52af1  Merge branch 'google_auth' into 'main'
2026-06-13 e90e276  resolve and refixes issues and errors
2026-06-13 df2a097  build: auto-seed on container boot; ignore local logs (Render prep)
2026-06-13 add0049  feat(auth): standard 'Continue with Google' button via OAuth2 popup
2026-06-13 2ed6c43  feat(tracking): SOS status timeline (Flutter port of React timeline)
2026-06-13 7f4c073  Merge pull request #10 (interactive-profile-provider-alerts)
2026-06-14 fbcc545  feat(home): interactive helper-cards carousel (Flutter port)
2026-06-14 4969f02  feat(ai): redesign AI assistant screen (Flutter port)
2026-06-14 eb0d039  feat(profile): redesign profile screen (Flutter port)
2026-06-14 abdab47  feat(profile): redesign payments sheet
2026-06-14 5e38671  feat(profile): redesign safety guidelines + emergency contacts
2026-06-14 c8a5408  feat(profile): redesign Refer & Earn sheet
2026-06-14 b90a146  feat(settings): redesign settings screen
2026-06-14 9deae4e  Merge branch 'feature/helper-cards-carousel'
2026-06-14 8737849  Merge branch 'feature/ai-assistant-redesign'
2026-06-14 232bfe2  Merge branch 'feature/profile-redesign'
2026-06-14 52c8de1  Merge remote-tracking branch 'github/main'
2026-06-14 00b34c8  build: deploy bundle (timeline + carousel + AI + profile redesigns)
2026-06-14 1cf899e  feat(profile): redesign Help & Support sheet + add Provider Mode registration
2026-06-14 0fbc742  build: deploy bundle (Help & Support + Provider Mode)
2026-06-14 e4cd95e  feat(history): redesign My SOS Requests (seeker/helper tabs + status cards)
2026-06-14 3f08798  build: deploy bundle (My SOS Requests redesign)
2026-06-14 c65f1fa  feat(requests): add fare_amount + helper_name; show fare on SOS cards
2026-06-14 5057d2f  build: deploy bundle (fare on SOS request cards)
2026-06-14 d3f3d5d  Resolve merge conflicts
2026-06-14 8495269  updated readme.md
```

---

## Week 2 — 15–21 June 2026  ·  17 commits
### Dispatch logic, tracking UX & CI/CD hardening

**Marketplace logic** — **nearest-helper dispatch** with ETA + escalation; more accurate web location; full-screen interactive map with draggable sheet and locale-aware geocoding.

**Tracking & UX** — per-service **themed tracking UI** with audio alerts and keyboard login; **Seeker/Helper role switch**, theme slider, tappable nearby-helpers list.

**CI/CD (GitLab)** — made **all jobs pass** (lint/type/test/security); standardised the **Docker executor** + a local runner setup script; added **format / type-check / coverage** stages; **auto-create Releases** on version tags; hardened against flaky networks (auto-retry, **DAG** ordering, per-build networking); slimmed the backend image.

**Git commit log — Week 2:**
```
2026-06-16 f4f5973  feat(requests): nearest-helper dispatch, ETA + escalation; accurate web location
2026-06-16 5888398  chore: add GitLab runner setup script; use withValues over deprecated withOpacity
2026-06-16 ae00beb  fix(home): full-screen interactive map + draggable sheet; locale-aware geocoding
2026-06-16 b9e70f9  ci: make all GitLab pipeline jobs pass (lint, type, test, security)
2026-06-16 ae898d1  ci(runner): default GitLab runner to docker executor; enforce LF on shell scripts
2026-06-19 2de9d51  feat(tracking): per-service themed tracking UI, audio alerts, keyboard login
2026-06-19 017338e  feat(home): Seeker/Helper role switch, theme slider, tappable nearby-helpers list
2026-06-20 de5510f  ci: fix flutter image tag and gitleaks false positive
2026-06-20 5d8d57b  ci: auto-retry network-bound jobs to survive transient pull failures
2026-06-21 1be69a9  fix(docker): drop unneeded apt build deps from backend image
2026-06-21 c65eaee  ci: add format, type_check, and coverage stages
2026-06-21 8f96a86  ci: auto-create GitLab Release on version tags
2026-06-21 1ebeed0  ci: make release job network-robust (cached image + job token)
2026-06-21 28e1732  ci: run jobs as a DAG so fast jobs don't wait on the slow Flutter pull
2026-06-21 5bd3ece  ci: harden pipeline against flaky-runner network failures
2026-06-21 a198918  ci: trigger pipeline run on local runner
2026-06-21 f2c1cf7  ci: put builds on per-build network so service aliases resolve
```

---

## Week 3 — 22–26 June 2026  ·  13 commits
### Repository restructure, quality & open-source hygiene

**Structure** — **split the repo** into `frontend/` (Flutter) + `backend/` (FastAPI), re-pathing CI/Vercel/lint; tidied the root (docs → `docs/`, scripts → `scripts/`).

**Cleanup** — removed tracked cruft (SQLite DBs, an orphaned nested-clone gitlink, runner artifacts); preserved reports separately; consolidated duplicated flake8/pylint config.

**Open-source / process** — added **CONTRIBUTING / CODE_OF_CONDUCT / SECURITY / USER_MANUAL**; **GitLab issue templates** (Bug/Feature/Docs/Setup) + **`.vscode/`** workspace config; in-app **"Report an Issue"** option (opens the GitLab issue tracker).

**Infrastructure** — diagnosed & fixed CI **runner** issues (shell→docker executor, Docker engine restart); restored a green pipeline.

**Git commit log — Week 3:**
```
2026-06-24 4d3b27d  refactor: move Flutter app into frontend/ (split frontend/ + backend/)
2026-06-25 26426aa  ci: trigger pipeline on docker runner
2026-06-25 6b169d1  ci: trigger clean pipeline (single docker runner)
2026-06-25 d6990b4  chore: drop tracked cruft (SQLite DBs, orphaned help gitlink, runner id)
2026-06-25 5b61f1c  docs: add internship project reports (preserved from removed help/ clone)
2026-06-25 290346e  chore: tidy root - group docs in docs/, script in scripts/
2026-06-25 e510674  Edit Dockerfile
2026-06-25 c4a2f8c  Dockerfile
2026-06-25 bb0ad16  docs: add CONTRIBUTING, USER_MANUAL, SECURITY, and CODE_OF_CONDUCT files
2026-06-25 57601e3  Dockerfile
2026-06-25 1a91dec  chore: add GitLab issue templates + VS Code workspace settings
2026-06-26 b675c25  ci: re-run pipeline (docker engine restored)
2026-06-26 2061030  feat(profile): add 'Report an Issue' in Help & Support
```

---

## At-a-glance summary

| Week | Dates | Commits | Focus | Headline outcome |
|------|-------|---------|-------|------------------|
| **1** | 9–14 Jun | ~116 | Foundation & full MVP | End-to-end app: backend, multi-platform Flutter, all auth, maps, AI (Ollama), 4-language localization, live deploy |
| **2** | 15–21 Jun | 17 | Dispatch, tracking, CI/CD | Nearest-helper dispatch + ETA, themed tracking, hardened green GitLab pipeline |
| **3** | 22–26 Jun | 13 | Structure, quality, hygiene | `frontend/`+`backend/` split, docs/templates, in-app issue reporting, clean CI |

**Cross-platform reach:** Android · iOS · Web (Chrome / Firefox / Safari / Edge)
**Languages:** English · हिन्दी · తెలుగు · தமிழ்
**Quality gates (CI):** ruff · flake8 · pylint · mypy · bandit · gitleaks · semgrep · pip-audit · pytest (coverage) · Docker build
**AI:** in-app assistant via local **Ollama / Llama 3.2** (configurable OpenAI/Gemini/Anthropic; offline fallback)
