# Emeritus — AI Strategy

**Version:** 1.0
**Scope:** AI Tutor governance, Pedagogy Policy Engine model use, curriculum ingestion AI, and the platform-wide boundary between advisory AI and evidence-gated state.
**Related:** `PRD.md` §6.10, `../CLAUDE.md` §4

---

## 1. Governing principle

**AI proposes. Evidence decides.**

Every AI-touched surface in Emeritus falls into exactly one of two categories:

1. **Advisory** — the AI suggests, explains, hints, drafts, or recommends. A human or an evidence-evaluation process must act on the suggestion before it affects any learner record.
2. **Prohibited** — the AI is not permitted to directly write mastery state, grade a summative assessment, or make an irreversible decision about a learner's academic record.

There is no third category. If a proposed feature doesn't fit cleanly into "advisory," it does not ship until it's redesigned to fit.

This mirrors the hard architectural constraint used across every regulated or high-stakes Zenith AI build (ContractVault, MedLink, METRICX, AssuraPay): **no AI-triggered state-changing writes** in the path that matters most to the end user's outcome. In a payments platform that's funds movement. In Emeritus, it's mastery.

---

## 2. Where AI is used

| Surface | Mode | Category |
|---|---|---|
| AI Tutor (chat, hints, Socratic dialogue) | Real-time, learner-facing | Advisory |
| Pedagogy Policy Engine | Real-time, determines instruction shape | Advisory (decision is deterministic policy informed by AI-assisted signal classification, not free-generation) |
| Adaptive Remediation strategy selection | Near-real-time | Advisory — proposes next strategy; the state machine (§ below) executes it |
| Misconception classification | Post-attempt, async | Advisory — proposes a misconception candidate; requires either corroborating evidence or a subsequent retest to confirm |
| Curriculum ingestion (syllabi, standards, pacing guides → objectives, units, prerequisites) | Async, authoring workflow | Advisory — proposals only, require human validation before canonical publication |
| Writing coaching (ELA) | Real-time, learner-facing | Advisory — coaches revision, does not produce graded submissions |
| Assessment authoring assistance | Async, educator-facing | Advisory — drafts items; educator publishes |

Nowhere in this table does AI output flow directly into a `mastery_state`, `assessment_score`, or `standards_mastery` write. Every one of those tables is written exclusively by the server-side evaluation and mastery-computation code paths, which take structured evidence as input — never a model's free-text or classification output as a shortcut.

---

## 3. AI Tutor governance

### 3.1 Required context on every invocation

The tutor is never invoked without: learner grade, course, unit, topic, objective, applicable standards, current mastery state, prerequisite status, recent responses, active misconceptions, remediation history, available learning assets for this concept, and assistance-usage history for this session.

A tutor call missing required context is a defect, not a degraded-but-acceptable state — the orchestrator should fail closed (fall back to a static hint or a "let's find the right starting point" prompt) rather than let the model improvise without curriculum grounding.

### 3.2 Modes

`TEACH · EXPLAIN · SHOW · SOCRATIC · HINT · GUIDED_PRACTICE · QUIZ · REMEDIATE · REVIEW · EXAM_PRACTICE · MATH_COACH · WRITING_COACH · READING_COACH · SCIENCE_COACH · LANGUAGE_PARTNER`

Mode selection is made by the orchestrator from learner state and current loop position (see `../diagrams/circular-workflow.svg`), not chosen freely by the model based on conversational drift.

### 3.3 The tutor does

- Guide reasoning with questions before supplying answers
- Offer hints scaled to grade level and current struggle
- Re-explain a concept through a different modality when the first explanation didn't land
- Generate fresh, curriculum-grounded practice items
- Reference the learner's actual evidence and remediation history
- Respond in age-appropriate register (K–2 tutoring reads nothing like 9–12 tutoring)

### 3.4 The tutor never

