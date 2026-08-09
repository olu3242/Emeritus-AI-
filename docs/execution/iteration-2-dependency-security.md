# Iteration 2 dependency-security disposition

## Finding

The candidate lock contains optional `sharp@0.34.5`, introduced only by `next@15.5.23` through its optional `sharp@^0.34.3` relationship. npm groups the inherited libvips findings under `GHSA-f88m-g3jw-g9cj` and reports CVE-2026-33327, CVE-2026-33328, CVE-2026-35590, and CVE-2026-35591. The reported vulnerable range is `sharp <0.35.0`; npm offers Next.js 16.3.0 as the automated fix, which is a breaking framework upgrade.

## Exposure analysis and mitigation

- Repository search finds no `next/image`, image route, `sharp` import, or application image-processing call.
- `next.config.ts` sets `images.unoptimized=true`, disabling the Next server image-optimization path.
- A clean install retains the optional native package because globally omitting optional dependencies also removes Rollup's required platform-native binary. Failed runs `31339119149` and `31339264541` preserve that evidence; the unsafe global omission was removed.
- The production-reachability audit command excludes optional packages: `npm audit --omit=dev --omit=optional --audit-level=high`. The complete lockfile audit continues to report the inherited finding.
- No untrusted image upload or image-transformation interface exists in Iteration 2.

Classification: `Temporarily mitigated with accepted residual risk required`. Repository evidence shows no application path to the vulnerable functionality, but the optional native package remains installed. No acceptance is fabricated: an authorized owner must accept the residual bundled-code risk or authorize a compatible framework/package remediation. Revalidation is required if image optimization is enabled, an image-processing/upload path is added, or the Next.js installation policy changes.

Required approver: product security or deployment owner. Decision expiry: 2026-09-09. Upgrade trigger: a Next.js 15-compatible `sharp >=0.35` range, an approved Next.js 16 migration, any image-processing feature, or the expiry date—whichever occurs first.
