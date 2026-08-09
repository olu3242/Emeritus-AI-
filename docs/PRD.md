# Emeritus — Product Requirements Document

**Version:** 1.0
**Owner:** Zenith AI Automation Agency
**Status:** Planning → Phase 0 (Repository Reconnaissance)
**Related:** `../CLAUDE.md`, `AI_STRATEGY.md`, `../diagrams/circular-workflow.svg`, `../diagrams/architecture.svg`

---

## 1. Problem statement

Most K–12 learning software optimizes for content delivery and engagement, not for evidence of understanding. A learner can complete a course — every video watched, every page scrolled — without the platform ever confirming they can actually apply the concept. School grades, which blend completion, participation, and assessment, further obscure the gap between *what a learner appears to know* and *what a learner can demonstrably do*.

This produces three compounding failures:

1. **False readiness.** Learners advance to dependent concepts (fractions before division is solid, algebra before arithmetic is fluent) without the prerequisite actually being mastered, and the system has no mechanism to notice.
2. **Undiagnosed misconceptions.** A wrong answer is treated as "incorrect" rather than as evidence of a specific, addressable misunderstanding — so remediation, when it exists, repeats the same failed instructional strategy.
3. **Illusory retention.** Mastery is measured once and assumed permanent. There is no mechanism to notice that a concept mastered in October is gone by February.

Emeritus is built to close all three gaps with one shared runtime, rather than three separate point solutions.

---

## 2. Product vision

A single adaptive multimodal mastery learning operating system, covering Kindergarten through Grade 12, in which:

- Every concept has a defined, demonstrable learning objective.
- Every learner interaction produces evidence, not just a completion flag.
- Every mastery state is backed by server-evaluated evidence and decays without reinforcement.
- Every subject and every grade band shares the same curriculum graph, mastery engine, and evidence discipline — while pedagogy, modality, and interaction design adapt to developmental stage.
- Students, educators, and guardians see the same underlying evidence, shaped for what each of them needs to act on.

---

## 3. Goals and non-goals

### Goals

- Ship a production-grade mastery runtime — not a documentation exercise, prototype, or mockup.
- Certify real end-to-end learner journeys across all four grade bands (K–2, 3–5, 6–8, 9–12).
- Certify seven initial high-school courses on the shared runtime.
- Enforce the constitutional invariant (content consumption != learning) as an architectural constraint, not a marketing claim.
- Keep AI strictly advisory in every money-adjacent, grade-adjacent, or mastery-adjacent decision path.

### Non-goals (v1)

- Replacing a school's system of record (SIS) — Emeritus integrates via enrollment data, it does not become the enrollment authority.
- District-wide procurement workflows — v1 targets single-school and single-course pilots.
- Full curriculum authoring UI for non-technical authors — v1 supports governed authoring by curriculum specialists, not open community contribution.
- Real-time collaborative classroom tools (live polls, shared whiteboards) — out of scope; Emeritus is asynchronous mastery infrastructure first.

---

## 4. Users and roles

| Role | Primary need | Key surfaces |
|---|---|---|
| **Learner** | Know what to learn today, and prove they understand it | Student Home, Topic Player, Knowledge Map, AI Tutor |
| **Guardian** | Know if their child is actually keeping up | Guardian dashboard (readiness, gaps, retention risk) |
| **Educator** | Know where the class stands, and where to intervene | Class overview, heatmaps, authoring, assessment tools |
| **Administrator** | Govern access, standards frameworks, and rollout scope | Admin console (out of primary v1 UI scope, API-first) |

Multi-role relationships are explicitly supported (an educator may also be a guardian; a district may have zero schools defined for a single-site pilot). Enrollment governs course visibility. Guardian access requires an explicit, authorized relationship — never implicit.

---

## 5. Core domain model

### 5.1 Curriculum graph

```
EducationSystem → Jurisdiction → StandardsFramework → GradeBand → Grade
  → Subject → Course → Unit → Topic → Concept → Skill
  → LearningObjective → LearningEvidence
```

Not every deployment uses every level — the graph is navigable at whatever depth a given course actually needs.

### 5.2 Prerequisite graph

Directed, acyclic relationships between concepts, skills, and objectives, which may cross topics, units, courses, grades, and academic years. Must support traversal in both directions: *what does this require* and *what depends on this*. Used directly by the Misconception & Prerequisite Diagnosis engine.

### 5.3 Mastery state machine

