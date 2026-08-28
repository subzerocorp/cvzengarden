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

Log: `/tmp/zg13-probes.log` (`PROBE_PORT=4520 npm run probe` after `npm run build` / `copy-dist`). Rust half (`cargo fmt --check`, clippy pedantic, `cargo test` on renderer + renderer-wasm) was green on rustc 1.87.0 before that run.

- [x] `grep -rn "jsdelivr" themes/*.css` — empty. `grep -c "@font-face"`: quarto.css 4, switchyard.css 4, nightgarden.css 5.
- [x] `ZG-13/no-third-party` — `PASS  ZG-13/no-third-party cycled nightgarden → quarto → switchyard and printed; 27 request(s), all 127.0.0.1/localhost`
- [x] `ZG-13/font-files` — `PASS  ZG-13/font-files 13 @font-face url(s) 200 font/woff2 under /themes/fonts/ and frontend/dist/themes/fonts/`
- [x] `ZG-13/fonts-load` — `PASS  ZG-13/fonts-load EB Garamond @ quarto; IBM Plex Sans @ switchyard; Syne @ nightgarden; no watched family in error`
- [x] `ZG-13/fallback` — `PASS  ZG-13/fallback aborted **/themes/fonts/**; .rz-name height 65.421875; S2 + BAR-U2 green; ignored 11 font-load error(s)`
- [x] `themes/fonts/*/OFL.txt` — eb-garamond, ibm-plex-sans, syne, outfit. `themes/README.md` contains `Font Library`, `CC BY 4.0`, and `HTTPS CDN`.
- [x] `BAR-L1` — `PASS  BAR-L1 PASS`
- [x] `U3_PRINT_PAGES` / `LONG_PRINT_PAGES` — not in `git diff -- frontend/scripts/probes.mjs`. S3 Nightgarden print 2 pages; U3 Garden/iframe and chrome-shell printToPDF 2/2/2. Same-face swap did not reflow.
- [ ] `just verify` exit 0 — rust + every ZG-13 / U3 / S1–S5 / ZG-4…10 probe green. Same-run leftover: `FAIL  ZG-11/page-count quarto … long-resume.html is 4 page(s), LONG_PRINT_PAGES is 3` (pre-existing on main / PR #26 Tester note; sandbox-only; chrome and `U3_PRINT_PAGES` untouched). Not fixed here.

Unit tests: `npm run test:unit` 206/206 including `frontend/scripts/probes/lib/theme-fonts.test.mjs` and `frontend/scripts/probes/zg-13.test.mjs`.
