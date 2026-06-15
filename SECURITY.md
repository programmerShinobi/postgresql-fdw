# Security Policy

## Reporting a vulnerability

**Please do not open a public issue for security vulnerabilities.**

Instead, use GitHub's private reporting:
**Security → Advisories → “Report a vulnerability”** on this repository. This
keeps the details private until a fix is available.

When reporting, please include:

- A description of the issue and its impact
- Steps to reproduce (a minimal example helps)
- Affected version/commit and your environment

We aim to acknowledge reports within a few days and will keep you updated on the
fix and disclosure timeline.

## Scope

This repository ships **development tooling** (a Dockerized PostgreSQL setup),
not a hosted service. Relevant concerns include:

- Default configuration that could expose data unintentionally
- The build pipeline / image supply chain (pinned tags, source builds)
- The pre-commit secret guard failing to catch a documented secret pattern

For hardening guidance and the secret-management standard this project follows,
see [docs/10-SECURITY.md](docs/10-SECURITY.md).

## Good hygiene for users

- Never commit `.env` / `.env.source`; only the `*.example` templates are tracked.
- Install the secret guard: `make hooks`.
- Rotate any credential that has been exposed (including remote FDW logins).
- Don't publish the database port on untrusted networks.