- Completes graded work on the learner's behalf
- Writes a final essay, lab report, or other summative submission
- Impersonates a student in any context
- Reveals protected assessment answers, including through inference chains a learner could reconstruct
- Writes a mastery state, standards-mastery record, or grade directly — only evaluated evidence can trigger those writes
- Makes an unsupported high-stakes decision alone (e.g., unilaterally recommending grade retention, special education referral, or removal from an advanced track) — these route to an educator, always

### 3.5 Testing this boundary

Governance is not a system-prompt instruction alone. It is enforced and tested at three layers:

1. **Prompt/context layer** — the tutor's context never includes protected answer keys for open assessment windows.
2. **Output filtering** — responses are checked against a protected-answer pattern before being returned, for any assessment currently `IN_PROGRESS` for that learner.
3. **Write-path layer** — the tutor's output channel has no credential or code path capable of writing to `mastery_state`, `assessment_score`, or `standards_mastery` tables, at the infrastructure level, not just by convention.

Layer 3 is the one that matters most: a prompt injection or jailbreak against layers 1–2 should still be unable to change a learner's record, because the tutor process is architecturally incapable of it.

---

## 4. Pedagogy Policy Engine and AI

The Pedagogy Policy Engine determines instruction shape (§ PRD 6.1) from a large, named set of inputs. AI may assist in classifying unstructured signal into those inputs — for example, estimating reading-level appropriateness of a passage, or classifying a free-text response's cognitive dimension (recall vs. application vs. analysis) — but the *policy decision itself* (what modality, what scaffolding, what practice type) is deterministic logic over those classified inputs, not a fresh model call per learner interaction. This keeps the policy engine auditable, debuggable, and reproducible: given the same inputs, it should make the same pedagogical choice every time.

---

## 5. Curriculum ingestion AI

AI may **propose**: units, topics, concepts, objectives, standards mappings, prerequisites, learning assets, and assessment plans, drawn from uploaded syllabi, standards documents, curriculum maps, pacing guides, textbooks, and teacher materials.

AI-generated curriculum requires human validation before canonical publication. Nothing proposed by the ingestion pipeline is queryable by a learner-facing surface until an authorized curriculum author has reviewed and published it through the governed workflow (`PRD.md` §5.1, curriculum versioning `DRAFT → PUBLISHED → ARCHIVED`).

---

## 6. Model use guidelines

- **Grounding over generation.** Every learner-facing AI response should be grounded in the curriculum graph and the learner's actual evidence record, retrieved and injected into context — not generated from the model's general knowledge of "what a biology lesson on cells usually covers."
- **Deterministic where it matters.** Grading of objective question types (multiple choice, matching, sorting, numeric response) uses deterministic server-side evaluation, not a model call. Model-assisted evaluation is reserved for extended response and writing, and even then produces a *proposed* score/feedback that follows the same advisory-only rule as everything else.
- **Fail closed, not open.** If required context is unavailable, or a governance check fails, the system falls back to a safer, less capable static experience rather than letting an ungrounded or unchecked AI response reach a learner.
- **No dark patterns.** AI is not used to maximize engagement, session length, or "streak" mechanics at the expense of the learner's actual pace or wellbeing. Emeritus's incentive is demonstrated mastery, not time-on-platform.

---

## 7. Summary boundary table

| Action | Who/what performs it |
|---|---|
| Suggest a hint | AI Tutor (advisory) |
| Grade a multiple-choice item | Deterministic server-side evaluator |
| Propose a misconception | Misconception Engine (AI-assisted, advisory) |
| Confirm a misconception | Evidence from a subsequent evaluated attempt |
| Draft a new unit from a syllabus | Curriculum ingestion AI (advisory) |
| Publish that unit | Authorized human curriculum author |
| Recommend today's study plan | Daily Learning Orchestrator (advisory, deterministic ranking over evidence) |
| Change a learner's mastery state | Only the Mastery Engine, only from evaluated evidence |
| Decide grade retention or track placement | Educator, informed by system evidence — never automated |
