# ZG-9 PETC — Phone résumé first; fold controls into a Theme sheet

**PBI:** ZG-9 (avril-blessed) · deps none (ZG-8 already on main as `bc664a9`)
**AXEL:** Generator `code-writer` (Elm + CSS + JS probes); adversaries reviewer → tester → architect (Elm/CSS/JS)
**Decomposition mode:** off

## Goal
On a 390px phone Elena's friend sees the résumé first, not a control panel. Controls fold into a Theme button that opens a sheet.

## Approach
Phase 1: `sidebarOpen : Bool` in Main. Theme toggle (`#theme-toggle`, accessible name `Theme`, `aria-expanded`) is CSS-hidden ≥721px. ≤720px: `.garden-stage` is first in the flex order and fills the viewport; `.app-sidebar` is a sticky bottom bar; `.app-sidebar--open` is the sheet. Escape closes and `focusId` returns to the toggle (same double-rAF port as About). Selecting a Theme closes the sheet. Body scroll lock is CSS `:has(.app-shell--sidebar-open)` inside the 720px query only.
Phase 2: named `ZG-9/*` probes + unit-tested calculations; existing RZ-3 / S1–S5 / U3 / ZG-4/5/6/7/8 stay green.

## Files
`frontend/src/Main.elm`, `frontend/css/chrome.css`, `frontend/scripts/probes/{zg-9.mjs,zg-9.test.mjs}`, `frontend/scripts/probes.mjs`, `frontend/README.md`, this file, `progress.md`, `features.json`, `.pinto/tasks/ZG-9.md`.

## Test strategy
Named probes `ZG-9/mobile-first`, `sheet`, `escape`, `desktop-unchanged`, `no-hscroll`. Phone viewport is 390×844; desktop 1280×800. Calculations are unit-tested. Existing RZ-3 / S1–S5 / U3 / ZG-4/5/6/7/8 stay green. `U3_PRINT_PAGES` untouched. Pre-existing carved-out miss: `ZG-11/page-count quarto`.

## Risk
`textContent` probes (ZG-7) include `display:none` nodes — do not put jargon on the toggle. Hidden sheet content is already jargon-free. Desktop grid must stay `18.5rem | 1fr`; the 720px query is an override after `52rem`, not a rewrite of it.

## Phases
1. **Phase 1 of 2** — Elm `sidebarOpen` + ≤720px stage-first / Theme sheet CSS.
2. **Phase 2 of 2** — probes, unit tests, README, evidence.

## Unresolved questions
- none (sheet, Escape, and 720px breakpoint are prescribed; theme-card restyle / swipe / native share are out)

## Execution Evidence

_Pending phase 2._
