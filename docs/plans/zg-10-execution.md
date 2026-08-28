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

Pending phase 2 run.
