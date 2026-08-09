# Iteration 2 manual accessibility protocol

Status: `BLOCKED — qualified reviewer and assistive-technology environment required`.

This protocol must be executed against the exact candidate commit. Automated axe results do not satisfy it.

## Review record

Record reviewer identity, qualification/testing role, date and time, tested commit, operating system/version, browser/version, assistive technology/product version, input devices, viewport, zoom, contrast mode, findings, severity, remediation commit, retest result, and sign-off decision.

| Journey | Expected result | Actual result | Pass/fail | Finding/severity |
|---|---|---|---|---|
| Screen reader: learner start, pause, resume, autosave, submit | Names, state, errors, autosave, and confirmation announced once in logical order | Not executed | Blocked | Qualified reviewer unavailable |
| Screen reader: teacher rubric and remediation | Criteria, instructions, validation, scoring state, and confirmation announced without protected-data leakage | Not executed | Blocked | Qualified reviewer unavailable |
| Keyboard-only complete learner and teacher journeys | All controls reachable and operable; focus visible and logical; skip link works | Not executed | Blocked | Human review unavailable |
| Zoom/reflow at 200% and 400%, 320 CSS px | No two-dimensional scrolling for ordinary content; controls and status remain usable | Not executed | Blocked | Human review unavailable |
| Windows high contrast / forced colors | Meaning, boundaries, focus, errors, and states remain perceivable without color alone | Not executed | Blocked | Environment/reviewer unavailable |
| Focus entry, validation, navigation, and return | Focus moves predictably and is never lost or trapped | Not executed | Blocked | Human review unavailable |
| Timed activity and accommodation | Extension, pause, resume, expiry, and warning behavior match assigned accommodation | Not executed | Blocked | Human review unavailable |
| Reduced motion | System preference suppresses nonessential motion | Not executed | Blocked | Human review unavailable |
| Media unavailable / low bandwidth | Text fallback and retry preserve work and disclose status | Not executed | Blocked | Representative media/real-use journey unavailable |

## Required sign-off

The reviewer must enumerate scenarios executed, passed checks, failed checks, findings and severities, then provide an explicit accept/reject decision. Blank or unperformed rows cannot be treated as passes.
