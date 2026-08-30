# ResumeZen — Implementation Progress

Branch `garden/persona-loop`. Board: Pinto `.pinto/` (key `ZG`). Loop: AVRIL → AXEL → persona walk → repeat until five personas have zero complaints.

## 2026-08-23 — Integration baseline

Merged every open `cursor/*` branch into `garden/persona-loop` (main was only the initial commit). Tree now has: `skeleton/` contract 1.0, `renderer/` (RZ-2, 19 tests green), `themes/` Nightgarden / Quarto / Switchyard (RZ-5), `frontend/` Elm switcher + print preview + S1–S5 hardening + U3 shell print (RZ-3, RZ-S1…S5), `ROADMAP.md`, `qa/MARKET-QUALITY-BAR.md`, `docs/planning/` AVRIL backlog RZ-2…RZ-9.

Baseline matrix:

- `cargo test` (renderer): PASS (19)
- `cargo clippy` pedantic (renderer): **FAIL** (11 `must_use` / `missing_errors_doc` / similar) — not yet fixed; the renderer was written without the pedantic gate.
- `cargo fmt --check`: PASS
- frontend probes: PASS on a free port. (Port 4173 is held by an unrelated local process; use `PROBE_PORT`.)

Harness scaffolded: `AGENTS.md`, `justfile`, `features.json`, this file, `.pinto/` (key `ZG`).

## Verification Status

- Tooling: renderer clippy pedantic red (tracked as harness debt for the first AXEL PBI)
- Reviews: none yet on this branch

## 2026-08-23 — AVRIL round 1 (in progress) and ZG-1 phase 1 of 1

AVRIL round 1 on `docs/plans/round-1-avril-intent.md`: 22 PBIs ZG-1…ZG-22 proposed; as of this entry 17 are triple-blessed (`avril-blessed`), ZG-11/12/19/20/21 are in their final PO→QA→CTO pass, and ZG-23 (deterministic cold-load FOUC probe) is being proposed. Planning docs: `docs/plans/round-1-avril-*.md`.

ZG-1 (renderer clippy pedantic): Generator → Reviewer BLESS → Tester BLESS → Architect BLESS. Commit `59f52ca`. Board `review`, not `done`: the AC "`just verify` exits 0" is blocked by the pre-existing flaky probe `S1 cold load FOUC` (computed-style race; frontend untouched; passes 2 of 3 identical runs). Follow-ups logged in `docs/plans/zg-1-gan-report.md` (Err-path tests for `render_json`, `nonempty` trim test, filter-then-unwrap sites, `RenderError` façade for ZG-4).

## 2026-08-24 — ZG-23 done; ZG-1 done; AVRIL round 1 complete (23/23)

AVRIL round 1 planning stop: `docs/plans/round-1-avril-blessed-backlog.md`. Human decision recorded: license (MIT code / CC BY 4.0 themes / Nathan Sculli). Fonts decision in discussion (ZG-13 may be amended).

ZG-23 (deterministic cold-load FOUC probe): Generator → Reviewer BLESS → Tester BLESS → Architect BLESS. Commit `748892a`. Paint-order oracle inside the sandbox frame; new `frontend/scripts/probes/lib/{paint,sheet-blocking}.mjs`. 10/10 deterministic. Board `done`.

ZG-1: `just verify` green on the same tree (PROBE_PORT=4331). Board `done`. Completion records: `docs/plans/zg-1-completion.md`, `docs/plans/zg-23-completion.md`.

## 2026-08-24 — ZG-11 phase 1 of 2

Long-resume fixture (Marcus Okafor-Lindqvist) byte-locked to crate output (`renderer/tests/fixtures.rs`, table-driven); probe helpers `openResumePage`, `printableWidthPx/HeightPx`, `paginate`, `contrastRatio`, marker/ink readers in `frontend/scripts/probes/lib/`; ZG-11 probes wired; 79 `node:test` unit tests run before the Playwright probes. Anti-vacuity on current sheets recorded (page-1 fill 0.36 / 0.30; Switchyard no print marker; Nightgarden marker 1.30:1, secondary 1.84:1).

GAN: Generator → Reviewer BLESS → Tester REJECT (no unit tests / runner) → fix → Reviewer BLESS → Tester BLESS → Architect BLESS. Commit `79cc260`. Phase 2 (theme CSS + page-count re-baseline) in progress.

## 2026-08-24 — ZG-11 done (phase 2 of 2)

