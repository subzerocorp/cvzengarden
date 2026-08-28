# PBI Completion — ZG-8

## Title
Copy a link to this exact view and say so when a theme in the URL does not exist

## Phases
- phase-1 chrome: BLESS reviewer | tester | architect — `f7af6b0` (ThemeId `Known | Unknown | Absent`, `view=print|screen`, `.copy-link`, unknown notice)
- phase-2 probes: `56bcc18` (ZG-8/* probes + README) → `7a88fa6` (execution evidence)
- Reviewer BLESS `f40b8bb` — `docs/plans/zg-8-reviewer.md`
- Tester BLESS `52c6c26` — 167 unit, all eight `ZG-8/*` PASS, U3 Jordan 2/2/2

## Architecture
Copy link and the unknown-theme notice live in the chrome layer only. `ThemeId.fromQuery` is a pure calculation (`Known id | Unknown raw | Absent`); `gardenSearch` / `readGardenQuery` are pure search math; history and clipboard stay in `ports.js`. `CopyLink` is Idle | Copied | Failed data; `update` is a calculation that returns `Effect = CopyHref | WaitClear`; `Main` is the only place that turns those into the `copyLink` port. Unknown `?theme=` is never rewritten. Author Resume is not added to the search string. Print action stays `.preview-controls__print` → iframe `print()`. Print preview name is unchanged. Chrome classes stay `copy-link` / `theme-notice*`; Themes still target `html`/`body`/`.rz-*`/`[data-rz-*]`. `qa/MARKET-QUALITY-BAR.md` is unchanged. Scope stayed ZG-8.

## AC Evidence
On the PBI (`## Execution Evidence`). Tester log: `docs/plans/zg-8-tester.md`. Generator: `docs/plans/zg-8-execution.md`. Reviewer: `docs/plans/zg-8-reviewer.md`.

## Verification matrix
- fmt / clippy pedantic / cargo test (renderer + renderer-wasm): PASS (Tester, rustc 1.87)
- `npm run test:unit`: 167 / 0 (21 `*.test.mjs` via `find`)
- Full `ZG-8/*` probes: PASS (`copy-link`, `copy-failed`, `view-url`, `view-back`, `unknown-theme`, `notice-escaped`, `no-notice`, `invalid-view`)
- S4 permalink + Back, S5, U3, ZG-4 / ZG-5 / ZG-6 / ZG-7: PASS
- U3 Jordan print: 2/2/2
- Pre-existing `ZG-11/page-count quarto` 4-vs-3: carved out; theme print CSS and `U3_PRINT_PAGES` untouched

## Board
- status: done (`pinto` CLI absent in this VM; `.pinto/tasks/ZG-8.md` written done with `done_at` + commits)

## QA
- Product walk: draft PR #24 for Product & QA; not production
- Production was not walked and was not published

## Follow-ups / non-goals honored
- U3 print CSS / `U3_PRINT_PAGES` / HTTPS / DNS / TLS / issue #9 untouched
- No hosted résumé / Publish (ZG-22), no ZG-9 mobile, no ZG-10 page count, no ZG-14 kit
- Unknown `?theme=` not rewritten to the fallback
- Author Resume not persisted in the URL
- Print preview toggle not renamed; `.preview-controls__print` kept
- Sample Intent still Swap only
- PR #24 left draft; not merged

ARCHITECTURE VERDICT: BLESSED

Chrome stayed chrome. Theme classification is a Known|Unknown|Absent calculation. History and clipboard are actions at the port edge. Themes, Renderer, Skeleton, Class Contract, MARKET-QUALITY-BAR, U3 print path, and HTTPS were not moved. A new senior will still see one iframe sandbox, one Class Contract, and one stored Resume shape.

**ARCHITECT BLESS ZG-8**