```
NEW → LEARNING → DEVELOPING → PROFICIENT → MASTERED → RETAINED
                                                  ↓            ↑
                                          REVIEW_DUE ──────────┘
                                                  ↓
                                            AT_RISK → REMEDIATION_REQUIRED
```

Every transition requires evidence. No transition is time-based alone.

### 5.4 Assessment and evaluation

`Assessment → AssessmentSection → AssessmentItem → AssessmentAttempt → QuestionAttempt → StudentResponse`

Assessment purposes: `DIAGNOSTIC` · `FORMATIVE` · `PRACTICE` · `SUMMATIVE` · `RETENTION`. Attempts persist across refresh and relogin. All objective grading happens server-side; client-supplied correctness is never trusted.

### 5.5 Misconception

A first-class entity, not a byproduct of a wrong answer:

```
concept · misconception description · evidence pattern · severity · confidence
  · possible prerequisite · remediation strategies · reassessment requirements
```

Differentiated from: knowledge gap, procedural error, misreading, prerequisite gap, careless error, language difficulty, insufficient evidence. Not every wrong answer is classified as a misconception.

---

## 6. Functional requirements by engine

### 6.1 Pedagogy Policy Engine

Determines language complexity, instruction length, visual density, interaction type, practice type, assessment type, feedback style, and scaffolding — as a function of grade, grade band, subject, concept, prerequisites, current mastery, recent performance, active misconceptions, confidence, assistance history, available modality, and accessibility configuration. **Not** a font-size toggle or an "ask an LLM to simplify this" shim.

### 6.2 Multimodal Content

Every topic defines a multimodal strategy. Supported asset types: `TEXT · IMAGE · ILLUSTRATION · DIAGRAM · CHART · GRAPH · MAP · TIMELINE · AUDIO · VIDEO · ANIMATION · SIMULATION · INTERACTIVE · DOCUMENT · WORKED_EXAMPLE · STORY · MANIPULATIVE`. Each asset declares pedagogical purpose (`INTRODUCTION · EXPLANATION · VISUALIZATION · EXAMPLE · EXPLORATION · PRACTICE · ASSESSMENT · REMEDIATION · REFERENCE`). Visual interaction types (`IMAGE_HOTSPOT`, `IMAGE_LABELING`, `GRAPH_INTERPRETATION`, `MAP_INTERPRETATION`, etc.) must grade through trusted server-side logic, not client assertions.

### 6.3 Comprehension Engine

Models understanding across `RECOGNITION → RECALL → UNDERSTANDING → APPLICATION → ANALYSIS → REASONING → TRANSFER`. A learner cannot reach high mastery through recall questions alone. Evidence type is developmentally appropriate: pointing, matching, sorting, and speaking for a young learner; explanation, calculation, analysis, and modeling for an older one.

### 6.4 Confidence Engine

Where developmentally appropriate, captures confidence alongside correctness:

| Correctness | Confidence | Interpretation |
|---|---|---|
| Correct | High | Strong evidence |
| Correct | Low | Fragile understanding |
| Incorrect | Low | Likely knowledge gap |
| Incorrect | High | Probable misconception |

### 6.5 Mastery Engine

Mastery is computed independently at skill, concept, objective, standard, topic, unit, course, and subject level, from configurable-weighted evidence across recognition, recall, understanding, application, analysis, reasoning, transfer, retention, and confidence calibration. **Never** computed from lesson completion or school grade. School grade, demonstrated mastery, retention, and readiness are allowed to diverge and are reported separately.

### 6.6 Misconception & Prerequisite Diagnosis

On weak performance: inspect current concept → inspect evidence → inspect prerequisite graph → identify likely prerequisite weakness → validate where possible → route the learner appropriately. Does not endlessly repeat the current lesson when the actual gap is upstream.

### 6.7 Adaptive Remediation Engine

Changes instructional strategy on repeated struggle, in order: text explanation → visual explanation → interactive model → concrete analogy → worked example → guided practice → prerequisite diagnosis → (once repaired) return to concept → reassessment → mastery recalculation.

### 6.8 Retention Engine

Configurable spaced retrieval (1 / 3 / 7 / 14 / 30 / 60 / 90 days by default, adjusted from learner evidence). Previously mastered concepts may become `REVIEW_DUE`, `AT_RISK`, or `REMEDIATION_REQUIRED`. Retention performance updates mastery confidence, not just a review-completed flag.

### 6.9 Daily Learning Orchestrator

Generates a prioritized daily plan from weak mastery, active misconceptions, prerequisite gaps, retention due dates, assignments, upcoming tests, exam proximity, teacher priorities, recent performance, learning velocity, and available study time. The learner should not need to manually sequence their own study plan.