Theme print fixes: sections break, entries stay intact, Switchyard forced break gone, inked markers with print-color-adjust, Nightgarden print ink ≥ 4.5:1; print grids keep the long fixture at 3 pages on all three themes; Jordan 2/2/2. GAN phase 2: Reviewer BLESS → Tester BLESS → Architect BLESS (PDFs judged acceptable to a hiring manager). Board `done`. Completion: `docs/plans/zg-11-completion.md`. ZG-12 started.

## 2026-08-24 — ZG-12 done

Nightgarden long-name fit (container-query clamp + wrap), rz-rise only inside `@supports view()` with fill forwards (sections painted before entry, and in browsers without scroll-driven animation), `white-space: pre-line` ×3 with a §5.3 contract note. GAN: Reviewer BLESS → Tester BLESS → Architect BLESS. Board `done`. Completion: `docs/plans/zg-12-completion.md`. ZG-2 started.

## 2026-08-24 — ZG-2 done

Renderer date hardening (`696ef18`): no panic on any string, timestamps truncate, unparseable → span without datetime, current only from parsed start, calendar validation. GAN: Reviewer BLESS → Tester REJECT (mutant) → fix → BLESS ×3. Board `done`. ZG-3 started.

## 2026-08-24 — ZG-3 done

Wild-file rendering (`84d2a91`): numeric score, url-only entries, span-value profiles, CRLF, safe_href URL hygiene, slug fallbacks, dir="auto" (locks regenerated). emit.rs restructured so empty entries are impossible; ZG-1 unwrap sites gone. GAN BLESS ×3. Board `done`. ZG-4 (Wasm renderer) started.

## 2026-08-24 — ZG-4 phase 1 of 2

`renderer-wasm` adapter crate, `RenderError` façade, `examples/render.rs` parity oracle + tests, rust-version pin, justfile coverage. GAN BLESS ×3. Phase 2 (JS/Elm bridge, sandbox swap, probes) in progress.

## 2026-08-24 — ZG-4 done (phase 2 of 2)

Renderer runs in the browser (`08b8a17`): render.js bridge, sandbox swap, byte parity with the crate on three inputs, 4.8 MiB in 82 ms, zero network. GAN BLESS ×3. Board `done`. ZG-5 (paste) started.

## 2026-08-24 — ZG-5 phase 1 of 2

Paste panel with humane, positioned errors (JsonScan/Classify pure Elm calcs), render through the Wasm bridge, article-only swap. GAN: Reviewer BLESS → Tester REJECT → fix → BLESS ×3. Phase 2 (file/drop, storage, copy) in progress.

## 2026-08-24 — Fonts policy locked

Human decision (`docs/plans/fonts-decision.md`): Font Library (submit original fonts, inbound CC BY 4.0; OFL seeds keep OFL); first-party Themes origin-only; submitted Themes may `@font-face` any public HTTPS CDN font — no host allowlist, CSS only. ZG-13 amended (README AC + notes); Font Library submit product deferred to a later AVRIL PBI. CONTEXT.md + ROADMAP Phase 4 updated. ZG-5 phase 2 continues.

## 2026-08-24 — ZG-5 done (phase 2 of 2)

File/drop (`classifyFile` content-first), `not-json-file` names the file, `localStorage['resumezen.resume']` holds the raw JSON, Forget restores the cloned sample article (no fetch). GAN: Reviewer BLESS → Tester BLESS → Architect BLESS. Tester `PROBE_PORT=4431 just verify` exit 0. Commit `e33212f`. Board `done`. Completion: `docs/plans/zg-5-completion.md`. ZG-6 is next (new `Intent` for sample buttons — do not reuse `ShowIt`).

## 2026-08-27 — ZG-6 in progress

Format named (JSON Resume + schema link), closed-sidebar sentence, copyable Alex Rivera example, Jordan + junior sample buttons as a new `Sample` Intent (no Store). Vendored schema at `b25e3f4bbafd349c2c5bbaa62602c03c228762db`. Junior sample `Sam Okoro` locked in `acceptance.rs`. Board `in-progress`. Evidence: `docs/plans/zg-6-execution.md`. All `ZG-6/*` probes PASS. Draft PR: not production; U3 and HTTPS untouched.

## 2026-08-27 — ZG-6 Tester BLESS (PR #22)

Tester re-ran the suite on `8db67f3`. `npm run test:unit` 147/147 (18 `*.test.mjs` via `find`). Isolated ZG-6 probes all PASS. `junior_sample_html_is_crate_output` PASS on rustc 1.87. U3 Jordan print 2/2/2. Static greps empty as required. Full probes fail only pre-existing `ZG-11/page-count quarto` 4-vs-3 (not a ZG-6 reject). Board left `in-progress`. Verdict: `docs/plans/zg-6-tester.md`.

