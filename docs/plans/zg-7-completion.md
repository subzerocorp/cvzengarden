# PBI Completion — ZG-7

## Title
Rewrite the chrome in plain language with an About panel and a free-during-preview line

## Phases
- phase-1 chrome: BLESS reviewer | tester | architect — `2fbb4ff` (Appearance, For screen / For paper, Screen / Paper / Screen + paper, Print / Save as PDF, About dialog)
- phase-2 probes: `1751ba4` (ZG-7/* probes + README) → `4fd68b8` (exact Screen locator) → `797a7a0` (execution evidence)
- Reviewer BLESS `6d360cf` — `docs/plans/zg-7-reviewer.md`
- Tester BLESS `a1f9f36` — 154 unit, isolated ZG-7 PASS, U3 Jordan 2/2/2

## Architecture
Chrome copy and the About dialog live in the chrome layer only. `About` is Closed | Open data; `update` is a calculation that returns `Effect = Focus`; `Main` is the only place that turns that into the `focusId` port. Closed About is off the tree so `document.body.textContent` cannot leak dialog copy. Print action stays `.preview-controls__print` → iframe `print()`. Print preview name is unchanged. Chrome classes stay `about-*` / `appearance__*` / `app-*`; Themes still target `html`/`body`/`.rz-*`/`[data-rz-*]`. `qa/MARKET-QUALITY-BAR.md` is unchanged. Scope stayed ZG-7.

## AC Evidence
On the PBI (`## Execution Evidence`). Tester log: `docs/plans/zg-7-tester.md`. Generator: `docs/plans/zg-7-execution.md`. Reviewer: `docs/plans/zg-7-reviewer.md`.

## Verification matrix
- fmt / clippy pedantic / cargo test (renderer + renderer-wasm): PASS (Tester, rustc 1.87)
- `npm run test:unit`: 154 / 0 (19 `*.test.mjs` via `find`)
- Isolated + full `ZG-7/*` probes: PASS (`no-jargon`, `one-print`, `badges`, `about`, `print-on-white`, `bar-q1`)
- U3 Jordan print: 2/2/2
- Pre-existing `ZG-11/page-count quarto` 4-vs-3: carved out; theme print CSS and `U3_PRINT_PAGES` untouched

## Board
- status: done (`pinto` CLI absent in this VM; `.pinto/tasks/ZG-7.md` written done with `done_at` + commits)

## QA
- Product walk: draft PR #23 for Product & QA; not production
- Production was not walked and was not published

## Follow-ups / non-goals honored
- U3 print CSS / `U3_PRINT_PAGES` / HTTPS / DNS / TLS / issue #9 untouched
- No ZG-8 share control, no ZG-9 mobile, no ZG-10 page count, no ZG-14 kit
- No invented price or launch date
- Print preview toggle not renamed
- PR #23 left open; not merged

ARCHITECTURE VERDICT: BLESSED

Chrome stayed chrome. About is a Closed|Open module whose only action is Focus at the port edge. Themes, Renderer, Skeleton, Class Contract, MARKET-QUALITY-BAR, U3 print path, and HTTPS were not moved. Heading is Appearance; one Print / Save as PDF; For designers is an empty slot. A new senior will still see one iframe sandbox and one Class Contract.

**ARCHITECT BLESS ZG-7**
