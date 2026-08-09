# Iteration 2 role-application evidence

## Guardian

`/guardian` calls the allowlisted `guardian_dashboard` RPC with the caller bearer token. The service derives the guardian from `auth.uid()`, lists only active relationships, rejects forged or revoked learner identifiers, and returns assignment/session progress, calculated/effective mastery, approved recommendations, remediation/reassessment state, enrichment, and guardian-visible guidance. It does not select responses, answer keys, scoring rules, rubric criteria, grader identity, internal notes, audit data, or outbox data.

## Administrator

`/administrator` calls `administrator_dashboard`. The browser supplies no tenant identifier; the RPC derives one active administrator membership from `auth.uid()`, bounds results to 1–100, and returns operational counts, class/enrollment summaries, assignment windows, scoring/override/recommendation status, failure counts, and audit metadata without audit data or outbox payloads. An administrator in another organization receives only that organization.

## Automated boundary

PostgreSQL tests validate authorized guardian/admin results, forged learner denial, immediate guardian revocation, other-tenant isolation, role denial, bounds, and protected-field absence. Browser tests validate routes, loading/error/session-clear states, unauthenticated API denial, mobile reflow, accessible names/status, axe checks, and protected technical-field absence. CI does not impersonate a human or constitute external usability validation.

## Formatting disposition

The repository has ESLint and TypeScript checks but no Prettier/Biome configuration or native formatting command. No broad formatter or mechanical rewrite was introduced during terminal closure. `git diff --check` passes; formatting remains a non-certification governance/tooling gap rather than a reported formatter pass.

## Upgrade migration disposition

`npm run test:migration:upgrade` creates a disposable localhost database, applies committed migrations 1–11, seeds an administrator membership, applies only migration 12, verifies preserved data/default status and both role-dashboard functions, then terminates connections and drops the database. This is a committed-history upgrade test, not a fabricated production snapshot.