## 2026-08-27 — ZG-6 Architect BLESS (PR #22)

Architecture holds: third `Paste.Intent` (`Sample`) Swap-only; ShowIt/Author still Stores; one key `resumezen.resume`; JSON Resume only stored Resume; `Generated.Samples` build-embedded; ZG-14 still owns dist copy of `skeleton/samples`; chrome has no `rz-` class/id; Themes still target `html`/`body`/`.rz-*`/`[data-rz-*]`; scope stayed ZG-6; U3 and HTTPS untouched. DoD met. Board `done`. Completion: `docs/plans/zg-6-completion.md`. QA draft host `https://6a90bc39674c4e34c89c8c34--cvzengarden.netlify.app`. PR #22 left open; production not published.

## 2026-08-27 — ZG-7 in progress

Plain-language chrome (Appearance, For screen / For paper, Screen / Paper / Screen + paper, Print / Save as PDF), About dialog with “Free during the preview”, GitHub href string-checked offline. View toggle still **Print preview**. `U3_PRINT_PAGES` and HTTPS / issue #9 untouched. Board `in-progress`, not `done`. Evidence: `docs/plans/zg-7-execution.md`. Draft PR #23 for Product & QA on a Netlify draft host, not production. All `ZG-7/*` probes PASS; U3 2/2/2 PASS. Same-run leftover `ZG-11/page-count quarto` 4-vs-3 is the pre-existing main failure recorded on ZG-6.

## 2026-08-27 — ZG-7 Reviewer BLESS (PR #23)

Walked the full diff vs `main` (`8842b9c…797a7a0`). Every ZG-7 AC holds: closed-chrome `textContent` has the prescribed words and none of the banned jargon; one `Print / Save as PDF` on `.preview-controls__print` still calls iframe `print()`; `Print preview` unique; badges Screen / Paper / Screen + paper; About is `[role=dialog].about-panel` with Free during the preview and the exact GitHub href; designers slot empty; no invented price; chrome has no `rz-` class/id; `MARKET-QUALITY-BAR.md` unchanged; `U3_PRINT_PAGES` and theme print CSS untouched. Pinto left `in-progress`. No merge. Verdict: `docs/plans/zg-7-reviewer.md`.

## 2026-08-27 — ZG-7 Tester BLESS (PR #23)

Tester re-ran the suite on `6d360cf` (rustc 1.87.0 installed; rust-version not lowered). `npm run test:unit` 154/154 including `zg-7.test.mjs`. Isolated ZG-7 probes all PASS (`no-jargon`, `one-print`, `badges`, `about`, `print-on-white`, `bar-q1`). Full probes: RZ-3 / S1–S5 / U3 Jordan 2/2/2 PASS. `just fmt` / clippy pedantic / cargo test green. Chrome has no `rz-` class/id; `MARKET-QUALITY-BAR.md` unchanged. Full probes fail only pre-existing `ZG-11/page-count quarto` 4-vs-3 (not a ZG-7 reject). Board left `in-progress`. Verdict: `docs/plans/zg-7-tester.md`.

## 2026-08-27 — ZG-7 Architect BLESS (PR #23)

Architecture holds: chrome copy is plain language; heading is Appearance not Chrome; one Print / Save as PDF; Print preview name unchanged. About is `[role=dialog].about-panel` with Free during the preview, exact GitHub href, empty For designers slot, no invented price. Chrome has no `rz-` class/id; Themes still target `html`/`body`/`.rz-*`/`[data-rz-*]`; `MARKET-QUALITY-BAR.md` unchanged. Scope stayed ZG-7; U3 and HTTPS untouched. DoD met. Board `done`. Completion: `docs/plans/zg-7-completion.md`. PR #23 left open; production not published.

## 2026-08-28 — ZG-8 in progress

Copy link (`.copy-link`) writes `location.href`; 2 s Copied; reject → `Copy failed — select the address bar and copy it` (never Copied). `view=print|screen` mirrors the Print preview toggle. Unknown `?theme=` keeps the URL and names the miss in Elm `text`. `ThemeId.fromQuery` is `Known | Unknown | Absent`. Board `in-progress`, not `done`. Evidence: `docs/plans/zg-8-execution.md`. Draft PR #24. All `ZG-8/*` probes PASS; S4 permalink + Back, S5, U3 2/2/2, ZG-7 PASS. Same-run leftover `ZG-11/page-count quarto` 4-vs-3 is the pre-existing main failure. U3 and HTTPS untouched.

