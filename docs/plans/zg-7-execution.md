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

Recorded after `just verify`. See the end of this file once the matrix has run.
