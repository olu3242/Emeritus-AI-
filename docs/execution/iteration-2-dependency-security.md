# Iteration 2 dependency-security disposition

## Finding

The candidate lock contains optional `sharp@0.34.5`, introduced only by `next@15.5.23` through its optional `sharp@^0.34.3` relationship. npm groups the inherited libvips findings under `GHSA-f88m-g3jw-g9cj` and reports CVE-2026-33327, CVE-2026-33328, CVE-2026-35590, and CVE-2026-35591. The reported vulnerable range is `sharp <0.35.0`; npm offers Next.js 16.3.0 as the automated fix, which is a breaking framework upgrade.

## Exposure analysis and mitigation

- Repository search finds no `next/image`, image route, `sharp` import, or application image-processing call.
- `next.config.ts` sets `images.unoptimized=true`, disabling the Next server image-optimization path.
- `.npmrc` sets `omit=optional`, so a clean production/CI install does not install the optional native `sharp` package.
- The production audit command explicitly excludes optional packages: `npm audit --omit=dev --omit=optional --audit-level=high`.
- No untrusted image upload or image-transformation interface exists in Iteration 2.

Classification: `Not affected with verified evidence` for the current repository build and declared install procedure. This classification expires if optional dependencies are installed in deployment, image optimization is enabled, an image-processing/upload path is added, or the Next.js installation policy changes. Revalidation is required at each of those triggers. No risk acceptance or advisory suppression is asserted.

The lockfile retains metadata for reproducible dependency resolution; presence in lock metadata is not runtime reachability. A clean CI installation and production build without optional dependencies are required evidence.
