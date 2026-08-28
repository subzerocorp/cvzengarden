# ZG-10 PETC — Honest page count + Save as PDF hint

**PBI:** ZG-10 (avril-blessed) · deps ZG-7 (on main as `f0a5ab2`; ZG-9 is `802c0d5`)
**AXEL:** Generator `code-writer` (Elm + CSS + JS probes); adversaries reviewer → tester → architect (Elm/CSS/JS)
**Decomposition mode:** off

## Goal
Honest "About N pages (Paper)" in Print preview, plus a hint that Save as PDF lives in the print dialog. No PDF pipeline. No page-break overlay.

## Approach
Phase 1: pure `frontend/static/page-estimate.js` (`pageGeometry`, `estimatePages`, `estimateLabel`) + `ports.js` `collectPageRules` / sync constrained-height measure / rAF-coalesced `pageEstimate` + Elm readout + PDF hint.
Phase 2: `frontend/scripts/page-estimate.test.mjs` (prescribed cases) + named `ZG-10/*` probes + tester README + tracking.

## Files
`frontend/static/page-estimate.js`, `frontend/scripts/page-estimate.test.mjs`, `frontend/static/ports.js`, `frontend/scripts/copy-dist.mjs`, `frontend/src/Main.elm`, `frontend/css/chrome.css`, `frontend/scripts/probes/{zg-10.mjs,zg-10.test.mjs}`, `frontend/scripts/probes.mjs`, `frontend/README.md`, this file, `progress.md`, `features.json`, `.pinto/tasks/ZG-10.md`.

## Test strategy
Unit: `node --test frontend/scripts/page-estimate.test.mjs` (every listed case). Named probes `ZG-10/paper-size`, `paper-size-fallbacks`, `estimate-matches-formula`, `estimate-near-pdf`, `updates-on-switch`, `updates-on-content`, `min-one`, `hint`, `no-guide-lines`. Existing S3 / U3 / ZG-7 `one-print` / S1–S5 / ZG-4/5/6/8/9 stay green. `U3_PRINT_PAGES` and `themes/` untouched. Pre-existing carved-out miss: `ZG-11/page-count quarto`.

## Risk
Constrained `html` width must be set and cleared in one task or the preview paints at paper width and the probe sees a leftover `style`. `@page` nested in `@media print` is only readable via CSSOM walk (not computed style). Quarto `:first` must not shadow the base rule.

## Phases
1. **Phase 1 of 2** — pure module + ports measure + Elm readout/hint.
2. **Phase 2 of 2** — unit cases, named probes, README, evidence.

## Unresolved questions
- none (formula, probe names, and hint copy are prescribed; page-boundary overlay and PDF pipeline are out)

## Execution Evidence

Log: `/tmp/zg10-probes-5.log` (`PROBE_PORT=4514 node scripts/probes.mjs` after `npm run build` / `copy-dist`). Rust half (`cargo fmt --check`, clippy pedantic, `cargo test` on renderer + renderer-wasm) was green on rustc 1.87.0 before that run.

- [x] `node --test frontend/scripts/page-estimate.test.mjs` — every prescribed case (estimatePages 0/946/946.5/1892/1893, singular label, Letter default 1 cm, Quarto 681.6×945.6, Switchyard 672.8×1009.1, A4 case, `:first` ignored, fallback tokens, none throw)
- [x] `ZG-10/paper-size` — `PASS  ZG-10/paper-size Quarto and Nightgarden declare Letter; Switchyard declares A4`
- [x] `ZG-10/paper-size-fallbacks` — `PASS  ZG-10/paper-size-fallbacks missing @page is Letter/default; 8.5in 11in is Letter/fallback`
- [x] `ZG-10/estimate-matches-formula` — `PASS  ZG-10/estimate-matches-formula readout matches the constrained-height formula (nightgarden 2, quarto 2, switchyard 2)`
- [x] `ZG-10/estimate-near-pdf` — `PASS  ZG-10/estimate-near-pdf nightgarden estimate 2 pdf 2; quarto estimate 2 pdf 2; switchyard estimate 2 pdf 2`
- [x] `ZG-10/updates-on-switch` — `PASS  ZG-10/updates-on-switch Quarto Letter → Switchyard A4; estimate settled on 2`
- [x] `ZG-10/updates-on-content` — `PASS  ZG-10/updates-on-content clones raised 2 → 3; remove and Screen/Print preview restored 2`
- [x] `ZG-10/min-one` — `PASS  ZG-10/min-one tiny Quarto résumé reads About 1 page (Letter)`
- [x] `ZG-10/hint` — `PASS  ZG-10/hint Save as PDF hint is visible in both views under the ZG-7 sentence`
- [x] `ZG-10/no-guide-lines` — `PASS  ZG-10/no-guide-lines Print preview has no page-boundary overlay and the iframe html has no leftover style`
- [x] Existing RZ-3 / S1–S5 / U3 / ZG-4/5/6/7/8/9 — all PASS in the same run. `U3_PRINT_PAGES` still `{nightgarden: 2, quarto: 2, switchyard: 2}`; Garden/iframe and chrome-shell printToPDF 2/2/2. View toggle still **Print preview**. `.preview-controls__print` unchanged. Chrome markup/CSS `rz-` check silent. ZG-7 `one-print`, ZG-8 copy-link / unknown `?theme=`, ZG-9 phone Theme sheet PASS.
- [ ] `just verify` exit 0 — rust + every ZG-10 / U3 / S1–S5 / ZG-7/8/9 probe green. Same-run leftover: `FAIL  ZG-11/page-count quarto … long-resume.html is 4 page(s), LONG_PRINT_PAGES is 3` (pre-existing on main / PR #25 Tester note; sandbox-only; chrome and `U3_PRINT_PAGES` untouched). Not fixed here.

Unit tests: `npm run test:unit` 193/193 including `frontend/scripts/page-estimate.test.mjs` and `frontend/scripts/probes/zg-10.test.mjs`.

`git diff origin/main -- themes/` empty. `U3_PRINT_PAGES` not in the `probes.mjs` hunk.
