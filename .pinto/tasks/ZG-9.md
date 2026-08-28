+++
id = "ZG-9"
title = "On a phone show the résumé first and fold the controls into a Theme button"
status = "done"
rank = "q"
labels = ["avril", "round-1", "chrome", "avril-blessed"]
start_at = "2026-08-28T01:14:51.000000Z"
done_at = "2026-08-28T01:49:29.000000Z"
commits = ["6b36edb", "efb8031", "108147e", "b66dabc", "a10f188", "62647b3"]
created = "2026-08-23T23:55:14.306093Z"
updated = "2026-08-28T01:49:29.000000Z"
+++

## Why
When Elena's friend opens her link on a 390px phone they see a control panel and no résumé; the résumé must be the first thing on screen (Elena).
## Covers
F5 — Elena
## Scope in
- `frontend/css/chrome.css` ≤ 720px: the stage (`.garden-stage`) renders first and fills the viewport; the sidebar collapses into a sticky bottom bar with a "Theme" button that opens the sidebar as a sheet (`.app-sidebar--open`)
- Elm: `sidebarOpen : Bool` state, toggle button with `aria-expanded`, Escape closes; body scroll locked while open
- Desktop ≥ 721px layout unchanged
## Scope out
- Redesigning the mobile theme cards (list is enough)
- Touch gestures / swipe between themes
- Native share sheet (Copy link from ZG-8 is enough)
## Acceptance criteria
- [x] Probe `ZG-9/mobile-first`: at 390×844, `document.querySelector('#garden-frame').getBoundingClientRect().top < 80` on load and `.rz-name` inside the iframe is within the visible viewport
- [x] Probe `ZG-9/sheet`: at 390×844 a button with accessible name `Theme` exists with `aria-expanded="false"`; clicking it sets `aria-expanded="true"`, `.app-sidebar` is visible, and `#theme-option-quarto` is clickable; selecting it swaps to `themes/quarto.css` and closes the sheet
- [x] Probe `ZG-9/escape`: with the sheet open, pressing Escape closes it and focus returns to the `Theme` button
- [x] Probe `ZG-9/desktop-unchanged`: at 1280×800 the `Theme` toggle is not visible and the S1–S5 date-geometry probes pass unchanged
- [x] Probe `ZG-9/no-hscroll`: at 390px `document.documentElement.scrollWidth <= 390` for all three themes
- [x] `just verify` green — rust + ZG-9 / U3 / S1–S5 / ZG-8 green; leftover is pre-existing `ZG-11/page-count quarto` (see `docs/plans/zg-9-tester.md`)
## Dependencies
- none
## Notes
- none

## Execution Evidence (commits 6b36edb, efb8031, 108147e, b66dabc, a10f188, 62647b3)

Full probe/unit evidence: `docs/plans/zg-9-execution.md`, `docs/plans/zg-9-tester.md`. Reviewer: `docs/plans/zg-9-reviewer.md`. GAN close: `docs/plans/zg-9-completion.md`.

- [x] `ZG-9/mobile-first` — full probe PASS (`#garden-frame` top 0 < 80; `.rz-name` in the 390×844 viewport)
- [x] `ZG-9/sheet` — full probe PASS (Theme opens the sheet; `#theme-option-quarto` swaps `themes/quarto.css` and closes it)
- [x] `ZG-9/escape` — full probe PASS (Escape closes the sheet and returns focus to Theme)
- [x] `ZG-9/desktop-unchanged` — full probe PASS (Theme toggle hidden at 1280×800; S1–S5 date geometry unchanged)
- [x] `ZG-9/no-hscroll` — full probe PASS (`documentElement.scrollWidth` ≤ 390 for Nightgarden / Quarto / Switchyard)
- [x] `just verify` recipes green except the carved-out ZG-11 quarto long-resume 4-vs-3

GAN: Reviewer BLESS (`a10f188`) → Tester BLESS (`62647b3`) → Architect BLESS. PR #25 left draft. Production not published.
