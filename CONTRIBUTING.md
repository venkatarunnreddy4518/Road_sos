# Contributing to Roadside Help

Thank you for contributing! This guide covers everything you need to submit quality work.

## Table of Contents
- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Branch Naming](#branch-naming)
- [Commit Messages](#commit-messages)
- [Pull / Merge Request Process](#pull--merge-request-process)
- [Testing Requirements](#testing-requirements)
- [Code Style](#code-style)

---

## Code of Conduct

All contributors are expected to follow our [Code of Conduct](CODE_OF_CONDUCT.md). Respectful, inclusive collaboration is mandatory.

---

## Getting Started

1. **Fork & clone** the repository.
2. Set up the backend (Python 3.11+):
   ```powershell
   cd backend
   python -m venv .venv
   .\.venv\Scripts\Activate.ps1
   pip install -r requirements.txt
   pip install -r requirements-dev.txt
   ```
3. Install Flutter SDK 3.x and run `flutter pub get` at the project root.
4. Install pre-commit hooks:
   ```bash
   pip install pre-commit
   pre-commit install
   ```
5. Copy `.env.example` → `.env` and fill in your values.

---

## Development Workflow

1. Create a feature branch from `main` (see [Branch Naming](#branch-naming)).
2. Make changes with tests.
3. Run the full quality suite before pushing:
   ```bash
   # Backend
   cd backend
   pytest --cov=app --cov-fail-under=80
   ruff check .
   mypy app/

   # Flutter
   flutter analyze
   flutter test
   ```
4. Open a Merge Request (MR) against `main`.

---

## Branch Naming

| Type | Pattern | Example |
|------|---------|---------|
| Feature | `feature/<short-desc>` | `feature/provider-ratings` |
| Bug fix | `fix/<short-desc>` | `fix/otp-timeout` |
| Docs | `docs/<short-desc>` | `docs/api-guide` |
| Chore | `chore/<short-desc>` | `chore/update-deps` |

---

## Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(scope): short summary

Optional body explaining WHY the change was needed.
```

**Types**: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `perf`, `ci`

Examples:
```
feat(auth): add phone OTP verification
fix(tracking): correct helper location drift on low GPS accuracy
docs(api): document request lifecycle endpoints
```

---

## Pull / Merge Request Process

1. Ensure CI passes (linting, type checks, tests, coverage ≥ 80 %).
2. Update `CHANGELOG.md` under `[Unreleased]` if your change is user-visible.
3. Link the MR to the relevant issue (`Closes #42`).
4. Request review from at least one maintainer.
5. Squash commits on merge to keep history clean.

---

## Testing Requirements

| Layer | Tool | Minimum coverage |
|-------|------|-----------------|
| Backend unit | pytest | 80 % |
| Backend integration | pytest + real PostgreSQL | all critical paths |
| Flutter widgets | flutter_test | smoke tests for all screens |

Do **not** mock the database in integration tests — use a real PostgreSQL instance. See [AGENTS.md](AGENTS.md) for CI database setup.

---

## Code Style

### Python (backend)
- **Formatter / linter**: Ruff (`ruff format .` + `ruff check .`)
- **Type checker**: Mypy (`mypy app/`)
- **Security scanner**: Bandit (`bandit -r app/`)
- Line length: 100 characters.
- All public functions must have type annotations.

### Dart / Flutter (frontend)
- Follow the [Effective Dart](https://dart.dev/effective-dart) guide.
- Run `flutter analyze` before committing; zero warnings allowed.

### General
- Delete dead code instead of commenting it out.
- Keep functions small and single-purpose.
- Write comments only when the *why* is non-obvious.
