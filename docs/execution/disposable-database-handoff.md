# Disposable PostgreSQL certification handoff

## Candidate evaluation

| Candidate | Availability | Decision |
|---|---|---|
| Configured disposable URL | No recognized variable present | Unavailable |
| Local Supabase | Config exists; Docker engine unavailable | Blocked |
| Repository test container | Docker unavailable locally | Blocked |
| GitHub Actions PostgreSQL service | Executed successfully in run `31335448796` | Selected and certified |
| Local PostgreSQL | No service, server, client, or listener found | Unavailable |
| WSL PostgreSQL | WSL distribution enumeration denied | Unavailable |
| New remote provider | Not authorized and no credentials supplied | Rejected |

The selected CI path uses a fresh PostgreSQL 15 service for each of two independent matrix jobs. Its database name contains `test`; the job-local container uses trust authentication on the isolated GitHub runner and stores no password. A test-only bootstrap provides Supabase-compatible roles, `auth.users`, and `auth.uid()` semantics before the production migration set is applied.

## Completed handoff

The feature branch was pushed and the workflow executed without merging into `main`. Both independent jobs passed and cleaned up.

## Reproduction options

Choose one:

1. Commit/push the prepared repository work through the normal review process, then manually run **Iteration 1 database certification**. Do not treat workflow syntax as execution evidence; retain both matrix-job results.
2. Provision PostgreSQL 15+ (Supabase-compatible or with the test bootstrap), positively confirm it is disposable, set `TEST_DATABASE_URL` securely, set `TEST_DATABASE_BOOTSTRAP=supabase-compatible` only for plain PostgreSQL, and run:

   `npm.cmd run db:test:migrate`

   `npm.cmd run test:integration`

The URL must use `postgresql://.../<database>` and the database name must contain `test` unless the host is `localhost`/`127.0.0.1`. Required privileges are database/schema creation and ownership-level DDL for the isolated database, including `pgcrypto`, roles, functions, triggers, policies, and RLS. Never target production or a shared development database. Rotate or destroy temporary credentials after the run; the environment owner owns cleanup.

Expected successful evidence is six recorded migrations, all database-backed integration/RLS tests passing in both clean jobs, green non-live regression/build gates, and no secret values in logs or artifacts. The sixth migration is the forward-only repair for the audit-event insert policy exposed by failed run `31335286584`.