## 2026-08-28 — ZG-8 Reviewer BLESS (PR #24)

Walked the full diff vs `main` (`f0a5ab2…7a88fa6`). Every ZG-8 AC holds: `.copy-link` writes `location.href`; 2 s `Copied`; reject → address-bar sentence and never `Copied`; `view=print|screen` shares `gardenSearch` with `theme`; unknown `?theme=` keeps the URL and names the miss in Elm `text`; `ThemeId.fromQuery` is `Known | Unknown | Absent`. Named probes present. Locks hold (`Print preview`, `.preview-controls__print`, no chrome `rz-`, `U3_PRINT_PAGES` 2/2/2, Sample does not Store, `test:unit` find-glob untouched). Pinto left `in-progress`. No merge. Verdict: `docs/plans/zg-8-reviewer.md`.

## 2026-08-28 — ZG-8 Tester BLESS (PR #24)

Tester re-ran the suite on `f40b8bb` (rustc 1.87.0 installed; rust-version not lowered). `npm run test:unit` 167/167 including `zg-8.test.mjs` and `garden-query.test.mjs`. Full probes (`PROBE_PORT=4489`): all eight `ZG-8/*` PASS; S4 permalink + Back, S5, U3 Jordan 2/2/2, ZG-4/5/6/7 PASS. `just fmt` / clippy pedantic / cargo test green. View toggle still **Print preview**; `.preview-controls__print` kept. Full probes fail only pre-existing `ZG-11/page-count quarto` 4-vs-3 (not a ZG-8 reject). Board left `in-progress`. Verdict: `docs/plans/zg-8-tester.md`.

## 2026-08-28 — ZG-8 Architect BLESS (PR #24)

Architecture holds: ThemeId.fromQuery is Known|Unknown|Absent; gardenSearch is the same generation as theme; history and clipboard stay in ports.js; CopyLink is Idle|Copied|Failed with CopyHref at the port edge. Unknown ?theme= is not rewritten. Chrome has no `rz-` class/id; Themes still target `html`/`body`/`.rz-*`/`[data-rz-*]`; `MARKET-QUALITY-BAR.md` unchanged. Locks hold (Print preview, `.preview-controls__print`, Sample does not Store, U3 2/2/2). Scope stayed ZG-8; U3 and HTTPS untouched. DoD met. Board `done`. Completion: `docs/plans/zg-8-completion.md`. PR #24 left draft; production not published.

## 2026-08-28 — ZG-9 phase 1 of 2

Phone résumé first: `sidebarOpen : Bool`, Theme toggle (`aria-expanded`), Escape + `focusId`, selecting a Theme closes the sheet. ≤720px CSS puts `.garden-stage` first and fills the viewport; `.app-sidebar` is a sticky bottom bar; `.app-sidebar--open` is the sheet. Desktop ≥721px grid unchanged. Board `in-progress`. Plan: `docs/plans/zg-9-execution.md`. U3, HTTPS, theme print CSS, ZG-8 Copied flash, and `MARKET-QUALITY-BAR.md` untouched.

## 2026-08-28 — ZG-9 phase 2 of 2

Named probes `ZG-9/mobile-first`, `sheet`, `escape`, `desktop-unchanged`, `no-hscroll` plus unit-tested calculations (`zg-9.test.mjs`). Tester README mentions the phone Theme sheet. Board stays `in-progress`. Probe evidence pending.

## 2026-08-28 — ZG-9 in progress (evidence)

All five `ZG-9/*` probes PASS at 390×844 / 1280×800. Existing RZ-3 / S1–S5 / U3 Jordan 2/2/2 / ZG-4/5/6/7/8 PASS. `npm run test:unit` 177/177. Rust fmt / clippy pedantic / cargo test green on rustc 1.87.0. Same-run leftover `ZG-11/page-count quarto` 4-vs-3 is the pre-existing main failure. Board `in-progress`, not `done`. Evidence: `docs/plans/zg-9-execution.md`. Draft PR #25. U3, HTTPS, theme print CSS, ZG-8 Copied flash, and `MARKET-QUALITY-BAR.md` untouched.

## 2026-08-28 — ZG-9 Reviewer BLESS (PR #25)

Walked the full diff vs `main` (`bc664a9…b66dabc`). Every ZG-9 AC holds: ≤720px stage-first + Theme sheet; `sidebarOpen` / `aria-expanded` / Escape + `focusId`; body lock only inside the 720px query; desktop ≥721px toggle hidden and grid unchanged. Named probes present. Locks hold (`Print preview`, `.preview-controls__print`, no chrome `rz-`, `U3_PRINT_PAGES` 2/2/2, Sample does not Store, `test:unit` find-glob untouched, ZG-8 copy-link + unknown `?theme=` untouched). Pinto left `in-progress`. No merge. Verdict: `docs/plans/zg-9-reviewer.md`.

