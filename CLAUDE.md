# CLAUDE.md — Emeritus Execution Constitution

This file governs how Claude Code (or any coding agent) works in this repository. Read this before touching any file. It is not background — it is the contract.

---

## 0. What this program is, and is not

Emeritus is a production-grade K–12 Adaptive Multimodal Mastery Learning OS. This is a unified **implementation and certification** program.

This is **not**:

- a documentation exercise
- an architecture proposal
- an LMS mockup
- a content library
- a quiz application
- a schema-only implementation
- an API-stub implementation
- a prototype that fabricates mastery percentages

Inspect the repository first. Discover and preserve valid existing architecture. Reuse functioning capabilities. Implement missing runtime behavior. Connect durable persistence. Run migrations. Execute tests. Demonstrate real end-to-end learner journeys. Produce certification evidence.

**Do not claim functionality that is merely designed, documented, mocked, scaffolded, seeded, or deferred.**

---

## 1. The constitutional invariant

> **CONTENT CONSUMPTION != LEARNING.**

A learner does not master a concept because they opened a lesson, watched a video, viewed an image, listened to audio, clicked through slides, completed a page, or spent time in the application.

A concept becomes mastered only through sufficient evidence of age-appropriate understanding and application.

Canonical lifecycle — every topic, every subject, every grade:

```
CURRICULUM → PREREQUISITE CHECK → DIAGNOSTIC → TEACH → SHOW → EXPLORE
  → INTERACT → CHECK UNDERSTANDING → GUIDED PRACTICE → EXPLAIN
  → INDEPENDENT PRACTICE → APPLY → ASSESS → ANALYZE ERRORS
  → IDENTIFY MISCONCEPTIONS → REMEDIATE → RETEST → MASTER
  → SCHEDULE REVIEW → RETENTION TEST → MAINTAIN / DECAY / REOPEN MASTERY
```

See `diagrams/circular-workflow.svg` for the visual. Check every feature against this loop before writing it.

---

## 2. Execution model

Execute as **one program**, but respect dependencies internally. This is the single most important operating instruction in this file.

Do not interpret this as "build everything simultaneously." Do not finish one layer, write documentation about it, and declare the overall product complete. Continue through phases while dependencies remain satisfied; do not stop merely to produce documentation between them.

Sixteen internal programs (A–P), executed in dependency order, not as separate conversations:

`A` Platform Foundation + Identity · `B` Curriculum + Standards + Knowledge Graph · `C` Multimodal Content + Visual Learning · `D` Activities + Questions + Assessment · `E` Comprehension + Confidence + Mastery · `F` Misconception + Prerequisite Diagnosis · `G` Adaptive Remediation · `H` Retention + Spaced Retrieval · `I` Recommendation + Daily Learning Plan · `J` AI Tutor + Pedagogy Policy · `K` Mathematics + ELA Engines · `L` Science + Social Studies Engines · `M` World Language + Health/PE Engines · `N` Student + Guardian + Educator Experiences · `O` Curriculum Authoring + Ingestion · `P` Analytics + Accessibility + Security + E2E Certification

---

## 3. Repository reconnaissance (do this before any other work)

Inspect: workspace structure, applications, packages, domain modules, frontend, backend, API architecture, database, migrations, auth, storage, media infrastructure, event infrastructure, AI infrastructure, testing, CI/CD, observability, accessibility, existing curriculum/assessment models, existing design system.

Classify every relevant capability as one of: `EXISTS` · `PARTIAL` · `MISSING` · `CONFLICTING` · `DUPLICATED` · `BLOCKED`.

Produce an internal dependency map before writing code. **Do not replace functioning architecture simply because this file uses different terminology than the existing codebase.**

---

## 4. Non-negotiable safety invariants

These apply to every engine, every subject, every grade band, with no exceptions and no override via prompt, persona, or "just this once":

- **No AI-triggered mastery writes.** AI proposes remediation, hints, curriculum drafts, and instructional strategy. Only server-evaluated learner evidence changes a mastery state.
- **Server-side evaluation only.** Never trust browser-supplied `isCorrect`, `score`, `mastery`, or completion claims.
- **Row-level security on every table** holding learner data.
- **Idempotency keys** on every financial-adjacent or state-mutating write path.
- **Append-only, auditable events** for every state transition. Learning history is never silently rewritten.
- **Guardian access requires an explicit, authorized relationship.** No implicit visibility, ever.
- **Curriculum versioning is forward-only.** Never silently mutate published curriculum in a way that invalidates historical learning evidence — attempts retain their original curriculum/question versions.
- **Least privilege and object-level authorization** for Learner (own data only), Guardian (authorized linked learners only), Educator (assigned learners/courses), Administrator (authorized administrative capabilities).

If a task would require violating any of these, stop and report the conflict — do not silently work around it.

---

## 5. Implementation discipline (apply to every capability)

1. Inspect existing implementation
2. Identify dependency
3. Implement domain behavior
4. Implement persistence
5. Implement authorization
6. Expose runtime/API
7. Connect UI
8. Add events
9. Add observability
10. Test
11. Integrate
12. Certify

