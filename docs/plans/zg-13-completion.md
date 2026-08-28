# PBI Completion — ZG-13

## Title
Self-host first-party theme fonts so a résumé page never calls jsDelivr

## Phases
- phase-1 vendor: BLESS reviewer | tester | architect — `dd50da3` (OFL seed under `themes/fonts/<family>/` with `OFL.txt`; `@font-face` `local()` then relative `url("fonts/…")`; `copy-dist.mjs` fail-loud copy; Font Library / CC BY 4.0 / HTTPS CDN policy on `themes/README.md`)
- phase-2 probes: `30a6616` (named ZG-13 probes + `theme-fonts.mjs` calculations) → `7b0744a` (evidence; board stayed in-progress)
- Reviewer BLESS `83d4a09` — `docs/plans/zg-13-reviewer.md`
- Tester BLESS `97dd096` — 206 unit, named ZG-13 probes PASS, U3 Jordan 2/2/2, U3 constants untouched

## Architecture
First-party faces live in the Theme layer as Font Library seed data (`themes/fonts/` + `OFL.txt`). Each Theme stays one pure CSS file; `@font-face` is `local()` then an origin-relative `url("fonts/…")`. No JS webfont loader. Chrome never gained an `rz-` class or id. Themes still target only `html` / `body` / `.rz-*` / `[data-rz-*]`. Probe calculations stay in `theme-fonts.mjs`; probe actions stay in `zg-13.mjs`. Build copy of the seed is an action at `copy-dist.mjs`. Policy is a README sentence, not a host allowlist and not a submit product. Scope stayed ZG-13.

## AC Evidence
On the PBI (`## Execution Evidence`). Tester log: `docs/plans/zg-13-tester.md`. Generator: `docs/plans/zg-13-execution.md`. Reviewer: `docs/plans/zg-13-reviewer.md`.

- [x] jsDelivr absent from `themes/*.css`; `@font-face` 4 / 4 / 5
- [x] `ZG-13/no-third-party` — 27 requests, all 127.0.0.1/localhost
- [x] `ZG-13/font-files` — 13 urls, 200, `font/woff2`, on disk
- [x] `ZG-13/fonts-load` — EB Garamond / IBM Plex Sans / Syne loaded; no watched family in error
- [x] `ZG-13/fallback` — `.rz-name` height > 0; S2 + BAR-U2; ignored 11 font-load errors
- [x] `themes/fonts/*/OFL.txt` + README `Font Library` / `CC BY 4.0` / `HTTPS CDN`
- [x] `BAR-L1 PASS`
- [x] `U3_PRINT_PAGES` / `LONG_PRINT_PAGES` not in the `probes.mjs` hunk; S3/U3 Jordan 2/2/2
- [ ] `just verify` leftover noted: pre-existing `ZG-11/page-count quarto` 4-vs-3 (not a ZG-13 hold)

## Verification matrix
- fmt / clippy pedantic / cargo test (renderer + renderer-wasm): PASS (Tester, rustc 1.87)
- `npm run test:unit`: 206 / 0 (26 `*.test.mjs` via `find`)
- Named ZG-13 probes: PASS (`no-third-party`, `font-files`, `fonts-load`, `fallback`, `BAR-L1`)
- S1–S5, U3, ZG-4 / ZG-5 / ZG-6 / ZG-7 / ZG-8 / ZG-9 / ZG-10 / ZG-12: PASS
- U3 Jordan print: 2/2/2
- Pre-existing `ZG-11/page-count quarto` 4-vs-3: carved out; theme print CSS and `U3_PRINT_PAGES` untouched

## Board
- status: done (`pinto` CLI absent in this VM; `.pinto/tasks/ZG-13.md` written done with `done_at` + commits)

## QA
- Product walk: QA PASS locked on https://zg13--cvzengarden.netlify.app
- Production stays ZG-10; was not walked and was not published
- CoS holds ship until GAN close

## Follow-ups / non-goals honored
- Font Library submit product — policy sentence only
- Subsetting / new faces / dropped faces — counts 4/4/5
- Print-page re-baseline — constants not edited
- CDN host allowlist — none
- U3 print CSS / `U3_PRINT_PAGES` / `LONG_PRINT_PAGES` / HTTPS / DNS / TLS / issue #9 untouched
- `qa/MARKET-QUALITY-BAR.md` unchanged
- JSON Resume remains the only stored Resume
- Residual ZG-11 quarto 4-vs-3 is not a hold
- PR #27 left draft; not merged; not marked ready

ARCHITECTURE VERDICT: BLESSED

Faces stayed Theme-layer data. First-party sheets load from the origin only. Chrome stayed chrome. Probe calculations stayed calculations. A new senior will still see one iframe sandbox, one Class Contract, one stored Resume shape, and a Font Library seed that never phones a CDN.

**ARCHITECT BLESS ZG-13**
