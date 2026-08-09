# Iteration 1 execution ledger

## Implemented

- Neutral, versioned curriculum domain migration with organizations, authorities, jurisdictions, packages, versions, typed nodes, relationships, provenance, overlays, reviews, imports, coverage snapshots, certifications, and append-only audit events.
- Tenant isolation and role-aware RLS. Learner/guardian/educator policies expose published curriculum only.
- Transactional JSON import RPC with bounded documents, deterministic digest, idempotency-key replay, immutable published history, and audit evidence.
- Workflow transition RPC with ordered states and optimistic concurrency.
- JSON and CSV validation, configurable terminology/progression adapters, pagination, deterministic non-mutating overlay resolution, and explicit-denominator coverage RPC.
- Non-authoritative US-structure and structurally different interoperability fixtures, labeled so they cannot be mistaken for verified curriculum.

## Evidence

- `npm.cmd test`: 6 tests passed.
- `npm.cmd run typecheck`: passed.
- Migration files exist but have **not** been applied to a live database in this environment.

## Certification continuation (2026-08-09)

| Requirement | Previous | Current | Repository/test evidence | Blocker / owner action | Iteration 2 impact |
|---|---|---|---|---|---|
| Disposable database environment | Blocked | Blocked | Supabase `config.toml` and guarded migration harness added; Docker Desktop reports `unable to start`; no `TEST_DATABASE_URL` is present | Environment owner: repair/start Docker Desktop, or supply a dedicated test URL via `TEST_DATABASE_URL` | Blocks entry |
| Migration application | Not started | Blocked | Four ordered forward migrations and `npm run db:test:migrate` exist | Apply to clean Supabase/Postgres after database target is available | Blocks entry |
| PostgreSQL/RLS tests | Not started | Implemented, not validated | Four database-backed permitted/denied/rollback/schema tests in `tests/integration`; command deliberately exits 2 without a safe target | Run migration then `npm run test:integration` | Blocks entry |
| Role separation | Partial | Implemented, not validated | Author/platform roles, self-approval denial, workflow state enforcement, audit record RPC | Requires live direct-database RLS execution | Blocks entry |
| Unit compatibility | Validated | Validated | `npm test`: 8 passed | None | No |
| Type safety | Validated | Validated | `npm run typecheck`: exit 0 | None | No |
| Lint | Missing | Validated | ESLint 9 flat config; `npm run lint`: exit 0 after remediation | None | No |
| Production build | Missing | Validated | Minimal truthful Next entry surface; `npm run build`: exit 0 | None | No |
| Dependency advisories | Unassessed | In progress | PostCSS and tar patched compatibly; remaining Next/sharp and Vitest/Vite findings documented in `iteration-1-advisories.md` | Engineering owner: compatibility-test supported major upgrades | Audit gate not passed |
| Docker-free certification path | Not started | Implemented, execution blocked | PostgreSQL 15 CI service workflow, five-migration history verification, Supabase-compatible test bootstrap, and eight live cases prepared | Repository owner: commit/review and dispatch workflow, or supply disposable `TEST_DATABASE_URL` | Blocks entry until executed successfully |

## Unmet exit-gate items

- Docker daemon is unavailable; local Supabase cannot start, so migrations, RLS, transaction/idempotency integration, and production runtime resolution are not certified.
- No verified authoritative US curriculum source or license inventory was supplied. Synthetic fixtures cannot satisfy population requirements.
- No operational web administration UI exists; the repository-appropriate service/RPC surface exists and the build has a truthful status surface only.
- Migration, integration, security, E2E, and regression suites against Postgres remain incomplete.
- Dependency audit completed. Compatible PostCSS/tar overrides were applied; supported fixes for remaining findings require separately reviewed major upgrades.

## Verdict

`ITERATION 1 PARTIALLY IMPLEMENTED — LISTED BLOCKERS REMAIN`

Iteration 2 was not started.
