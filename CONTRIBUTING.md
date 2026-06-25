# Contributing to Roadside SOS

Thank you for your interest in contributing! This document outlines everything you need to know to get started, submit changes, and meet our quality bar.

---

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Branch & Commit Conventions](#branch--commit-conventions)
- [Submitting a Merge Request](#submitting-a-merge-request)
- [Quality Checklist](#quality-checklist)
- [Project Structure](#project-structure)
- [Spec-Kit Workflow](#spec-kit-workflow)

---

## Code of Conduct

All contributors are expected to abide by our [Code of Conduct](CODE_OF_CONDUCT.md). Please read it before participating.

---

## Getting Started

1. **Fork** the repository on GitLab.
2. **Clone** your fork locally:
   ```bash
   git clone https://gitlab.com/<your-username>/speckit_project.git
   cd speckit_project
   ```
3. Add the upstream remote:
   ```bash
   git remote add upstream https://gitlab.com/arunn009/help.git
   ```

---

## Development Setup

### Prerequisites

| Tool | Minimum Version |
|------|----------------|
| Python | 3.11+ |
| Flutter SDK | 3.x (Dart 3.x) |
| PostgreSQL | 14+ |
| Node.js (optional) | 18+ (for tooling only) |

### Backend (FastAPI)

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
pip install pre-commit
pre-commit install

Copy-Item .env.example .env
# Edit .env with your local DATABASE_URL and JWT_SECRET

alembic upgrade head
python -m app.seed.run

uvicorn app.main:app --reload --port 8000
```

### Frontend (Flutter)

```powershell
cd frontend
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
```

---

## Branch & Commit Conventions

### Branch Names

Use the following prefixes:

| Prefix | Purpose |
|--------|---------|
| `feat/` | New features |
| `fix/` | Bug fixes |
| `chore/` | Maintenance, refactoring, tooling |
| `docs/` | Documentation only |
| `test/` | Tests only |

Example: `feat/provider-push-notifications`

### Commit Messages (Conventional Commits)

We use [Conventional Commits](https://www.conventionalcommits.org/) — these power the automated `CHANGELOG.md` via `git-cliff`.

```
<type>(<optional scope>): <short description>

[optional body]

[optional footer: BREAKING CHANGE or issue refs]
```

**Types**: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `ci`, `perf`

Examples:
```
feat(auth): add Google OAuth sign-in support
fix(requests): prevent double-accept race condition
docs(readme): add Haversine query explanation
chore(ci): cache .venv by requirements.txt hash
```

---

## Submitting a Merge Request

1. **Sync** with upstream before branching:
   ```bash
   git fetch upstream
   git checkout main
   git merge upstream/main
   ```
2. Create a feature branch from `main`.
3. Make your changes and commit using Conventional Commits.
4. **Run the full quality suite** (see below) — the CI pipeline will reject failures.
5. Push your branch and open a **Merge Request** against `main`.
6. Fill in the MR template: summary, related issue, testing steps, and screenshots for UI changes.
7. Request a review from at least one maintainer.

> **Do not** merge your own MR. Wait for approval and a green pipeline.

---

## Quality Checklist

Run these locally **before** pushing. The CI pipeline enforces the same checks.

### Backend

```powershell
cd backend
.\.venv\Scripts\Activate.ps1

ruff check .                          # lint
ruff format --check .                 # format
mypy app/                             # type checking
bandit -r app/ -ll                    # security scan
pytest --cov=app --cov-fail-under=80  # tests + 80% coverage
```

### Frontend

```powershell
cd frontend
flutter analyze   # static analysis
flutter test      # widget + unit tests
```

### Pre-commit (runs automatically on `git commit`)

```bash
pre-commit run --all-files
```

---

## Project Structure

| Path | Contents |
|------|----------|
| `backend/app/` | FastAPI application (routers, services, models, schemas) |
| `backend/alembic/` | Database migration scripts |
| `frontend/lib/` | Flutter source code |
| `specs/` | Spec-Kit design artifacts |
| `docs/` | Additional documentation |
| `scripts/` | Utility and automation scripts |

---

## Spec-Kit Workflow

Before implementing a new feature, consult the design artifacts in `specs/002-roadside-marketplace/`:

| File | Purpose |
|------|---------|
| `spec.md` | Feature specification |
| `plan.md` | Implementation plan |
| `tasks.md` | Task breakdown |
| `data-model.md` | Database schema |
| `api-contract.md` | OpenAPI endpoint contracts |

Update these documents if your change alters the design.

---

## Reporting Issues

- Use the GitLab issue tracker.
- For **security vulnerabilities**, please follow the [Security Policy](SECURITY.md) — do **not** open a public issue.
- Label bugs with `type::bug` and enhancements with `type::feature`.

---

Thank you for helping make Roadside SOS better! 🚗🔧
