# PBI Completion — ZG-10

## Title
Show an honest page count in print preview and how to save a PDF

## Phases
- phase-1 chrome: BLESS reviewer | tester | architect — `8d2e336` (pure `page-estimate.js`, ports CSSOM collect + sync constrained-height measure, Elm Print-preview readout + Save as PDF hint)
- phase-2 probes: `65e9673` (ZG-10/* probes + unit cases + README) → `59707d4` (measure leftover-style mop + probe evidence) → `67221cd` (board log)
- Reviewer BLESS `565b5fc` — `docs/plans/zg-10-reviewer.md`
- Tester BLESS `8286619` — 193 unit, all nine `ZG-10/*` PASS, U3 Jordan 2/2/2

## Architecture
The page estimate lives in the chrome layer only. Paper geometry and the About-N label are pure calculations (`pageGeometry` / `estimatePages` / `estimateLabel`) on immutable page-rule facts. CSSOM walk, the one-task constrained-height measure, and the inbound `pageEstimate` port are actions at the existing `ports.js` edge. Elm stores `Maybe PageEstimate` and renders the readout only in Print preview; the Save as PDF hint is chrome copy under the ZG-7 sentence. Themes still target `html`/`body`/`.rz-*`/`[data-rz-*]` inside the iframe. Print action stays `.preview-controls__print` → iframe `print()`. Print preview name is unchanged. Chrome classes stay `preview-controls__pages` / `preview-controls__hint`; chrome has no `rz-` class or id. `qa/MARKET-QUALITY-BAR.md` is unchanged. ZG-8 Copy link + unknown `?theme=` and ZG-9 Theme sheet stay. Scope stayed ZG-10.

## AC Evidence
On the PBI (`## Execution Evidence`). Tester log: `docs/plans/zg-10-tester.md`. Generator: `docs/plans/zg-10-execution.md`. Reviewer: `docs/plans/zg-10-reviewer.md`.

## Verification matrix
- fmt / clippy pedantic / cargo test (renderer + renderer-wasm): PASS (Tester, rustc 1.87)
- `npm run test:unit`: 193 / 0 (24 `*.test.mjs` via `find`)
- Full `ZG-10/*` probes: PASS (`paper-size`, `paper-size-fallbacks`, `estimate-matches-formula`, `estimate-near-pdf`, `updates-on-switch`, `updates-on-content`, `min-one`, `hint`, `no-guide-lines`)
- S1–S5, U3, ZG-4 / ZG-5 / ZG-6 / ZG-7 / ZG-8 / ZG-9: PASS
- U3 Jordan print: 2/2/2
- Pre-existing `ZG-11/page-count quarto` 4-vs-3: carved out; theme print CSS and `U3_PRINT_PAGES` untouched
- Quarto About N of 2 vs 3: residual (shorter stored sample); formula probe recomputes; not a fail

## Board
- status: done (`pinto` CLI absent in this VM; `.pinto/tasks/ZG-10.md` written done with `done_at` + commits)

## QA
- Product walk: draft PR #26 for Product & QA; not production
- Production was not walked and was not published

## Follow-ups / non-goals honored
- U3 print CSS / `U3_PRINT_PAGES` / HTTPS / DNS / TLS / issue #9 untouched
- No page-boundary guide lines, paged.js, or server PDF pipeline
- No ZG-11 `printableHeightPx` / `long-resume.*` reuse
- Print preview toggle not renamed; `.preview-controls__print` kept; one `Print /` button
- Sample Intent still Swap only
- JSON Resume remains the only stored Resume
- ZG-8 Copy link + unknown `?theme=` unchanged
- ZG-9 phone Theme sheet unchanged
- PR #26 left draft; not merged

ARCHITECTURE VERDICT: BLESSED

Chrome stayed chrome. Geometry is a calculation on page-rule data. Measure and ports stay at the action edge. Themes, Renderer, Skeleton, Class Contract, MARKET-QUALITY-BAR, U3 print path, HTTPS, ZG-8 copy-link, and ZG-9 Theme sheet were not moved. A new senior will still see one iframe sandbox, one Class Contract, and one stored Resume shape.

**ARCHITECT BLESS ZG-10**