## 2026-08-28 — ZG-9 Tester BLESS (PR #25)

Tester re-ran the suite on `a10f188` (rustc 1.87.0 installed; rust-version not lowered). `npm run test:unit` 177/177 including `zg-9.test.mjs`. Full probes (`PROBE_PORT=4490`): all five `ZG-9/*` PASS; S1–S5, U3 Jordan 2/2/2, ZG-4/5/6/7/8 PASS. `just fmt` / clippy pedantic / cargo test green. View toggle still **Print preview**; `.preview-controls__print` kept. Full probes fail only pre-existing `ZG-11/page-count quarto` 4-vs-3 (not a ZG-9 reject). Board left `in-progress`. Verdict: `docs/plans/zg-9-tester.md`.

## 2026-08-28 — ZG-9 Architect BLESS (PR #25)

Architecture holds: phone Theme sheet is chrome data (`sidebarOpen`) plus a screen-only presentation override; Escape/`focusId` stay at the existing port edge. Chrome has no `rz-` class/id; Themes still target `html`/`body`/`.rz-*`/`[data-rz-*]`; `MARKET-QUALITY-BAR.md` unchanged. Locks hold (Print preview, `.preview-controls__print`, Sample does not Store, U3 2/2/2, ZG-8 copy-link + unknown `?theme=`). Scope stayed ZG-9; U3 and HTTPS untouched. DoD met. Board `done`. Completion: `docs/plans/zg-9-completion.md`. PR #25 left draft; production not published.

## 2026-08-28 — ZG-10 phase 1 of 2

Pure `page-estimate.js` (`pageGeometry` / `estimatePages` / `estimateLabel`) plus `ports.js` `collectPageRules`, sync constrained-height measure, and rAF-coalesced inbound `pageEstimate`. Elm readout only in Print preview; Save as PDF hint in both views after the ZG-7 sentence. Board `in-progress`. Plan: `docs/plans/zg-10-execution.md`. `themes/` and `U3_PRINT_PAGES` untouched.

## 2026-08-28 — ZG-10 phase 2 of 2

Named probes `ZG-10/paper-size`, `paper-size-fallbacks`, `estimate-matches-formula`, `estimate-near-pdf`, `updates-on-switch`, `updates-on-content`, `min-one`, `hint`, `no-guide-lines` plus prescribed `page-estimate.test.mjs` cases. Tester README mentions About N pages and the print-dialog hint. Board stays `in-progress`. Probe evidence pending.

## 2026-08-28 — ZG-10 in progress (evidence)

All nine `ZG-10/*` probes PASS. Existing RZ-3 / S1–S5 / U3 Jordan 2/2/2 / ZG-4/5/6/7/8/9 PASS. `npm run test:unit` 193/193. Rust fmt / clippy pedantic / cargo test green on rustc 1.87.0. Same-run leftover `ZG-11/page-count quarto` 4-vs-3 is the pre-existing main failure. Board `in-progress`, not `done`. Evidence: `docs/plans/zg-10-execution.md`. Draft PR #26. U3, HTTPS, theme print CSS, ZG-8 Copied flash, and `MARKET-QUALITY-BAR.md` untouched.

## 2026-08-28 — ZG-10 Reviewer BLESS (PR #26)

Review only. Diff vs `802c0d5` is 14 ZG-10 files. Pure `page-estimate.js`, ports measure, Elm Print-preview readout, `[data-pdf-hint]` after the ZG-7 sentence, named `ZG-10/*` probes, and prescribed unit cases are present. Locks hold (Print preview, `.preview-controls__print`, one `Print /` button, no chrome `rz-`, U3 2/2/2, ZG-8 copy-link + unknown theme, ZG-9 Theme sheet). `themes/` and `U3_PRINT_PAGES` untouched. Carved-out `ZG-11/page-count quarto` not a reject. Board stays `in-progress`. Verdict: `docs/plans/zg-10-reviewer.md`.

## 2026-08-28 — ZG-10 Tester BLESS (PR #26)

