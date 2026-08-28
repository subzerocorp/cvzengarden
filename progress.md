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
