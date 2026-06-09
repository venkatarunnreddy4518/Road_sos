<!--
Sync Impact Report
==================
Version change: TEMPLATE → 1.0.0
Bump rationale: Initial ratification of the project constitution (first concrete version).

Modified principles: none (initial definition)
Added principles:
  - I. Test-First (NON-NEGOTIABLE)
  - II. Security by Default
  - III. Simplicity & YAGNI
  - IV. Clear Contracts & Separation of Concerns
  - V. Observability & Maintainability
Added sections:
  - Security Requirements
  - Development Workflow & Quality Gates

Templates requiring updates:
  - .specify/templates/plan-template.md ........ ✅ aligned (Constitution Check references generic gates)
  - .specify/templates/spec-template.md ........ ✅ aligned (no mandatory section conflicts)
  - .specify/templates/tasks-template.md ....... ✅ aligned (test-first task ordering supported)

Deferred TODOs: none
-->

# Web Application Constitution

## Core Principles

### I. Test-First (NON-NEGOTIABLE)
Test-Driven Development is mandatory for all feature work. Tests MUST be written and
reviewed BEFORE implementation begins, MUST fail first (Red), and only then is code
written to make them pass (Green), followed by Refactor. No production code is merged
without accompanying automated tests covering its behavior.

**Rationale**: Writing tests first forces clear thinking about requirements and behavior,
prevents regressions, and is the project's primary safety net for a web application that
will evolve over time.

### II. Security by Default
Security is the highest non-functional priority. All input MUST be validated and
sanitized; authentication and authorization MUST be enforced on every protected route and
operation; secrets MUST never be hard-coded or committed to the repository; sensitive data
MUST be encrypted in transit (HTTPS/TLS) and protected at rest. Dependencies MUST be kept
current and scanned for known vulnerabilities.

**Rationale**: A web application is exposed to untrusted users by nature. Treating security
as a default rather than an afterthought prevents the most common and most damaging classes
of breaches.

### III. Simplicity & YAGNI
Start with the simplest solution that satisfies the requirement. Do not add abstraction,
configuration, or generalization until a concrete need exists ("You Aren't Gonna Need It").
Any added complexity MUST be justified in the plan against the requirement it serves.

**Rationale**: Simple code is easier to test, secure, review, and maintain. Premature
complexity is a recurring source of bugs and slowdowns.

### IV. Clear Contracts & Separation of Concerns
Frontend, backend, and data layers MUST communicate through explicit, documented contracts
(API schemas, types, interfaces). Business logic MUST be separated from presentation and
from data-access code. A change in one layer MUST NOT require unexplained changes in another.

**Rationale**: Clear boundaries make a web app testable in isolation, allow layers to evolve
independently, and keep the codebase understandable as it grows.

### V. Observability & Maintainability
Application behavior MUST be observable: structured logging for significant events and
errors, with no sensitive data written to logs. Errors MUST surface clear, actionable
messages. Code MUST be readable and consistent with the surrounding style.

**Rationale**: You cannot fix or secure what you cannot see. Observability and readable code
keep debugging fast and onboarding cheap.

## Security Requirements

- All network traffic MUST use HTTPS/TLS; plain HTTP is permitted only for local development.
- Authentication and session management MUST follow current best practices (e.g. hashed and
  salted passwords, secure/HttpOnly cookies or signed tokens, sensible expiry).
- Authorization MUST be checked server-side for every protected action; client-side checks
  are convenience only, never the security boundary.
- Secrets and credentials MUST be supplied via environment variables or a secrets manager and
  MUST be listed in `.gitignore`-protected files, never committed.
- All external input (request bodies, query params, headers, uploads) MUST be validated and
  encoded/escaped to prevent injection (SQL, XSS, command, etc.).
- Dependencies MUST be reviewed before adding and periodically audited for vulnerabilities.

## Development Workflow & Quality Gates

- Each feature follows the Spec Kit flow: specify → clarify → plan → tasks → implement.
- The Test-First principle gates implementation: failing tests exist before code is written.
- Every change MUST pass the full automated test suite before being merged.
- Changes MUST be reviewed (self-review at minimum for solo work) against this constitution,
  with particular attention to the Security Requirements above.
- Complexity introduced in a plan MUST be explicitly justified; unjustified complexity is a
  blocking review finding.

## Governance

This constitution supersedes other practices where they conflict. Amendments MUST be made by
editing this file, accompanied by a version bump and a Sync Impact Report describing the
change and its propagation to dependent templates.

Versioning policy (semantic versioning):
- **MAJOR**: Backward-incompatible governance changes or removal/redefinition of a principle.
- **MINOR**: A new principle or section is added, or guidance is materially expanded.
- **PATCH**: Clarifications, wording, or non-semantic refinements.

All work MUST be verifiable against these principles. Reviews and pull requests MUST confirm
compliance, and any deviation MUST be documented and justified.

**Version**: 1.0.0 | **Ratified**: 2026-06-09 | **Last Amended**: 2026-06-09
