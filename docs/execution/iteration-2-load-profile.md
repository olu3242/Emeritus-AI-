# Iteration 2 load profile

The repository harness is a deterministic smoke test, not a production-capacity certification. It runs only against a disposable database named by `TEST_DATABASE_URL` after the integration seed.

| Profile | Dataset | Concurrency | Ramp/duration | Mix | Threshold |
|---|---|---:|---|---|---|
| `small-ci` | Integration fixture | 3 workers × 20 reads | Immediate, bounded by 60 requests | Assignment/session/remediation aggregate reads | 100% success, p95 ≤ 1000 ms |

Run: `npm run test:load:small` with `TEST_DATABASE_URL` set. Output is one JSON record containing classification, concurrency, request/success counts, duration, throughput, p50/p95/p99, and thresholds.

## Authorized sustained profile package

Owner must supply an isolated staging database, monitoring, dataset, and approved SLOs. Suggested classroom-derived starting profile for owner approval—not a certified threshold—is 30 learner sessions, 30-second autosaves, a 30-submission burst, five teacher progress readers, five guardian summary readers, and mixed remediation/reassessment traffic for 30 minutes. Record database size/configuration, ramp, exact mix, success/failure/conflict counts, throughput, p50/p95/p99, locks, CPU, memory, I/O, connection use, and cleanup. The owner must approve thresholds before execution.

Sustained-load status: `Awaiting authorized environment`.

## Latest smoke evidence

Workflow `31340719340`, commit `c63121de87da25dc3284d3e9de94bdf13b9e1e31`:

- Job `93313911210`: 60 requests, zero failures, 100% success, p95 2.8 ms, 30.8 ms total.
- Job `93313911225`: 60 requests, zero failures, 100% success, p95 1.1 ms, 27.7 ms total.

Both passed the declared smoke threshold. These results remain non-certifying for production capacity.
