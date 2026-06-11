# AGENTS.md — AI Agent & Automation Guide

This file describes how AI coding agents (Claude Code, Copilot, Cursor, etc.) and CI automation agents should interact with this repository.

---

## Repository Overview for Agents

| Component | Language | Location | Entry point |
|-----------|----------|----------|-------------|
| Backend API | Python 3.11+ / FastAPI | `backend/` | `app/main.py` |
| Flutter frontend | Dart 3 / Flutter 3.x | `lib/` | `lib/main.dart` |
| Database migrations | Alembic | `backend/alembic/` | `alembic/versions/` |
| Tests (backend) | pytest | `backend/tests/` | `pytest` |
| Tests (frontend) | flutter_test | `test/` | `flutter test` |
| Spec & design docs | Markdown | `specs/` | `specs/002-roadside-marketplace/` |

---

## Architecture Constraints

- **Database**: PostgreSQL 14+ only — do **not** use SQLite for integration tests or migrations. The backend's `alembic/` migrations target PostgreSQL syntax.
- **Auth**: JWT tokens issued by the backend. The Flutter client stores tokens in `flutter_secure_storage`. Do not store secrets in `SharedPreferences` or Dart source.
- **Environment secrets**: all secrets live in `backend/.env` (copied from `backend/.env.example`). Never commit `.env` files. Never hard-code secrets in source.
- **CORS**: `CORS_ORIGINS=*` in `.env.example` is for local development only. Production deployments must set explicit origins.

---

## Running Quality Checks

Before submitting any change, run the full quality suite:

```bash
# From project root (backend)
cd backend
source .venv/bin/activate        # or .\.venv\Scripts\Activate.ps1 on Windows

ruff check .                      # linting
ruff format --check .             # formatting
mypy app/                         # type checking
bandit -r app/ -ll                # security scanning
pytest --cov=app --cov-fail-under=80   # tests + coverage

# From project root (Flutter)
flutter analyze                   # static analysis
flutter test                      # widget + unit tests
```

---

## CI Pipeline Behaviour

The GitLab CI pipeline (`.gitlab-ci.yml`) runs on every push:

| Stage | Jobs | What it checks |
|-------|------|---------------|
| `lint` | ruff, mypy, flutter analyze | Code style and types |
| `security` | bandit, gitleaks, pip-audit | Secrets and CVEs |
| `test` | pytest (PostgreSQL service), flutter test | Correctness + coverage |
| `build` | docker build | Container builds cleanly |

A pipeline failure blocks the MR merge. Fix the failure before requesting review.

---

## Pre-commit Hooks

Install once after cloning:

```bash
pip install pre-commit
pre-commit install
```

Hooks run automatically on `git commit`. To run them manually:

```bash
pre-commit run --all-files
```

Hooks include: Ruff (lint + format), Mypy, Bandit, Gitleaks (secret scan), trailing-whitespace, end-of-file fixer.

---

## Database Setup for CI / Integration Tests

Integration tests require a live PostgreSQL instance. In CI this is provided by the GitLab service container. Locally:

```bash
# Create the test database (one time)
createdb -U postgres roadside_help_test

# Run migrations against it
DATABASE_URL=postgresql+psycopg://postgres:postgres@localhost:5432/roadside_help_test \
  alembic upgrade head

# Run tests
DATABASE_URL=postgresql+psycopg://postgres:postgres@localhost:5432/roadside_help_test \
  pytest
```

---

## Generating Changelogs

This project uses [git-cliff](https://git-cliff.org/) for automated changelog generation from Conventional Commits:

```bash
# Preview unreleased changes
git cliff --unreleased

# Generate full CHANGELOG.md
git cliff -o CHANGELOG.md

# Tag a release and update changelog
git tag v0.2.0
git cliff -o CHANGELOG.md
git add CHANGELOG.md && git commit -m "chore(release): v0.2.0"
```

---

## Spec-Kit Workflow

This project uses the [Spec Kit](https://github.com/speckit-dev/speckit) spec-driven development workflow. Design artifacts live in `specs/002-roadside-marketplace/`:

| File | Purpose |
|------|---------|
| `spec.md` | Feature specification |
| `plan.md` | Implementation plan |
| `tasks.md` | Actionable task list |
| `data-model.md` | Database schema |
| `api-contract.md` | OpenAPI endpoint contracts |

When implementing features, consult these documents first. Update them when the design changes.

---

## Agent-Specific Instructions

### Claude Code / Claude API
- Read `specs/002-roadside-marketplace/plan.md` for full project context before making changes.
- Prefer editing existing files over creating new ones.
- Do not add speculative features or dead-code fallbacks.
- All generated Python must pass `ruff check` and `mypy` without errors.
- Do not commit `.env`, `*.db`, or secret files under any circumstances.

### Dependabot / Renovate
- Auto-merge patch updates for non-security dependencies after CI passes.
- Security updates: auto-merge if tests pass; otherwise open a PR for manual review.
- Pin Python dependency versions in `requirements.txt`; use `>=` bounds only in `pyproject.toml`.

### GitLab CI Runner
- Use the Docker executor with the `python:3.11-slim` image for Python jobs.
- PostgreSQL service image: `postgres:16-alpine`.
- Cache the `.venv` directory keyed on `requirements.txt` hash.
