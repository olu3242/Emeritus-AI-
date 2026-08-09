# Iteration 1 dependency advisory assessment

Assessment date: 2026-08-09. Source command: `npm.cmd audit --json`.

| Path | Scope | Highest severity | Relevance | Remediation |
|---|---|---:|---|---|
| `next@15.5.23 > postcss@8.4.31` | Production build | High | Relevant if attacker-controlled CSS/source maps are processed | Resolved with compatible root override `postcss@8.5.26`; verify with `npm.cmd audit --omit=dev`. |
| `next@15.5.23 > sharp@0.34.5` | Optional production image processing | High | Relevant if Next image optimization processes attacker-controlled images | Unresolved. Patched `sharp>=0.35.0` is outside Next 15's declared `^0.34.3`; npm recommends Next 16.3.0, a major upgrade requiring a separate compatibility pass. |
| `supabase@1.226.4 > tar@7.4.3` | Development CLI | Critical | Relevant while CLI extracts downloaded local-runtime assets; not shipped in the web runtime | Resolved with compatible root override `tar@7.5.21`; verify with full `npm.cmd audit`. |
| `vitest@2.1.9 > vite@5.4.21` and `esbuild@0.21.5` | Test/development only | High | Dev-server issues; certification invokes non-listening `vitest run` only | Unresolved. npm's supported fix is Vitest 4.1.10, a major upgrade. Perform separately, then rerun all suites. |
| `vitest@2.1.9` UI server | Test/development only | Critical | UI server is not installed/configured or invoked by repository scripts | Unresolved but operationally mitigated by using `vitest run`; major Vitest upgrade remains required. |

No `npm audit fix --force` was used. Compatible overrides reduced the installation report from 10 findings to 7 and production audit findings from 3 to 2. Remaining production `sharp` exposure prevents treating the audit gate as passing until Next 16 compatibility is assessed or Next publishes a compatible patched 15.x dependency.
