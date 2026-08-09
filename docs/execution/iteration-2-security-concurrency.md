# Iteration 2 security, concurrency, and load evidence

## Automated coverage

The clean PostgreSQL suite exercises authorized and denied tenant membership, cross-tenant writes, cross-tenant update/delete enumeration behavior, privileged curriculum import, protected answer-key reads, unrelated score reads, guardian authorization, unauthorized grading, teacher-only override/recommendation/remediation actions, remediation RLS, optimistic session and remediation locks, idempotent submissions, scoring replay, and exactly-once score/mastery records.

The application gateway requires a bearer credential, exposes only an explicit RPC allowlist, returns generic authorization errors, and never accepts an authoritative score or mastery value for persistence.

## Certification-environment thresholds

These are correctness thresholds for the constrained two-job CI environment, not production-capacity claims:

| Profile | Dataset/concurrency | Threshold | Evidence status |
|---|---|---|---|
| Duplicate final submission | Two/replayed calls for one idempotency key | One authoritative score and one mastery contribution | Automated PostgreSQL scenario |
| Stale autosave | Current and stale lock versions | Current write succeeds; stale write returns serialization conflict | Automated PostgreSQL scenario |
| Remediation replay | Repeated reassessment submission | One score and one mastery decision per scoring/policy version | Automated PostgreSQL scenario |
| Independent clean execution | Two PostgreSQL 15 jobs | Both apply all migrations and pass all required tests | Pending candidate CI |

## Unexecuted load profiles

No sustained virtual-user test, mixed autosave/scoring traffic profile, database resource observation, latency-percentile run, outbox-worker restart test, or production-sized dataset test was executed. Tool/version, virtual users, duration, throughput, p50/p95/p99 latency, database resource use, and production-like limits therefore remain `Blocked` pending an authorized load environment and agreed operational targets.

The repository evidence supports transactional correctness under tested replay/conflict cases only. It does not support a production-scale or capacity claim.

Terminal run `31340719340` passed 15/15 PostgreSQL tests independently in jobs `93313911210` and `93313911225`. Added cases cover cross-tenant and same-tenant filtered reads, administrator tenant isolation, answer/rubric/outbox protection, direct mutation filtering, expired assignments, withdrawn enrollment, guardian revocation, internal-note isolation, concurrent session convergence, stale/replay invariants, and bounded response payloads. Enforcement spans authentication context, RLS, function authorization, domain windows, database uniqueness, idempotency, and optimistic locking.

## Dependency audit

The complete lockfile audit reports two high-severity inherited `sharp`/libvips findings. The production-reachability audit passed in both terminal jobs after server image optimization was disabled and repository search proved no image-processing path. Because `sharp` remains installed, the disposition is `Temporarily mitigated with accepted residual risk required`; no acceptance has been fabricated. See `iteration-2-dependency-security.md`.
