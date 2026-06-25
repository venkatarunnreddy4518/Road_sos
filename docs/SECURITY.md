# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| 0.1.x (current) | :white_check_mark: |

---

## Reporting a Vulnerability

**Please do not open a public issue for security vulnerabilities.**

If you discover a security vulnerability in Roadside Help, please report it responsibly:

1. **Email**: teamcenturions5@gmail.com  
   Subject line: `[SECURITY] <brief description>`
2. Include the following in your report:
   - Description of the vulnerability.
   - Steps to reproduce.
   - Potential impact.
   - Suggested fix (optional).

We will acknowledge your report within **48 hours** and aim to release a fix within **7 days** for critical issues.

---

## Security Measures in Place

| Area | Control |
|------|---------|
| Authentication | JWT (HS256) with short-lived access tokens (60 min) + refresh tokens |
| Passwords | bcrypt hashing (cost factor 12) |
| Secrets | `.env` file excluded from git; `.env.example` contains no real credentials |
| Transport | HTTPS enforced in production; HTTP only for local development |
| Input validation | Pydantic models on all API endpoints |
| SQL injection | SQLAlchemy ORM with parameterised queries — no raw SQL string interpolation |
| CORS | Explicit origin allowlist in production (`CORS_ORIGINS` env var) |
| Static analysis | Bandit runs on every commit via pre-commit hooks |
| Secret scanning | Gitleaks runs on every commit via pre-commit hooks |
| Dependency audit | `pip-audit` runs in CI on every push |

---

## Known Limitations (Prototype)

- Phone OTP in the development build accepts `000000` for any number. **Do not deploy to production without real Twilio credentials.**
- Google sign-in in the development build uses a demo identity. **Configure real OAuth client IDs before any public deployment.**
- `CORS_ORIGINS=*` in `.env.example` is for local development only.

---

## Vulnerability Disclosure Timeline

1. Reporter submits vulnerability details.
2. Maintainers acknowledge within 48 hours.
3. Maintainers assess severity and begin fix.
4. Fix released and reporter notified.
5. Public disclosure after affected users have had time to update (typically 30 days).
