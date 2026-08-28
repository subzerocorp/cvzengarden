# ZG-13 PETC — Self-host first-party theme fonts

**PBI:** ZG-13 (avril-blessed) · deps none (ZG-10 is on `main` as `7dc0550`)
**AXEL:** Generator `code-writer` (CSS + JS probes); adversaries reviewer → tester → architect (CSS/JS)
**Decomposition mode:** off

## Goal
A first-party résumé page never calls jsDelivr. Faces stay when printing offline.

## Approach
Phase 1: vendor the exact latin woff2 files the three Themes already reference under `themes/fonts/<family>/` with each family's `OFL.txt`; rewrite `@font-face src` to `local("…")` then `url("fonts/…")`; copy `themes/fonts/` in `copy-dist.mjs`; write the locked Font Library / CC BY 4.0 / HTTPS CDN policy on `themes/README.md`.
Phase 2: named probes `ZG-13/no-third-party`, `font-files`, `fonts-load`, `fallback`, and `BAR-L1` (this PBI owns BAR-L1). Pure calculations over CSS / request logs / FontFace lists / pair styles. Fallback uses the ZG-4 `pageerror`-only stance and ignores console errors whose location or text contains `/themes/fonts/`.

## Files
`themes/fonts/**`, `themes/{quarto,switchyard,nightgarden}.css`, `themes/README.md`, `frontend/scripts/copy-dist.mjs`, `frontend/scripts/probes/{zg-13.mjs,zg-13.test.mjs,lib/theme-fonts.mjs,lib/theme-fonts.test.mjs}`, `frontend/scripts/probes.mjs` (wire only; `U3_PRINT_PAGES` / `LONG_PRINT_PAGES` untouched), `frontend/scripts/probes/lib/{request-log.mjs,request-log.test.mjs,page.mjs}`, this file, `progress.md`, `features.json`, `.pinto/tasks/ZG-13.md`.

## Test strategy
Unit-test the font-face brace scan, host filter, pair differ, FontFace reasons, and fallback console filter. Named Playwright probes as the PBI specifies. S3/U3 stay green against current constants. Same-face swap must not reflow; if it does, stop and return to planning.

## Risk
A same-face swap that reflows print pages. Do not edit `U3_PRINT_PAGES` or `LONG_PRINT_PAGES`.

## Phases
1. **Phase 1 of 2** — vendor OFL seed + rewrite `@font-face` + copy-dist + README policy.
2. **Phase 2 of 2** — probes, unit tests, evidence.

## Unresolved questions
- none (fonts policy locked 2026-08-24; no host allowlist)

## Execution Evidence

Pending phase 2.
