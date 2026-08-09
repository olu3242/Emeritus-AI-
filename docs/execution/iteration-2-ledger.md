# Iteration 2 execution ledger

Entry gate: Iteration 1 certified by PostgreSQL run `31335448796` on commit `8f7e995`.

| Requirement | Status | Repository evidence | Certification evidence |
|---|---|---|---|
| Versioned lessons and assessments | PostgreSQL-backed | Migration `20260809160000`; immutable version references in sessions/attempts | Run `31337024669` passed twice |
| Classes, enrollment, guardian authorization | RLS-validated | Tenant-scoped tables, atomic guardian predicate, denied unrelated user | 9/9 live cases passed twice |
| Assignment and resumable session | E2E-validated | `start_learning_session`, idempotent unique keys | Persisted session proven twice |
| Protected scoring | E2E-validated | Item table revoked from authenticated roles; `submit_assessment` server function | Correct score, replay, and answer-key denial passed twice |
| Deterministic mastery | E2E-validated | `src/learning/mastery.ts`; persisted decision and recommendation | 11/11 unit and 9/9 live cases passed twice |
| Remediation/enrichment | E2E-validated (rule slice) | Persisted recommendation derived from mastery ratio | Enrichment path passed twice; broader remediation journey outstanding |
| Complete persisted vertical slice | E2E-validated | Learner, teacher-owned assignment, guardian, scoring, mastery, audit | Jobs `93304457681`, `93304457697` succeeded |
| Accessibility UI journeys | Not started | No operational lesson player yet | Blocks certification |
| Human rubric scoring and teacher override | Not started | Not in first slice | Blocks certification |

## Live evidence

- Commit: `16f7f90d2d7d1f14ee16bf177192062d4dd587c2`.
- Workflow: `31337024669`.
- PostgreSQL jobs: `93304457681`, `93304457697`, both successful with cleanup.
- Per job: 7/7 migrations, 9/9 live cases, 11/11 unit tests, typecheck, lint, and build.
- Failed predecessor runs remain preserved and led to migration syntax, scoring-name, and guardian-RLS fixes without weakening assertions.

Current verdict: `ITERATION 2 PARTIALLY IMPLEMENTED — LISTED REQUIREMENTS REMAIN`

Iteration 3 remains blocked until the full Iteration 2 exit gate passes.
