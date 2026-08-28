# ZG-7 PETC — Plain-language chrome, About panel, free during preview

**PBI:** ZG-7 (avril-blessed) · deps none
**AXEL:** Generator `code-writer` (Elm + CSS + JS probes); adversaries reviewer → tester → architect (Elm/CSS/JS)
**Decomposition mode:** off

## Goal
Rewrite garden chrome in plain language. One About dialog. Honest “free during the preview” line. Elena stops feeling dumb; Priya finds the print action; nobody hunts a price.

## Approach
Phase 1: Elm copy + About module (pure model/update, `Effect = Focus`) + GPUI-token dialog CSS + `focusId` port. Phase 2: `frontend/scripts/probes/zg-7.mjs` (calculations unit-tested; Playwright actions reuse U3 iframe `print()` wiring) + README tester sentence + tracking.

## Files
`frontend/src/About.elm`, `frontend/src/Main.elm`, `frontend/css/chrome.css`, `frontend/static/ports.js`, `frontend/scripts/probes/zg-7.mjs`, `frontend/scripts/probes/zg-7.test.mjs`, `frontend/scripts/probes.mjs`, `frontend/README.md`, this file, `progress.md`, `features.json`, `.pinto/tasks/ZG-7.md`.

## Test strategy
Named probes `ZG-7/no-jargon`, `one-print`, `badges`, `about`, `print-on-white`. `textContent` only. GitHub `href` string equality, never fetched. Existing RZ-3 / S1–S5 / U3 / ZG-4/5/6/11/12 stay green. `U3_PRINT_PAGES` untouched.

## Risk
Focus return after Escape races Elm’s patch; port uses double `requestAnimationFrame`. Hidden paste panel is still in `textContent` — do not put jargon there (ZG-6 already clean).

## Phases
1. **Phase 1 of 2** — copy + About panel + focus port.
2. **Phase 2 of 2** — probes, README, evidence.

## Unresolved questions
- none (copy is prescribed; designer-kit links belong to ZG-14)

## Execution Evidence

Log: `/tmp/zg7-frontend.log` (`PROBE_PORT=4477 just test-frontend`). Rust half of `just verify` (fmt, clippy pedantic, cargo test) was green on rustc 1.87.0 before that run.

- [x] `ZG-7/no-jargon` — `PASS  ZG-7/no-jargon closed chrome textContent has Appearance / For paper / Print / Save as PDF / Pick a look for your résumé and none of the banned developer words`
- [x] `ZG-7/one-print` — `PASS  ZG-7/one-print exactly one Print / action; Print / Save as PDF prints the iframe; Print preview toggle still unique`
- [x] `ZG-7/badges` — `PASS  ZG-7/badges Nightgarden / Quarto / Switchyard badges read Screen / Paper / Screen + paper`
- [x] `ZG-7/about` — `PASS  ZG-7/about About dialog has Free during the preview and the GitHub href; Escape closes and restores focus` (href string equality; request log had no GitHub fetch)
- [x] `ZG-7/print-on-white` — `PASS  ZG-7/print-on-white switcher textContent claims prints in dark ink on white paper (S3/U3 remain the honesty guard)`
- [x] Existing RZ-3 / S1–S5 / U3 — all PASS in the same run. `U3_PRINT_PAGES` still `{nightgarden: 2, quarto: 2, switchyard: 2}`; Garden/iframe and chrome-shell printToPDF 2/2/2; `.preview-controls__print` and button name `Print preview` retained. S3 white paper / no motion PASS.
- [x] Chrome has no `rz-` class or id (static chrome probe). `ZG-7/bar-q1` — `PASS  ZG-7/bar-q1 Independent Product Experience Guardian remains in qa/MARKET-QUALITY-BAR.md`. File not edited.
- [ ] `just verify` exit 0 — rust + every ZG-7 / U3 / S1–S5 probe green. Same-run leftover: `FAIL  ZG-11/page-count quarto … long-resume.html is 4 page(s), LONG_PRINT_PAGES is 3` (pre-existing on main / PR #22 Tester note; sandbox-only; chrome and `U3_PRINT_PAGES` untouched). Not fixed here.

Unit tests: `npm run test:unit` 154/154 including `frontend/scripts/probes/zg-7.test.mjs`.

Existing `getByRole('button', { name: 'Screen' })` locators in `probes.mjs` now pass `{ exact: true }` so “For screen” and “Nightgarden Screen” do not steal the View toggle. `Print preview` is unchanged.