Tester re-ran the suite on `565b5fc` (rustc 1.87.0 installed; rust-version not lowered). `npm run test:unit` 193/193 including `page-estimate.test.mjs` and `zg-10.test.mjs`. Full probes (`PROBE_PORT=4491`): all nine `ZG-10/*` PASS; S1–S5, S3, U3 Jordan 2/2/2, ZG-4/5/6/7/8/9 PASS. `just fmt` / clippy pedantic / cargo test green. View toggle still **Print preview**; `.preview-controls__print` kept; one `Print /` button. Full probes fail only pre-existing `ZG-11/page-count quarto` 4-vs-3 (not a ZG-10 reject). Quarto About N of 2 vs 3 is residual (shorter stored sample). Board left `in-progress`. Verdict: `docs/plans/zg-10-tester.md`.

## 2026-08-28 — ZG-10 Architect BLESS (PR #26)

Architecture holds: page estimate is chrome data (`Maybe PageEstimate`) plus pure geometry calculations; CSSOM collect and the one-task constrained-height measure stay at the `ports.js` edge. Chrome has no `rz-` class/id; Themes still target `html`/`body`/`.rz-*`/`[data-rz-*]`; `MARKET-QUALITY-BAR.md` unchanged. Locks hold (Print preview, `.preview-controls__print`, one `Print /` button, Sample does not Store, U3 2/2/2, ZG-8 copy-link + unknown `?theme=`, ZG-9 Theme sheet). Scope stayed ZG-10; U3 and HTTPS untouched. DoD met. Board `done`. Completion: `docs/plans/zg-10-completion.md`. PR #26 left draft; production not published.

## 2026-08-28 — ZG-13 in progress (evidence)

Self-hosted first-party faces (EB Garamond, IBM Plex Sans, Syne, Outfit) under `themes/fonts/` with `OFL.txt`. `@font-face` is `local()` then `url("fonts/…")`. No jsDelivr. All five named probes PASS: `ZG-13/no-third-party`, `font-files`, `fonts-load`, `fallback` (ignored 11 font-load errors), `BAR-L1 PASS`. U3 Jordan still 2/2/2 — same-face swap did not reflow. `U3_PRINT_PAGES` / `LONG_PRINT_PAGES` untouched. `npm run test:unit` 206/206. Rust fmt / clippy pedantic / cargo test green on rustc 1.87.0. Same-run leftover `ZG-11/page-count quarto` 4-vs-3 is the pre-existing main failure. Board `in-progress`, not `done`. Evidence: `docs/plans/zg-13-execution.md`. Draft PR #27. HTTPS / issue #9 untouched.

## 2026-08-28 — ZG-13 Tester BLESS (PR #27)

Tester re-ran the suite on `83d4a09` (rustc 1.87.0 installed; rust-version not lowered). `npm run test:unit` 206/206 including `theme-fonts.test.mjs` and `zg-13.test.mjs`. Isolated + full probes (`PROBE_PORT=4521` / `4522`): all five named ZG-13 lines PASS; `BAR-L1 PASS`; S3/U3 Jordan 2/2/2. `grep -rn jsdelivr themes/*.css` empty; `@font-face` 4/4/5. `just fmt` / clippy pedantic / cargo test green. Full probes fail only pre-existing `ZG-11/page-count quarto` 4-vs-3 (not a ZG-13 reject). Board left `in-progress`. PR left draft. Verdict: `docs/plans/zg-13-tester.md`.

## 2026-08-28 — ZG-13 Architect BLESS (PR #27)

