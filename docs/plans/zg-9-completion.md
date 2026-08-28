# PBI Completion — ZG-9

## Title
On a phone show the résumé first and fold the controls into a Theme button

## Phases
- phase-1 chrome: BLESS reviewer | tester | architect — `6b36edb` (`sidebarOpen`, Theme toggle, Escape/`focusId`, ≤720px stage-first + sheet; desktop ≥721px unchanged)
- phase-2 probes: `efb8031` (ZG-9/* probes + README) → `108147e` (board log) → `b66dabc` (desktop toggle hide + probe evidence)
- Reviewer BLESS `a10f188` — `docs/plans/zg-9-reviewer.md`
- Tester BLESS `62647b3` — 177 unit, all five `ZG-9/*` PASS, U3 Jordan 2/2/2

## Architecture
The phone Theme sheet lives in the chrome layer only. `sidebarOpen` is chrome data; toggle / Escape / theme-pick are chrome calculations that return the existing `focusId` action at the port edge. Phone layout is a chrome `@media screen` override after the desktop grid, not a second Skeleton or a Theme. Body scroll lock is chrome presentation (`:has(.app-shell--sidebar-open)` inside the 720px query only). Themes still target `html`/`body`/`.rz-*`/`[data-rz-*]` inside the iframe. Print action stays `.preview-controls__print` → iframe `print()`. Print preview name is unchanged. Chrome classes stay `sidebar-toggle` / `app-sidebar__*` / `app-shell--sidebar-open`; chrome has no `rz-` class or id. `qa/MARKET-QUALITY-BAR.md` is unchanged. ZG-8 Copy link + unknown `?theme=` stay. Scope stayed ZG-9.

## AC Evidence
On the PBI (`## Execution Evidence`). Tester log: `docs/plans/zg-9-tester.md`. Generator: `docs/plans/zg-9-execution.md`. Reviewer: `docs/plans/zg-9-reviewer.md`.

## Verification matrix
- fmt / clippy pedantic / cargo test (renderer + renderer-wasm): PASS (Tester, rustc 1.87)
- `npm run test:unit`: 177 / 0 (22 `*.test.mjs` via `find`)
- Full `ZG-9/*` probes: PASS (`mobile-first`, `sheet`, `escape`, `desktop-unchanged`, `no-hscroll`)
- S1–S5, U3, ZG-4 / ZG-5 / ZG-6 / ZG-7 / ZG-8: PASS
- U3 Jordan print: 2/2/2
- Pre-existing `ZG-11/page-count quarto` 4-vs-3: carved out; theme print CSS and `U3_PRINT_PAGES` untouched

## Board
- status: done (`pinto` CLI absent in this VM; `.pinto/tasks/ZG-9.md` written done with `done_at` + commits)

## QA
- Product walk: draft PR #25 for Product & QA; not production
- Production was not walked and was not published

## Follow-ups / non-goals honored
- U3 print CSS / `U3_PRINT_PAGES` / HTTPS / DNS / TLS / issue #9 untouched
- No mobile theme-card restyle, swipe, or native share
- No ZG-10 page count, no ZG-14 kit, no hosted résumé / Publish
- Print preview toggle not renamed; `.preview-controls__print` kept
- Sample Intent still Swap only
- JSON Resume remains the only stored Resume
- ZG-8 Copy link + unknown `?theme=` unchanged
- PR #25 left draft; not merged

ARCHITECTURE VERDICT: BLESSED

Chrome stayed chrome. Phone sheet is chrome data plus a screen-only presentation override. Focus stays at the existing port edge. Themes, Renderer, Skeleton, Class Contract, MARKET-QUALITY-BAR, U3 print path, HTTPS, and ZG-8 copy-link were not moved. A new senior will still see one iframe sandbox, one Class Contract, and one stored Resume shape.

**ARCHITECT BLESS ZG-9**