### 6.10 AI Tutor

See `AI_STRATEGY.md` for full governance detail. Context includes grade, course, unit, topic, objective, standards, current mastery, prerequisites, recent responses, active misconceptions, remediation history, available assets, and assistance history. Modes: `TEACH · EXPLAIN · SHOW · SOCRATIC · HINT · GUIDED_PRACTICE · QUIZ · REMEDIATE · REVIEW · EXAM_PRACTICE · MATH_COACH · WRITING_COACH · READING_COACH · SCIENCE_COACH · LANGUAGE_PARTNER`.

---

## 7. Non-functional requirements

- **Accessibility:** keyboard navigation, screen-reader semantics, semantic headings, form labels, focus management, alt text, semantic visual descriptions, captions, transcripts, font scaling, reduced motion, high-contrast compatibility, TTS/STT integration.
- **Privacy and safety:** least privilege, protected student information, enforced guardian relationships, prevented cross-student access, audited privileged actions, secured uploads, governed AI interactions, minimized personal information, age-appropriate experiences, no manipulative engagement mechanics.
- **Persistence:** durable, relational persistence for every domain entity listed in §5. No production path may depend on memory repositories, static JSON, browser localStorage, hardcoded data, or test fixtures as authoritative state.
- **Migration safety:** forward-only migrations; historical migrations are never rewritten; production-relevant migration behavior is tested before merge.
- **Observability:** instrumented failures for topic loading, asset loading, visual interaction, assessment, grading, authorization denial, persistence, AI, mastery calculation, remediation, and retention scheduling — without exposing sensitive student data in logs.

---

## 8. Acceptance criteria (v1 launch)

A capability ships only when all of the following are true:

- [ ] Domain behavior is implemented, not stubbed.
- [ ] Persistence is durable and relational, with RLS applied.
- [ ] Authorization is enforced at the object level, not just the route level.
- [ ] The capability is reachable through a real UI surface, not only an API.
- [ ] Relevant events are emitted and observable.
- [ ] Unit, integration, and at least one E2E test exist and pass.
- [ ] The capability appears, with evidence, in a certified vertical slice for at least one grade band.

Full launch acceptance additionally requires:

- [ ] K–2, 3–5, 6–8, and 9–12 vertical slices are all certified (see `CLAUDE.md` §7).
- [ ] All seven launch courses are certified end-to-end.
- [ ] Cross-role, retention, and misconception certifications all pass.
- [ ] AI Tutor governance certification passes (never reveals graded answers, never writes mastery directly).

---

## 9. Metrics

| Metric | Definition | Target signal |
|---|---|---|
| **Evidence coverage** | % of "mastered" concepts backed by ≥1 application/analysis-level evidence item, not recall-only | Trending toward 100% |
| **Mastery–grade divergence** | Mean absolute gap between school grade and demonstrated mastery | Visible and non-zero — divergence is expected, not a bug |
| **Retention half-life** | Median days before a mastered concept without reinforcement drops out of `MASTERED` | Increasing over successive cohorts as remediation improves |
| **Misconception resolution rate** | % of detected misconceptions that reach `MASTERED` within 3 remediation cycles | Trending upward |
| **AI Tutor answer-leak rate** | Instances of the tutor revealing a protected assessment answer | Zero, monitored continuously |

---

## 10. Risks

| Risk | Mitigation |
|---|---|
| Teams interpret "adaptive" as a difficulty slider | Pedagogy Policy Engine is specified with named inputs (§6.1); code review checks against this list |
| AI drift toward completing graded work | Hard governance boundary in `AI_STRATEGY.md`, tested continuously, not just at launch |
| Mastery inflation (state advances without real evidence) | Mastery Engine spec explicitly forbids completion- or time-based transitions (§6.5) |
| Guardian over-visibility | Object-level authorization tested as an explicit certification (§8) |
| Curriculum edits invalidating historical evidence | Forward-only curriculum versioning (§7); attempts retain their original curriculum/question version |

---

## 11. Open questions

- Which state/district standards frameworks are required for the initial pilot cohort, beyond Common Core and AP?
- What is the guardian-relationship verification process for the pilot (school-provided roster vs. self-service linking)?
- Does the initial pilot require offline or low-bandwidth support for the K–2 experience?

These are tracked as `BLOCKED` or `DEFERRED` items in the Phase 0 reconnaissance report per `CLAUDE.md` §10, not silently assumed.
