# Emeritus

**A K–12 Adaptive Multimodal Mastery Learning OS.**

Emeritus is a production-grade runtime that sits underneath a school's curriculum and refuses to let content consumption stand in for learning. A concept is never marked mastered because a learner opened it, watched it, or clicked through it — only because they demonstrated it, under server-side evaluation, and later retained it.

This repository is the planning and execution package for Emeritus: the landing page, the product requirements, the AI governance strategy, the execution constitution for coding agents, and the two canonical diagrams that every implementation decision should trace back to.

---

## Table of contents

- [Constitutional invariant](#constitutional-invariant)
- [What's in this package](#whats-in-this-package)
- [The Mastery Loop](#the-mastery-loop)
- [Architecture at a glance](#architecture-at-a-glance)
- [Grade bands and pedagogy](#grade-bands-and-pedagogy)
- [Subject engines](#subject-engines)
- [Launch certification pack](#launch-certification-pack)
- [Getting started](#getting-started)
- [Project structure](#project-structure)
- [Execution phases](#execution-phases)
- [Testing and certification](#testing-and-certification)
- [Safety invariants](#safety-invariants)
- [Roadmap](#roadmap)
- [License](#license)

---

## Constitutional invariant

> **CONTENT CONSUMPTION != LEARNING.**

A learner does not master a concept because they:

- opened a lesson
- read text
- watched a video
- viewed an image
- listened to audio
- clicked through slides
- completed a page
- spent time in the application

A concept becomes mastered only through sufficient evidence of age-appropriate understanding and application, evaluated server-side, and confirmed again later under spaced retrieval.

This is the single sentence every engineering and product decision in this repository is checked against. If a feature can't point to how it produces or consumes *evidence*, it doesn't belong in the mastery runtime — it belongs in the content library, which is a different, much smaller problem.

---

## What's in this package

```
emeritus/
├── index.html                      Landing page (single-file, no build step)
├── package.json                    Project manifest and scripts
├── README.md                       This file
├── CLAUDE.md                       Execution constitution for coding agents
├── docs/
│   ├── PRD.md                      Product requirements document
│   └── AI_STRATEGY.md              AI governance and tutor strategy
└── diagrams/
    ├── circular-workflow.svg       The Mastery Loop (canonical learner state cycle)
    └── architecture.svg            Six-layer system architecture
```

Nothing here is a stub. The landing page is a real, responsive, accessible single-file deliverable. The diagrams are the literal artifacts referenced throughout `PRD.md`, `AI_STRATEGY.md`, and `CLAUDE.md` — not illustrative filler.

---

## The Mastery Loop

Every topic, in every subject, at every grade, moves through the same evidence cycle:

```
DIAGNOSE → TEACH → SHOW & INTERACT → COMPREHEND → PRACTICE & APPLY
    → ASSESS → MASTER (or → MISCONCEPTION → REMEDIATE → back to TEACH)
    → RETAIN → (review due) → back to DIAGNOSE
```

See `diagrams/circular-workflow.svg` for the canonical visual. What changes by grade band is *modality* — how a first grader proves they can count to ten looks nothing like how a junior demonstrates readiness for AP Government — but the loop itself, and the requirement for evidence at every gate, never changes.

---

## Architecture at a glance

Six layers, one runtime, shared by every grade and every subject engine:

1. **Experience** — Student Home, Topic Player, Knowledge Map, Educator Console, Guardian View
2. **Learning Runtime** — Topic Player Engine, AI Tutor Orchestrator, Daily Plan Orchestrator, Assessment Runtime
3. **Intelligence Engines** *(governed, advisory-only)* — Pedagogy Policy, Comprehension & Confidence, Mastery State Machine, Misconception & Prerequisite Diagnosis, Adaptive Remediation, Retention & Spaced Review
4. **Curriculum & Domain Core** — Curriculum Graph, Standards Alignment, Prerequisite Graph, Subject Engines
5. **Platform Foundation** — Identity & Roles, Enrollment & Relationships, Object-Level Authorization, Event Bus
6. **Persistence & Observability** — Postgres with RLS and forward-only migrations, append-only audit chain, analytics and readiness store, observability

Cross-cutting every layer: accessibility, student privacy and least-privilege access, curriculum versioning, server-side-only evaluation, and a hard prohibition on AI-triggered mastery writes.

See `diagrams/architecture.svg` for the full visual and `docs/PRD.md` §Architecture for the entity-level detail.

---

## Grade bands and pedagogy

| Band | Emphasis | Leads with |
|---|---|---|
| **K–2** | See it, touch it, say it | Illustrations, read-aloud, manipulatives, drag-and-drop, short interactions |
| **3–5** | Read, reason, explain | Comprehension, visual models, maps, timelines, guided written response |
| **6–8** | Argue with evidence | Mathematical modeling, experiments, data interpretation, evidence-based argument |
| **9–12** | Work like the discipline works | Primary sources, research, simulation, formal argumentation, AP-level assessment |

The curriculum graph, standards alignment, and prerequisite graph are shared across all four bands. Pedagogy — not architecture — is where the platform adapts.

---

## Subject engines

Mathematics · ELA/Reading · Science · Social Studies · World Language · Health/PE, each built on the same Activity, Question, Comprehension, and Mastery engines, with subject-specific error diagnosis (e.g. detecting an incomplete application of the distributive property in algebra, not just marking an answer wrong).

---

## Launch certification pack

Seven high-school courses are the first vertical slice certified end-to-end:

- Honors Biology
- Honors English Language & Composition
- Advanced Quantitative Reasoning
- AP U.S. Government & Politics
- Honors English Literature & Composition
- Spanish II
- Lifetime Fitness & Wellness Pursuits

These are curriculum data, not platform architecture — the runtime is not hardcoded around them, and additional courses and grade bands are added without touching the core engines.

---

## Getting started

This package ships as planning and design artifacts. To stand up the implementation described in `CLAUDE.md` and `docs/PRD.md`:

```bash
# install dependencies
npm install

# copy environment template and fill in Supabase credentials
cp .env.example .env.local

# run database migrations
npm run db:migrate

# seed reference curriculum data (K-2 counting, Honors Biology cell structure)
npm run db:seed

# start the development server
npm run dev
```

To view the landing page only, no build step is required — `index.html` is a single self-contained file:

```bash
open index.html
```

---

## Project structure

The intended implementation structure (not yet scaffolded in this package — see `CLAUDE.md` §Repository Reconnaissance for how a coding agent should approach an existing or greenfield repository):

```
apps/
  web/                 Next.js app — student, educator, guardian experiences
packages/
  curriculum/          Curriculum graph, standards, prerequisite graph
  assessment/          Question engine, assessment runtime, server-side evaluation
  mastery/             Mastery state machine, comprehension, confidence
  misconception/       Misconception detection, prerequisite diagnosis
  remediation/         Adaptive remediation strategy selection
  retention/           Spaced retrieval scheduling
  tutor/                AI Tutor orchestration and governance
  subjects/
    mathematics/
    ela/
    science/
    social-studies/
    world-language/
    health-pe/
  events/              Durable event emission and consumption
  auth/                Identity, roles, object-level authorization
supabase/
  migrations/          Forward-only SQL migrations
scripts/
  seed.ts
  certify.ts
```

---

## Execution phases

Implementation proceeds in dependency order, not all at once:

0. Repository reconnaissance
1. Identity + learner + guardian + educator + enrollment
2. Curriculum + standards + prerequisite graph
3. Multimodal content + visual interactions + Topic Player
4. Activity + question + assessment runtime
5. Comprehension + confidence + mastery
6. Misconception + prerequisite diagnosis
7. Adaptive remediation
8. Retention + spaced retrieval
9. Recommendation + daily learning plan
10. AI Tutor + pedagogy adaptation
11. Subject engines
12. Student + guardian + educator intelligence
13. Curriculum authoring + ingestion
14. Full K–12 certification + production hardening

Full detail, including stop conditions and the completion report format, is in `CLAUDE.md`.

---

## Testing and certification

A capability is not "done" because it has a schema, an API returning fixtures, or a UI with hardcoded values. It is done when it is implemented, persisted, authorized, exposed at runtime, connected to the UI, instrumented, and tested — and it is *certified* when a real end-to-end learner journey proves it, for a representative slice of each of K–2, 3–5, 6–8, and 9–12.

```bash
npm run test          # unit + domain + repository tests
npm run test:e2e       # end-to-end learner journey tests
npm run certify:all    # runs the four grade-band certification suites
```

Required certifications before any capability is reported as `IMPLEMENTED`:

- K–2 vertical slice (Grade 1 Mathematics — Counting Objects to 10)
- Grades 3–5 vertical slice
- Grades 6–8 vertical slice
- Grades 9–12 vertical slice (Honors Biology — Cell Structure)
- Cross-role certification (educator authors → learner masters → educator and guardian see evidence, unauthorized parties are denied)
- Retention certification (mastery → review due → retrieval → mastery updated)
- Misconception certification (wrong answer → diagnosis → remediation → retest → mastery recalculated)
- AI Tutor governance certification

---

## Safety invariants

These hold across every engine, every subject, and every grade band, without exception:

- **No AI-triggered mastery writes.** AI proposes; only evaluated learner evidence changes mastery state.
- **Server-side evaluation only.** A client can never be the source of truth for correctness, score, or completion.
- **Row-level security on every table** that holds learner data.
- **Idempotency keys** on every write path that could otherwise double-process an attempt.
- **Append-only, auditable events** for every state transition — learning history is never silently rewritten.
- **Guardian access requires an explicit, authorized relationship.** No implicit visibility.
- **Curriculum versioning is forward-only.** Published curriculum that historical attempts depended on is never mutated in a way that invalidates that evidence.

---

## Roadmap

| Status | Milestone |
|---|---|
| ✅ | Landing page, PRD, AI strategy, execution constitution, canonical diagrams |
| ⏳ | Repository reconnaissance and platform foundation (Phase 0–1) |
| ⏳ | Curriculum graph and K–2 / 9–12 vertical slice certification |
| ⏳ | Full six-engine intelligence layer |
| ⏳ | Seven-course launch certification pack |
| ⏳ | Guardian and educator experience hardening |
| ⏳ | Curriculum authoring and ingestion pipeline |

---

## License

UNLICENSED — proprietary planning package. Built by Zenith AI Automation Agency.
#   E m e r i t u s - A I -  
 