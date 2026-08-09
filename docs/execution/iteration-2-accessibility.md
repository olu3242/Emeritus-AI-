# Iteration 2 accessibility evidence

## Automated scope

The `/learning` operational surface includes a skip link, semantic main/section/aside structure, associated form labels and descriptions, visible focus, an `aria-live` status region, responsive reflow, reduced-motion handling, password treatment for bearer input, and non-color-only feedback.

Playwright checks keyboard access to the skip link and runs axe against WCAG 2 A/AA, WCAG 2.1 AA, and WCAG 2.2 AA tags. The two browser assertions complete locally without assertion failures; Windows process teardown currently prevents the local command from reaching a clean exit and is therefore not counted as a local pass. The Linux CI result is the authoritative automated result.

Both independent Linux jobs passed seven accessibility and workflow E2E tests in role-application workflow `31341528923`: jobs `93316004424` and `93316004382`. Coverage includes teacher/learner operations, guardian/admin routes and states, unauthenticated API denial, mobile reflow, accessible status, and axe analysis.

## Manual scope

No manual screen-reader, zoom, high-contrast, low-bandwidth, caption, transcript, or assistive-technology session was performed in this coding environment. Those checks remain `Blocked` on a qualified human accessibility review and must not be inferred from axe results.

The versioned execution record is `docs/execution/iteration-2-manual-accessibility-protocol.md`. It intentionally contains no fabricated passes.