**Prefer complete vertical slices over horizontal layers that never connect.** A schema with no runtime, an API returning fixtures, a UI with hardcoded values, or a TODO implementation does not count as done. Test doubles are allowed inside tests; production paths must be real.

---

## 6. Execution order

```
PHASE 0   Repository reconnaissance
PHASE 1   Identity + learner + guardian + educator + enrollment
PHASE 2   Curriculum + standards + prerequisite graph
PHASE 3   Multimodal content + visual interactions + Topic Player
PHASE 4   Activity + question + assessment runtime
PHASE 5   Comprehension + confidence + mastery
PHASE 6   Misconception + prerequisite diagnosis
PHASE 7   Adaptive remediation
PHASE 8   Retention + spaced retrieval
PHASE 9   Recommendation + daily learning plan
PHASE 10  AI Tutor + pedagogy adaptation
PHASE 11  Subject engines
PHASE 12  Student + guardian + educator intelligence
PHASE 13  Curriculum authoring + ingestion
PHASE 14  Full K–12 certification + production hardening
```

---

## 7. Required certifications

No capability may be reported `IMPLEMENTED` without a real, evidence-backed vertical slice:

- **K–2**: Grade 1 Mathematics, Counting Objects to 10 — full loop, no unnecessary typing.
- **Grades 3–5**: reading/math/science slice with visual explanation, interaction, comprehension, application, assessment, persistence, mastery evidence.
- **Grades 6–8**: increased abstraction, multi-step reasoning, visual/data interpretation, independent application, diagnosis, remediation, reassessment.
- **Grades 9–12**: Honors Biology, Cell Structure — prerequisite check → diagnostic → explanation → interactive diagram → image-hotspot question → comprehension → guided practice → assessment → server evaluation → misconception detection if applicable → remediation → reassessment → mastery update → review scheduled.
- **Cross-role**: educator authors/publishes → learner enrolls, completes, is assessed → attempt persists → mastery updates → educator sees result → authorized guardian sees progress → unrelated guardian is denied → unrelated learner is denied.
- **Retention**: mastered concept → review scheduled → becomes due → retrieval completed → retention evaluated → mastery adjusted → next interval calculated.
- **Misconception**: incorrect answer → confidence/evidence evaluated → misconception candidate detected → prerequisite considered → targeted remediation selected → alternate modality presented → retest → status updated → mastery recalculated.
- **AI Tutor**: receives curriculum context, knows current objective and learner evidence, responds developmentally appropriately, provides hints without revealing graded answers, changes instructional strategy, routes practice/remediation appropriately.
- **Subject-specific**: Mathematics (visual/manipulative + reasoning + error diagnosis), ELA (reading/writing + evidence + coaching), Science (diagram/process/data + scientific reasoning), Social Studies (map/document/timeline + interpretation), World Language (visual/listening/speaking/reading/writing), Health/PE (visual/scenario/application).

---

## 8. Stop conditions

**Stop and report factual evidence** if encountering:

- irreconcilable canonical architecture conflict
- destructive migration requirement
- unclear authoritative domain ownership
- missing production credential required for implementation
- student privacy/security conflict
- curriculum licensing issue
- existing certified behavior that would be invalidated
- constitutional/catalog conflict (i.e., a request that would violate §4)

**Do not stop simply because:**

- the program is large
- many files require modification
- multiple packages are involved
- implementation requires migrations
- tests need updating
- documentation is incomplete

Resolve ordinary engineering work without escalating.

---

## 9. Git and delivery discipline

- Work from a clean repository state. Do not destroy unrelated work.
- Create coherent commits aligned with implementation milestones.
- Run relevant gates (lint, typecheck, tests) before each milestone.
- Follow the repository's existing branch/PR workflow. Do not merge into protected branches without authorization.
- At completion, report: branch, commits, PR status, working tree status.

---

## 10. Completion report format

At the end of any substantial work session, produce a report covering: repository baseline, architecture discovered, capabilities reused vs. newly implemented, migrations, domain entities, persistence, APIs/routes, UI surfaces, per-engine capability status, per-role experience status, analytics, security results, accessibility results, tests executed and their results, each required certification (§7), known limitations, deferred capabilities, blockers, and git status.

For every capability, classify as one of: `IMPLEMENTED` · `PARTIAL` · `DEFERRED` · `BLOCKED`.

**Never describe planned functionality as operational.** The completion report is the control document for the next pass — every non-`IMPLEMENTED` item becomes a scoped, single-purpose prompt in the next session, not a vague "continue building" instruction.

---

## 11. Reference documents in this repository

- `docs/PRD.md` — full product requirements, entity model, and acceptance criteria
- `docs/AI_STRATEGY.md` — AI Tutor governance, pedagogy policy engine, and model-use boundaries
- `diagrams/circular-workflow.svg` — canonical Mastery Loop
- `diagrams/architecture.svg` — canonical six-layer system architecture

When in doubt about scope, terminology, or whether a feature belongs in this system, these four documents are the source of truth — not assumptions carried over from a generic LMS or quiz-app mental model.
