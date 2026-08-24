+++
id = "ZG-9"
title = "On a phone show the résumé first and fold the controls into a Theme button"
status = "todo"
rank = "q"
labels = ["avril", "round-1", "avril-blessed"]
created = "2026-08-23T23:55:14.306093Z"
updated = "2026-08-24T01:13:07.439802Z"
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
- [ ] Probe `ZG-9/mobile-first`: at 390×844, `document.querySelector('#garden-frame').getBoundingClientRect().top < 80` on load and `.rz-name` inside the iframe is within the visible viewport
- [ ] Probe `ZG-9/sheet`: at 390×844 a button with accessible name `Theme` exists with `aria-expanded="false"`; clicking it sets `aria-expanded="true"`, `.app-sidebar` is visible, and `#theme-option-quarto` is clickable; selecting it swaps to `themes/quarto.css` and closes the sheet
- [ ] Probe `ZG-9/escape`: with the sheet open, pressing Escape closes it and focus returns to the `Theme` button
- [ ] Probe `ZG-9/desktop-unchanged`: at 1280×800 the `Theme` toggle is not visible and the S1–S5 date-geometry probes pass unchanged
- [ ] Probe `ZG-9/no-hscroll`: at 390px `document.documentElement.scrollWidth <= 390` for all three themes
- [ ] `just verify` green
## Dependencies
- none
## Notes
- none
