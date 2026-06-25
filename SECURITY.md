# Security Policy

## Supported Versions

The following versions of Roadside SOS receive security updates:

| Version | Supported |
|---------|-----------|
| Latest (`main` branch) | ✅ Active |
| Previous releases | ⚠️ Critical fixes only |

---

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitLab issues, merge requests, or comments.**

If you discover a security vulnerability, please use the responsible disclosure process below:

### How to Report

1. **Email**: Send a detailed report to the project maintainer's registered GitLab email (found on the GitLab profile page).
2. **GitLab Confidential Issue**: Open a [confidential issue](https://docs.gitlab.com/ee/user/project/issues/confidential_issues.html) in the repository — only project maintainers can see these.

### What to Include

Please include as much of the following as possible:

- Type of vulnerability (e.g., SQL injection, authentication bypass, JWT misconfiguration, IDOR)
- The full path of the affected file(s) or API endpoint(s)
- Step-by-step reproduction instructions
- Proof-of-concept code or screenshots (if available)
- Potential impact and affected versions

### Response Timeline

| Stage | Target Time |
|-------|-------------|
| Acknowledgement | Within **48 hours** |
| Triage & severity assessment | Within **5 business days** |
| Patch available for critical issues | Within **14 days** |
| Public disclosure (coordinated) | After patch is released |

We will keep you informed at each stage and credit you in the release notes (unless you prefer to remain anonymous).

---

## Security Architecture

### Authentication & Secrets

- **JWT tokens** are issued by the FastAPI backend with a configurable expiry. Tokens are stored in `flutter_secure_storage` (iOS Keychain / Android Keystore) — **never** in `SharedPreferences` or source code.
- All secrets (database URL, JWT secret, OAuth credentials) live in `backend/.env` and are **never committed** to the repository. The `.env` file is listed in `.gitignore`.
- `.env.example` contains placeholder values only — do **not** use it with real credentials.

### Transport Security

- All production traffic is served over **HTTPS** only. The Render backend and Vercel frontend enforce TLS termination.
- CORS in production is configured with **explicit allowed origins** — the `CORS_ORIGINS=*` in `.env.example` is for local development only.

### Static Analysis & Dependency Scanning

The CI pipeline runs the following security tools on every push:

| Tool | What It Checks |
|------|---------------|
| [Bandit](https://bandit.readthedocs.io/) | Python source code for common security anti-patterns |
| [Gitleaks](https://github.com/gitleaks/gitleaks) | Secrets and credentials accidentally committed to Git history |
| [pip-audit](https://github.com/pypa/pip-audit) | Known CVEs in Python dependencies |

### Known Mitigations

| Threat | Mitigation |
|--------|-----------|
| SQL injection | SQLAlchemy ORM with parameterized queries throughout |
| Broken auth | JWT expiry + refresh token rotation |
| Race conditions (double-accept) | Database-level row locking on `service_requests` status transitions |
| Sensitive data exposure | No PII in logs; location data scoped to active sessions only |

---

## Dependency Updates

- **Dependabot / Renovate** handles automated patch-level dependency updates. Security patches are auto-merged when all CI checks pass.
- Run `pip-audit` locally to identify vulnerabilities in your local environment:
  ```bash
  pip install pip-audit
  pip-audit -r backend/requirements.txt
  ```

---

## Bug Bounty

This is an open-source prototype project and does not currently offer a formal bug bounty programme. However, meaningful security contributions are gratefully acknowledged in the `CHANGELOG.md` and project credits.
