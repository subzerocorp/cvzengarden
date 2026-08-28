# ZG-10 Tester — PR #26

Branch `cursor/zg-10-page-estimate-2615` @ `565b5fc` (Reviewer BLESS note) vs `main` `802c0d5`.
Tester only. Pinto left `in-progress`. No merge. No second PR. No product change.

Mandates applied: AXEL Tester (run the suite, do not rubber-stamp) + rust-code-tester (run fmt / clippy pedantic / cargo test on rustc 1.87; do not lower rust-version).

## Environment (honest)

Snapshot rustc was **1.83.0**. Crates pin `rust-version = "1.87"`. The bar was **not** lowered. Tester installed `rustc 1.87.0 (17067e9ac 2025-05-09)` in this VM, plus prebuilt `wasm-pack 0.13.1` and `just 1.43.1` (neither on PATH in the snapshot). Playwright Chromium 151.0.7922.34. `just verify` as a single recipe was not re-run after the full probe pass; the four recipes were run separately (see Verification). Frontend half of `just verify` is `npm test` and would exit 1 on the carved-out ZG-11 miss.

## Verdict

**TESTER BLESS ZG-10**

## Must-run evidence

### 1. `npm run test:unit` + find walk

```text
$ cd frontend && find scripts static -name '*.test.mjs' | sort
scripts/build-wasm.test.mjs
scripts/page-estimate.test.mjs
scripts/probes/lib/byte-parity.test.mjs
scripts/probes/lib/contrast.test.mjs
scripts/probes/lib/css-structure.test.mjs
scripts/probes/lib/page.test.mjs
scripts/probes/lib/paint.test.mjs
scripts/probes/lib/paste.test.mjs
scripts/probes/lib/pdf.test.mjs
scripts/probes/lib/pixels.test.mjs
scripts/probes/lib/print-geometry.test.mjs
scripts/probes/lib/print-ink.test.mjs
scripts/probes/lib/request-log.test.mjs
scripts/probes/lib/resume-size.test.mjs
scripts/probes/lib/sheet-blocking.test.mjs
scripts/probes/lib/sheet-source.test.mjs
scripts/probes/zg-10.test.mjs
scripts/probes/zg-11.test.mjs
scripts/probes/zg-4.test.mjs
scripts/probes/zg-7.test.mjs
scripts/probes/zg-8.test.mjs
scripts/probes/zg-9.test.mjs
static/garden-query.test.mjs
static/render.test.mjs
# count: 24 (ZG-9's 22 plus page-estimate.test.mjs and zg-10.test.mjs)

$ node --test --test-reporter=spec scripts/page-estimate.test.mjs
ℹ tests 10
ℹ pass 10
ℹ fail 0

$ npm run test:unit
# script is still: node --test --test-reporter=spec $(find scripts static -name '*.test.mjs')
ℹ tests 193
ℹ pass 193
ℹ fail 0
```

`package.json` `test:unit` is still `node --test --test-reporter=spec $(find scripts static -name '*.test.mjs')`. Under `sh`, `find` is an explicit file list. Prescribed `page-estimate.test.mjs` cases all passed: `estimatePages` 0→1 / 946→1 / 946.5→2 / 1892→2 / 1893→3; singular `About 1 page (Letter)`; Letter default 1 cm; Quarto 681.6×945.6; Switchyard 672.8×1009.1; `A4` case; `:first` ignored; fallback tokens; none throw.

### 2. Full probe suite (after `npm run build`)

`PROBE_PORT=4491 node scripts/probes.mjs` (log `/tmp/zg10-tester-probes.log`): 159 PASS, 1 FAIL.

Named ZG-10 probes (all PASS in this run):

```text
PASS  ZG-10/paper-size Quarto and Nightgarden declare Letter; Switchyard declares A4
PASS  ZG-10/paper-size-fallbacks missing @page is Letter/default; 8.5in 11in is Letter/fallback
PASS  ZG-10/estimate-matches-formula readout matches the constrained-height formula (nightgarden 2, quarto 2, switchyard 2)
PASS  ZG-10/estimate-near-pdf nightgarden estimate 2 pdf 2; quarto estimate 2 pdf 2; switchyard estimate 2 pdf 2
PASS  ZG-10/updates-on-switch Quarto Letter → Switchyard A4; estimate settled on 2
PASS  ZG-10/updates-on-content clones raised 2 → 3; remove and Screen/Print preview restored 2
PASS  ZG-10/min-one tiny Quarto résumé reads About 1 page (Letter)
PASS  ZG-10/hint Save as PDF hint is visible in both views under the ZG-7 sentence
PASS  ZG-10/no-guide-lines Print preview has no page-boundary overlay and the iframe html has no leftover style
```

Quarto About N of 2 vs the PBI's informational "today 3" is residual (shorter stored sample). The formula probe recomputes N; this Tester's Jordan readout is 2/2/2. Not a fail.

### 3. Existing S1–S5, S3, U3, ZG-4/5/6/7/8/9 (same build)

U3 Jordan print still 2/2/2:

```text
PASS  U3 nightgarden Garden/iframe printToPDF is 2 pages and ends at Projects
PASS  U3 quarto Garden/iframe printToPDF is 2 pages and ends at Projects
PASS  U3 switchyard Garden/iframe printToPDF is 2 pages and ends at Projects
PASS  U3 nightgarden: chrome-shell printToPDF is 2 pages and ends at Projects
PASS  U3 quarto: chrome-shell printToPDF is 2 pages and ends at Projects
PASS  U3 switchyard: chrome-shell printToPDF is 2 pages and ends at Projects
```

