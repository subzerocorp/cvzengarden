# ZG-9 Tester — PR #25

Branch `cursor/zg-9-phone-theme-sheet-d6dc` @ `a10f188` (Reviewer BLESS note) vs `main` `bc664a9`.
Tester only. Pinto left `in-progress`. No merge. No second PR. No product change.

Mandates applied: AXEL Tester (run the suite, do not rubber-stamp) + rust-code-tester (run fmt / clippy pedantic / cargo test on rustc 1.87; do not lower rust-version).

## Environment (honest)

Snapshot rustc was **1.83.0**. Crates pin `rust-version = "1.87"`. The bar was **not** lowered. Tester installed `rustc 1.87.0 (17067e9ac 2025-05-09)` in this VM, plus prebuilt `wasm-pack 0.13.1` and `just 1.43.1` (neither on PATH in the snapshot). Playwright Chromium 151.0.7922.34. `just verify` as a single recipe was not re-run after the full probe pass; the four recipes were run separately (see Verification). Frontend half of `just verify` is `npm test` and would exit 1 on the carved-out ZG-11 miss.

## Verdict

**TESTER BLESS ZG-9**

## Must-run evidence

### 1. `npm run test:unit` + find walk

```text
$ cd frontend && find scripts static -name '*.test.mjs' | sort
scripts/build-wasm.test.mjs
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
scripts/probes/zg-11.test.mjs
scripts/probes/zg-4.test.mjs
scripts/probes/zg-7.test.mjs
scripts/probes/zg-8.test.mjs
scripts/probes/zg-9.test.mjs
static/garden-query.test.mjs
static/render.test.mjs
# count: 22 (ZG-8's 21 plus zg-9.test.mjs)

$ npm run test:unit
ℹ tests 177
ℹ pass 177
ℹ fail 0
```

`package.json` `test:unit` is still `node --test --test-reporter=spec $(find scripts static -name '*.test.mjs')`. Under `sh`, `find` is an explicit file list. Suite includes `mobileFirstReasons`, `nameInViewport`, `sheetClosedReasons`, `sheetOpenReasons`, `themeHrefReasons`, `sheetClosedAfterSelectReasons`, `escapeReasons`, `desktopToggleReasons`, `dateGeometryReasons`, `hscrollReasons`.

### 2. Full probe suite (after `npm run build`)

`PROBE_PORT=4490 node scripts/probes.mjs` (log `/tmp/zg9-tester-probes.log`): 150 PASS, 1 FAIL.

Named ZG-9 probes (all PASS in this run):

```text
PASS  ZG-9/mobile-first #garden-frame top 0 < 80 and .rz-name is in the 390×844 viewport
PASS  ZG-9/sheet Theme opens the sheet; #theme-option-quarto swaps themes/quarto.css and closes it
PASS  ZG-9/escape Escape closes the sheet and returns focus to Theme
PASS  ZG-9/desktop-unchanged Theme toggle hidden at 1280×800; S1–S5 date geometry unchanged
PASS  ZG-9/no-hscroll documentElement.scrollWidth ≤ 390 for all three themes
```

### 3. Existing S1–S5, U3, ZG-4/5/6/7/8 (same build)

U3 Jordan print still 2/2/2:

```text
PASS  U3 nightgarden Garden/iframe printToPDF is 2 pages and ends at Projects
PASS  U3 quarto Garden/iframe printToPDF is 2 pages and ends at Projects
PASS  U3 switchyard Garden/iframe printToPDF is 2 pages and ends at Projects
PASS  U3 nightgarden: chrome-shell printToPDF is 2 pages and ends at Projects
PASS  U3 quarto: chrome-shell printToPDF is 2 pages and ends at Projects
PASS  U3 switchyard: chrome-shell printToPDF is 2 pages and ends at Projects
```

S1–S5, RZ-3, and every `ZG-4/*`, `ZG-5/*`, `ZG-6/*`, `ZG-7/*`, `ZG-8/*` line PASSed in the same run. View toggle still named **Print preview**. `.preview-controls__print` retained (`frontend/src/Main.elm` + `frontend/css/chrome.css`; U3 clicks that class).

