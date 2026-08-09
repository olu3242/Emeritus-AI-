# Iteration 1 recovery and provisioning report

Recorded: 2026-08-09 (America/Chicago)

## Repository state

- Starting/ending branch: `main`, tracking `origin/main`.
- Starting/ending commit: `7289a42f5bbe51af5c6b987c5f8b81d3bfc85dbd`.
- Existing user work preserved; no commit, push, deployment, provider creation, or external-service modification occurred.
- One forward migration was added for authenticated table/sequence grants. Existing migration files were not changed during this recovery pass.

## Provisioning candidates

| Candidate | Result | Safety/isolation |
|---|---|---|
| Existing configured disposable URL | Unavailable | No recognized database variable exists |
| Local Supabase/Docker | Unavailable | Docker service stopped and Desktop previously reported unable to start |
| Local PostgreSQL | Unavailable | No service, server, client, or listener |
| WSL PostgreSQL | Unavailable | WSL enumeration denied |
| Remote provider | Rejected | Not authorized; no credential or ownership/cleanup evidence |
| GitHub Actions PostgreSQL 15 service | Prepared, not executed | Fresh job-local `*_test` database, trust auth only inside isolated runner, two independent matrix jobs |

## Harness result

- Explicit live opt-in remains `TEST_DATABASE_URL`; absent configuration fails closed.
- Target guard accepts localhost or a database name containing `test` and rejects unidentified remote targets.
- Optional `TEST_DATABASE_BOOTSTRAP=supabase-compatible` creates test-only auth roles, `auth.users`, and `auth.uid()` semantics for plain PostgreSQL.
- Migration runner applies six ordered migrations, records exact identifiers, refuses reapplication, and verifies history count. Migration six is the forward-only audit insert-policy repair exposed consistently by both jobs in failed run `31335286584`.
- CI matrix provisions two fresh PostgreSQL 15 environments to test reproducibility without cross-run contamination.
- Eight live tests are prepared: allowed/cross-tenant reads, unauthorized import, cross-tenant insert/update/delete denial, rollback, schema/index/RLS checks, committed idempotent import with audit evidence, and idempotency conflict rejection.
- Workflow syntax is not execution evidence. Zero live tests ran in this environment.

## Non-live validation

| Command | Exit | Count/result |
|---|---:|---|
| `npm.cmd run typecheck` | 0 | PASS |
| `npm.cmd test` | 0 | 8 passed, 0 failed |
| `npm.cmd run lint` | 0 | PASS |
| `npm.cmd run build` | 0 | PASS, Next 15.5.23 |
| `git diff --check` | 0 | PASS |
| `npm.cmd run db:test:migrate` | nonzero | BLOCKED: `TEST_DATABASE_URL` required |
| `npm.cmd run test:integration` | nonzero | BLOCKED: `TEST_DATABASE_URL` required; 0/8 live tests executed |

## Migration manifest

Initial expected set: five migrations, ordered `20260809150000` through `20260809154000`; both CI jobs applied these successfully in run `31335286584`. The live tests exposed a missing authorized audit insert policy, now repaired by forward migration `20260809155000`. Current expected set: six. Replacement clean-run evidence remains pending.

## Credential safety

- No real connection string, password, token, or service-role value was added.
- CI uses no database password and scopes trust authentication to its isolated service container.
- `.env.example` contains placeholders only and remains non-secret documentation.
- No runtime credential values were present in the environment or printed.

## Required owner action

The repository/environment owner must either run the prepared GitHub Actions workflow after normal commit/review, or securely provide a positively identified disposable `TEST_DATABASE_URL` and run the migration and integration commands documented in `disposable-database-handoff.md`. Retain command logs and both clean-run results; destroy or rotate temporary access afterward.

## Downstream state

- Iteration 1: not certified.
- Iteration 2: may not begin.
- Iteration 3: blocked on certified Iterations 1 and 2.
- Iteration 4: blocked on certified Iterations 1–3.

## Verdict

`BLOCKED — ENVIRONMENT-OWNER DATABASE PROVISIONING REQUIRED`