S1–S5, S3, RZ-3, and every `ZG-4/*`, `ZG-5/*`, `ZG-6/*`, `ZG-7/*`, `ZG-8/*`, `ZG-9/*` line PASSed in the same run. View toggle still named **Print preview**. `.preview-controls__print` retained (`frontend/src/Main.elm` + `frontend/css/chrome.css`; U3 clicks that class). Exactly one button whose accessible name starts with `Print /` (`ZG-7/one-print` PASS).

`U3_PRINT_PAGES` still `{nightgarden: 2, quarto: 2, switchyard: 2}` and is not in the `probes.mjs` hunk vs `802c0d5`.

Pre-existing environment miss (not a ZG-10 reject; theme print CSS and `U3_PRINT_PAGES` untouched):

```text
FAIL  ZG-11/page-count quarto example.html 2 page(s), long-resume.html 4 page(s): long-resume.html is 4 page(s), LONG_PRINT_PAGES is 3; long-resume.html is 4 page(s), want <= 3
```

Chromium 151. One probe failed in the full suite. Every `ZG-10/*` line in that same run PASSed.

### 4. `just fmt` / clippy pedantic / cargo test (rustc 1.87.0)

| Recipe | Result |
| --- | --- |
| `just fmt` | PASS (renderer + renderer-wasm) |
| `just clippy` | PASS (`-D warnings -D clippy::pedantic`, both crates) |
| `cargo test` renderer | PASS: lib 29, acceptance 10, example 2, fixtures 2, wild 28 |
| `cargo test` renderer-wasm | PASS: 4 |
| `npm run test:unit` | PASS: 193 / 0 |
| `npm run probe` / `just test-frontend` | FAIL only `ZG-11/page-count quarto` 4 vs 3 (carved out) |

No `backend/Cargo.toml`. rust-version left at 1.87.

### 5. Chrome `rz-` + locks

```text
$ git diff --name-only 802c0d5...HEAD -- qa/MARKET-QUALITY-BAR.md themes/
# empty
```

Diff vs `main` is ZG-10 files only (PBI, execution/reviewer notes, tracking, chrome Elm/CSS, `page-estimate.js`, `ports.js`, probes, README). No theme CSS.

Chrome class/id scan of `frontend/src`, `frontend/css`, `frontend/static` (excluding generated wasm) with the static-probe regexes (`class`/`id`/`classList` `rz-`, CSS `#.rz-`): **none on chrome markup**. Comments and sandbox queries may name `.rz-resume` (skeleton contract); chrome does not use the prefix.

HTTPS / DNS / TLS / issue #9 / `U3_PRINT_PAGES` / theme print CSS not touched by this Tester.

## AC checkboxes (Tester-produced evidence)

- [x] `node --test frontend/scripts/page-estimate.test.mjs` — 10/10 prescribed cases
- [x] `ZG-10/paper-size` — full probe PASS (Quarto + Nightgarden Letter; Switchyard A4)
- [x] `ZG-10/paper-size-fallbacks` — full probe PASS (missing `@page` → Letter/default; `8.5in 11in` → Letter/fallback)
- [x] `ZG-10/estimate-matches-formula` — full probe PASS (nightgarden 2, quarto 2, switchyard 2)
- [x] `ZG-10/estimate-near-pdf` — full probe PASS (2/2, 2/2, 2/2)
- [x] `ZG-10/updates-on-switch` — full probe PASS (Quarto Letter → Switchyard A4; estimate 2)
- [x] `ZG-10/updates-on-content` — full probe PASS (2 → 3 → 2; Screen removes readout)
- [x] `ZG-10/min-one` — full probe PASS (`About 1 page (Letter)`)
- [x] `ZG-10/hint` — full probe PASS (visible in both views under the ZG-7 sentence)
- [x] `ZG-10/no-guide-lines` — full probe PASS (no overlay; iframe `html` has no leftover style)
- [x] Existing S1–S5 / S3 / U3 / ZG-4 / ZG-5 / ZG-6 / ZG-7 / ZG-8 / ZG-9 — all PASS; U3 Jordan 2/2/2
- [x] Diff touches no file under `themes/` and does not edit `U3_PRINT_PAGES`
- [x] `just verify` recipes green except the carved-out ZG-11 quarto long-resume 4-vs-3

## Rust test gate

ZG-10 added no Rust public API. Regression matrix on rustc 1.87: `just fmt`, pedantic clippy, `cargo test` renderer + renderer-wasm all clean. Arrange = install 1.87 rather than `--ignore-rust-version`; Act = run the recipes; Assert = exit 0. "It works on my machine is not an answer" — these commands were run in this VM.

TEST VERDICT: PASSED

Missing tests:
- none for ZG-10. The only red line this Tester produced is the pre-existing ZG-11 quarto page-count miss.

## Non-goals honored

- U3 print CSS / `U3_PRINT_PAGES` not edited
- DNS / TLS / issue #9 not touched
- Pinto left `in-progress`
- No second ticket or PR
- No merge
- No production deploy
- Print preview toggle not renamed; `.preview-controls__print` kept; one `Print /` button
- Theme print CSS not edited
- Page-boundary guide lines / paged.js / server PDF not present
- Tester wrote no product code

**TESTER BLESS ZG-10**