Architecture holds: first-party faces are Theme-layer Font Library seed data (`themes/fonts/` + `OFL.txt`); each Theme stays one pure CSS file with `local()` then origin-relative `url("fonts/…")`; no JS webfont loader. Chrome has no `rz-` class/id; Themes still target `html`/`body`/`.rz-*`/`[data-rz-*]`. Probe calculations stay in `theme-fonts.mjs`; actions stay in `zg-13.mjs`. Font Library policy on `themes/README.md` (CC BY 4.0 inbound, HTTPS CDN for submitted Themes, no host allowlist, first-party never phones a CDN). Locks hold (U3 2/2/2, constants untouched, no typeface change, no print re-baseline, HTTPS / issue #9 untouched). Scope stayed ZG-13. Residual ZG-11 quarto 4-vs-3 is not a hold. Reviewer BLESS already on disk (`83d4a09` / `docs/plans/zg-13-reviewer.md`). DoD met except the noted leftover `just verify` line. Board `done`. Completion: `docs/plans/zg-13-completion.md`. PR #27 left draft; production stays ZG-10; CoS holds ship.

## 2026-08-28 — Pinto is the only planning SoT

`features.json` retired. Every commit it tracked already had a ZG card (`pinto list --json`: 23 items, 14 done / 9 todo). Shared DoD and open cards ZG-19/20/21 now say board I/O is the `pinto` CLI only — never hand-edit `.pinto/tasks/*.md`. `just status` / `scripts/status-dashboard` / `.opencode` preflight count from `pinto list --json` only. No new ZGs. No Garden / walk-in / host / DNS change.

## 2026-08-30 — ZG-11 quarto page-count fixed; `just verify` green

`ZG-11/page-count quarto` (long-resume 4 pages, `LONG_PRINT_PAGES` 3, `MAX_LONG_PAGES` 3) was carried as "pre-existing" through ZG-13 execution, Tester and Architect. It was not a regression: quarto renders the long fixture at 4 pages with the ZG-11-era sheet (`9164681`), with the pre-ZG-3 fixture (`79cc260`), and with `**/themes/fonts/**` aborted — the constant was never satisfiable on the pinned browser. Chromium rev 1194 is what `playwright-core` 1.56.1 pins, so the reading is authoritative; `printToPdf` sends its own CDP params (`preferCSSPageSize`), so the driver version does not enter into it.

Fixed in `themes/quarto.css` `@media print` — whitespace only, no type change: `.rz-header` 0.8→0.55rem / 0.5→0.4rem, `.rz-section` 0.35→0.16rem, `.rz-entry` 0.25→0.18rem. Quarto has the shortest printable height (952px vs 1009 / 995), so it runs out of page first; the gaps are commented as load-bearing. long-resume quarto 4→3; `U3_PRINT_PAGES` untouched (Jordan still 2/2/2); `page1-fill` 0.91→0.90 (≥0.85); `#rz-experience` 999.9→995.4px, still above 952 for `fixture-trips-e1`. Print-scale headroom now matches switchyard exactly (3 pages at 1.01, 4 at 1.02).

`just verify` exits 0 — fmt, clippy pedantic, cargo test, 165 probes, no failures. First green run on record. `LONG_PRINT_PAGES` and `MAX_LONG_PAGES` left at 3; no board move, no fixture change.

## 2026-08-30 — ZG-16: every theme card credits its designer

`generate.mjs parseTheme` now reads `Author:` and `URL:` from the theme header and is exported behind a main guard so the unit test can import it without running the generator. `URL:` goes through `safeThemeUrl`: only `http`/`https` survives, so a designer-supplied header cannot put `javascript:` or `data:` into an href. `Generated.Themes.Theme` gains `author : String` and `url : Maybe String`; the compiler caught `ThemeId.fallbackTheme`, whose synthesised record now carries no author rather than an invented one.

Cards render `by <author>` under the name, linked when the theme has a URL. First-party headers are `Author: ResumeZen` / `URL: https://github.com/subzerocorp/cvzengarden`. No `Author:` line means no `.theme-switcher__author` at all. `themes/_blank.css` gained a `URL:` line; `themes/README.md` documents all five header fields with a worked example.

The link sits inside the option button, so `stopPropagationOn "click"` keeps crediting a designer from swapping the reader's theme — measured, not assumed: Chromium fires both the link and the button handler without it. It is also its own tab stop, which invalidated S4's assumption that one Tab from nightgarden reaches quarto; `probes.mjs` now focuses `#theme-option-quarto` directly. Same claim, no adjacency assumption.

New probes `ZG-16/byline`, `ZG-16/byline-link`, `ZG-16/no-fake-byline` (the last writes an authorless lab theme, regenerates, asserts the card exists with no byline, and deletes it in `finally`). `just verify` exits 0 — 170 probes, `npm run test:unit` 212/212. Screenshot `/tmp/zg16-switcher.png`. Board `review`, not `done`: the DoD's Reviewer / Tester / Architect BLESS ritual has not been run.

## 2026-08-30 — ZG-16 cycle 2: byline is a sibling of the option button

Reviewer REJECT of `5529b3f` (`docs/plans/zg-16-reviewer.md`), five blockers. AC1 amended: the card, not the button, is what "contains" the byline.

The card is now `li.theme-switcher__item` — it owns the border, radius, background, `--selected` and hover; `#theme-option-*` stays the focusable `<button>` with `aria-pressed` and `onClick`, and `.theme-switcher__author` is its sibling. `button` forbids interactive descendants, and `role=button` is children-presentational, so the nested `<a>` was a tab stop assistive tech never exposed as a link. Outside the button the link cannot reach the selection handler, so `stopPropagationOn`, the `NoOp` Msg and its `update` branch, and the three `order:` rules all went with it; the duplicate `.theme-switcher__option` / `__name` blocks are merged. S4 is back to `focus(nightgarden)` + Tab ×2 — measured, the walk is option → byline link → next option, which also pins the byline's tab position.

`parseTheme` reads `rz-target` only as its own `/* … */` comment, so `themes/README.md`'s worked example (and `themes/_blank.css:8`, pre-existing since `43517f9`) taught a form that silently parses as `Both`. Both moved to the line-1 form; the README says which comment each field lives in and why. The parser is unchanged — the line-1 form is what `CLASS-CONTRACT.md` §2 and all three first-party themes already use.

`generate.test.mjs`'s import guard test asserted only `typeof parseTheme === "function"`. It now spawns a child that imports the module and asserts no `Generated N theme(s)` line and a byte-identical `src/Generated/Themes.elm`; with the guard deleted it fails. `probes/zg-16.test.mjs` covers all six `bylineReasons` branches plus the pass case, and the lab probe grew a second theme — `Author:` with no `URL:` — so both `viewByline` branches are exercised; both files are deleted and the catalog regenerated in `finally`.

Should-fixes: the entry-point guard now bails on an undefined `process.argv[1]` and compares `fs.realpathSync` (a symlinked `npm run gen` was a silent no-op), in `generate.mjs` and `build-wasm.mjs`; `safeThemeUrl` returns `parsed.href`; a non-empty `URL:` that is dropped now warns instead of vanishing. `rel="nofollow ugc"` is deferred — no submitted themes yet.

`just verify` exits 0 — fmt, clippy pedantic, cargo test, 171 probes, `npm run test:unit` 225/225. Board unmoved; the three-adversary chain restarts from scratch.

## 2026-08-30 — ZG-16 cycle 3: the option button is the card again

Reviewer REJECT of `8af53d2` (`docs/plans/zg-16-reviewer.md`), two blockers; blocker 2 (AC2's stated value) was settled by the conductor on the board, so this is the fix for blocker 1.

Moving the frame onto the `li` moved the hit box with it: measured at 1280×800 the card was 259.8×55.2 while `#theme-option-*` was 237×18.2 — 30% of the card's area — and `elementFromPoint` at the card's inner corner returned the `li`, where a click selects nothing, yet the whole card lightened on hover. The card's inset now lives on its children instead of the `li`: the button carries `0.55rem 0.65rem 0.15rem` and `.theme-switcher__author` carries the rest (`0 0.65rem 0.55rem`), so the button measures 257.8×29.4 — the card's full padding-box width and everything down to the byline's own box, 55.2% of the card's height, with the byline row the only region a click can miss. Hover moved from `.theme-switcher__item:hover` to `.theme-switcher__option:hover`, so no pixel lightens that a click cannot take, and `.theme-switcher__option:last-child` recovers the bottom inset for a theme that renders no byline at all.

New probe `ZG-16/hit-box` pins it: per card it reads the `li`'s padding box, the button's border box and the byline's box, then samples five points, parking the pointer away and moving it onto each to see which ones lighten. `hitBoxReasons` is the calculation — the option must span the card's width, start flush with its top, reach the byline row and cover at least half the height; nothing outside the option may lighten; and at least one point inside it must (the current selection is exempt, since `--accent` and `--sidebar-accent` are the same value, so it is already painted at the hover tint). Restoring `8af53d2`'s `chrome.css` turns all three cards red with the measured numbers.

Should-fixes: S4's focus-ring filter now includes `theme-switcher__author-link`, so the byline link's ring is asserted rather than skipped — dropping the rule turns S4 red. `labBylineProbe` no longer cleans up in a `finally`: cleanup runs after the probe body, reports its own failure as `ZG-16/lab-cleanup`, and re-throws the probe's original error, so a rebuild error can never replace it. `zg-16.mjs` no longer recomputes `repoDir`/`frontendDir` as module constants that shadow the runner's injected parameters. `noFakeBylineReasons` and `plainBylineReasons` are extracted and unit-tested, which makes the module header's action/calculation claim honest. `suspectThemeHost` warns at build time about a kept URL whose host has no dot and is not `localhost` — `https:alert(1)` and `http:evil` parse as live, permanently broken links; the scheme filter is untouched and its hostile-input cases still pass.

Follow-up, not done here: the lab probe still writes into tracked `themes/`. `mkdtempSync` plus a themes-dir override for `generate.mjs` (per `zg-5.mjs:351`) is a cleanly separable change.

`just verify` exits 0 — fmt, clippy pedantic, cargo test, 174 probes, `npm run test:unit` 242/242. Board unmoved; nothing committed.
