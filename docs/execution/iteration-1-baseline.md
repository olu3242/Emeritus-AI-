# Iteration 1 repository baseline

Recorded: 2026-08-09 (America/Chicago)

## Repository truth

- Branch: `main`, tracking `origin/main`.
- Baseline commit: `7289a42f5bbe51af5c6b987c5f8b81d3bfc85dbd` (`first commit`).
- Tracked files at baseline: `README.md` only.
- User-owned untracked files preserved: `CLAUDE.md`, `index.html`, `package.json`, `docs/`, `diagrams/`, and empty `Emeritus-AI-/`.
- The repository is a planning package. There was no application source, database schema, migration, authentication implementation, runtime API, test suite, CI, observability, curriculum model, assessment model, learner model, or design system.

## Capability classification

| Capability | Baseline | Evidence |
|---|---|---|
| Product requirements and architecture | EXISTS | `README.md`, `CLAUDE.md`, `docs/PRD.md`, diagrams |
| Web application | MISSING | no `app/`, `src/`, or Next configuration |
| Production persistence and migrations | MISSING | no `supabase/` directory |
| Authentication, roles, tenancy, authorization | MISSING | dependencies declared only |
| Curriculum/import/resolution runtime | MISSING | no source code |
| Content, assessment, learner runtime | MISSING | no source code |
| Tests and CI | MISSING | scripts declared, no tests/configuration |
| Production credentials/local services | BLOCKED until supplied/started | no environment file or reachable database established |

## Architectural decisions for Iteration 1

- PostgreSQL/Supabase is the production persistence boundary already selected by the repository manifest and PRD.
- Tenant isolation and object authorization are enforced in PostgreSQL RLS, with server services adding role checks at the use-case boundary.
- Stable public identities are strings scoped by organization/package; database UUIDs remain internal identities.
- Published versions are immutable. Replacement creates a new version and preserves historical records.
- Imports call a transactional database function using one bounded JSON batch and an idempotency key; no production memory repository exists.
- Curriculum structure is represented by typed nodes and relationships so a new conforming package does not require schema redesign.

## Evidence locations

- Baseline and ledgers: `docs/execution/`
- Forward-only migrations: `supabase/migrations/`
- Automated evidence: `artifacts/certification/` (generated, not hand-authored)
- Fixtures: `fixtures/curriculum/` (explicitly non-authoritative)

## Existing validation state

The baseline declared npm scripts whose targets did not exist. Node 24.16.0 is installed. PowerShell script execution policy blocks `.ps1` shims, so validation uses `.cmd` executables. Database certification requires a running Supabase/PostgreSQL environment and is never inferred from unit tests.
