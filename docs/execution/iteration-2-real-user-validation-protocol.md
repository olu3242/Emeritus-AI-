# Iteration 2 real-user role validation package

Status: `Awaiting human validation`. No participant or result is pre-populated.

Participants must be authorized representatives of each role, provide consent, use synthetic data, and avoid entering student records or other personal information. Record participant role (not unnecessary identity), environment, browser/device, tested commit, date, observer, task outcome, usability finding, functional defect, severity, and retest.

| Role | Seeded tasks | Acceptance criteria |
|---|---|---|
| Teacher | Select class/learner; review submission; finalize rubric; compare mastery; add rationale override; accept/replace remediation; review reassessment; inspect history | Tasks complete without protected-data leakage or unauthorized scope; persisted state survives refresh |
| Learner | Open active assignment; pause/resume; recover autosave conflict; submit automatic and constructed responses; view pending score; complete remediation and reassessment | State and feedback are understandable; retry does not duplicate evidence; accessibility needs are met |
| Guardian | Select authorized learner; view assignment, mastery, and remediation summary; verify internal responses/rubrics/notes absent; retest after relationship revocation | Only permitted summary appears and revocation denies access immediately |
| Administrator | Inspect tenant enrollment, assignment/scoring state, override governance, audit and failure visibility | No cross-tenant records appear; operational failures are actionable |

Severity: critical (security/data loss/blocking harm), high (core task impossible), medium (task materially impaired), low (minor friction). Acceptance requires zero open critical/high findings, all tasks completed by representative participants, and remediation/retest evidence for failures.