`U3_PRINT_PAGES` still `{nightgarden: 2, quarto: 2, switchyard: 2}` and is not in the `probes.mjs` hunk vs `bc664a9`.

Pre-existing environment miss (not a ZG-9 reject; theme print CSS and `U3_PRINT_PAGES` untouched):

```text
FAIL  ZG-11/page-count quarto example.html 2 page(s), long-resume.html 4 page(s): long-resume.html is 4 page(s), LONG_PRINT_PAGES is 3; long-resume.html is 4 page(s), want <= 3
```

Chromium 151. One probe failed in the full suite. Every `ZG-9/*` line in that same run PASSed.

### 4. `just fmt` / clippy pedantic / cargo test (rustc 1.87.0)

| Recipe | Result |
| --- | --- |
| `just fmt` | PASS (renderer + renderer-wasm) |
| `just clippy` | PASS (`-D warnings -D clippy::pedantic`, both crates) |
| `cargo test` renderer | PASS: lib 29, acceptance 10, example 2, fixtures 2, wild 28 |
| `cargo test` renderer-wasm | PASS: 4 |
| `npm run test:unit` | PASS: 177 / 0 |
| `npm run probe` / `just test-frontend` | FAIL only `ZG-11/page-count quarto` 4 vs 3 (carved out) |

No `backend/Cargo.toml`. rust-version left at 1.87.

### 5. Chrome `rz-` + locks

```text
$ git diff --name-only bc664a9...HEAD -- qa/MARKET-QUALITY-BAR.md themes/
# empty
```

Diff vs `main` is 11 files, all ZG-9 (PBI, execution/reviewer notes, tracking, chrome Elm/CSS, probes, README). No theme CSS.

Chrome class/id scan of `frontend/src`, `frontend/css`, `frontend/static` (excluding generated wasm) with the static-probe regexes (`class`/`id`/`classList` `rz-`, CSS `#.rz-`): **none on chrome markup**. Comments and sandbox queries may name `.rz-resume` (skeleton contract); chrome does not use the prefix.

HTTPS / DNS / TLS / issue #9 / `U3_PRINT_PAGES` / theme print CSS not touched by this Tester.

## AC checkboxes (Tester-produced evidence)

- [x] `ZG-9/mobile-first` — full probe PASS (`#garden-frame` top 0 < 80; `.rz-name` in the 390×844 viewport)
- [x] `ZG-9/sheet` — full probe PASS (Theme opens the sheet; `#theme-option-quarto` swaps `themes/quarto.css` and closes it)
- [x] `ZG-9/escape` — full probe PASS (Escape closes the sheet and returns focus to Theme)
- [x] `ZG-9/desktop-unchanged` — full probe PASS (Theme toggle hidden at 1280×800; S1–S5 date geometry unchanged)
- [x] `ZG-9/no-hscroll` — full probe PASS (`documentElement.scrollWidth` ≤ 390 for Nightgarden / Quarto / Switchyard)
- [x] Existing S1–S5 / U3 / ZG-4 / ZG-5 / ZG-6 / ZG-7 / ZG-8 — all PASS; U3 Jordan 2/2/2
- [x] `just verify` recipes green except the carved-out ZG-11 quarto long-resume 4-vs-3

## Rust test gate

ZG-9 added no Rust public API. Regression matrix on rustc 1.87: `just fmt`, pedantic clippy, `cargo test` renderer + renderer-wasm all clean. Arrange = install 1.87 rather than `--ignore-rust-version`; Act = run the recipes; Assert = exit 0. "It works on my machine is not an answer" — these commands were run in this VM.

TEST VERDICT: PASSED

Missing tests:
- none for ZG-9. The only red line this Tester produced is the pre-existing ZG-11 quarto page-count miss.

## Non-goals honored

- U3 print CSS / `U3_PRINT_PAGES` not edited
- DNS / TLS / issue #9 not touched
- Pinto left `in-progress`
- No second ticket or PR
- No merge
- No production deploy
- Print preview toggle not renamed; `.preview-controls__print` kept
- Theme print CSS not edited
- Mobile theme-card restyle / swipe / native share not in this Tester run's product change (Tester wrote no product code)

**TESTER BLESS ZG-9**
