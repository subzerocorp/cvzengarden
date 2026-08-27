# ZG-7 Tester — PR #23

Branch `cursor/zg-7-plain-language-chrome-e9ad` @ `6d360cf` (Reviewer BLESS note) vs `main` `8842b9c`.
Tester only. Pinto left `in-progress`. No merge. No second PR. No product change.

Mandates applied: AXEL Tester (run the suite, do not rubber-stamp) + rust-code-tester (run fmt / clippy pedantic / cargo test on rustc 1.87; do not lower rust-version).

## Environment (honest)

Snapshot rustc was **1.83.0**. Crates pin `rust-version = "1.87"`. The bar was **not** lowered. Tester installed `rustc 1.87.0 (17067e9ac 2025-05-09)` in this VM, plus prebuilt `wasm-pack 0.13.1` and `just 1.43.1` (neither on PATH in the snapshot). Playwright Chromium 151.0.7922.34. `just verify` as a single recipe was not re-run after the full probe pass; the four recipes were run separately (see Verification). Frontend half of `just verify` is `npm test` and would exit 1 on the carved-out ZG-11 miss.

## Verdict

**TESTER BLESS ZG-7**

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
static/render.test.mjs
# count: 19 (ZG-6's 18 plus zg-7.test.mjs)

$ npm run test:unit
ℹ tests 154
ℹ pass 154
ℹ fail 0
```

`package.json` `test:unit` is still `node --test --test-reporter=spec $(find scripts static -name '*.test.mjs')`. Under `sh`, `find` is an explicit file list. Suite includes `jargonReasons`, `badgeReasons`, `printNameReasons`, `aboutCopyReasons`, `printOnWhiteReasons`, `guardianReasons`.

### 2. Isolated ZG-7 probes (after `npm run build`)

`PROBE_PORT=4478 node frontend/.tester-zg-7-isolated.mjs` — tester-only runner; starts `serve.mjs`, calls `zg7Probes` from `frontend/scripts/probes/zg-7.mjs`. Deleted after the run. Not committed.

```text
PASS  ZG-7/bar-q1 Independent Product Experience Guardian remains in qa/MARKET-QUALITY-BAR.md
PASS  ZG-7/no-jargon closed chrome textContent has Appearance / For paper / Print / Save as PDF / Pick a look for your résumé and none of the banned developer words
PASS  ZG-7/one-print exactly one Print / action; Print / Save as PDF prints the iframe; Print preview toggle still unique
PASS  ZG-7/badges Nightgarden / Quarto / Switchyard badges read Screen / Paper / Screen + paper
PASS  ZG-7/about About dialog has Free during the preview and the GitHub href; Escape closes and restores focus
PASS  ZG-7/print-on-white switcher textContent claims prints in dark ink on white paper (S3/U3 remain the honesty guard)

All isolated ZG-7 probes passed.
```

`ZG-7/about` asserts href string equality (`https://github.com/subzerocorp/cvzengarden`) and fails if the request log contains a GitHub fetch. Isolated run printed PASS; no GitHub fetch.

### 3. Existing RZ-3 / S1–S5 / U3 (same build)

Full `PROBE_PORT=4479 node scripts/probes.mjs` (log `/tmp/zg7-tester-probes.log`): 137 PASS, 1 FAIL.

U3 Jordan print still 2/2/2:

```text
PASS  U3 nightgarden Garden/iframe printToPDF is 2 pages and ends at Projects
PASS  U3 quarto Garden/iframe printToPDF is 2 pages and ends at Projects
PASS  U3 switchyard Garden/iframe printToPDF is 2 pages and ends at Projects
PASS  U3 nightgarden: chrome-shell printToPDF is 2 pages and ends at Projects
PASS  U3 quarto: chrome-shell printToPDF is 2 pages and ends at Projects
PASS  U3 switchyard: chrome-shell printToPDF is 2 pages and ends at Projects
```

S3 white paper / no motion still green (`S3 Nightgarden print paper is not a dark full-bleed`; `Print preview does not keep Nightgarden screen motion running`; `S3 prefers-reduced-motion kills Nightgarden motion`). RZ-3 identity, S1 swap, S2 dates, S4 Tab/`Print preview`, S5 `?theme=` all PASS in the same run. Selectors `#theme-option-*`, `.preview-controls__print`, button name `Print preview` retained (`ZG-7/one-print` + S4).

Pre-existing environment miss (not a ZG-7 reject; theme print CSS and `U3_PRINT_PAGES` untouched):

```text
FAIL  ZG-11/page-count quarto example.html 2 page(s), long-resume.html 4 page(s): long-resume.html is 4 page(s), LONG_PRINT_PAGES is 3; long-resume.html is 4 page(s), want <= 3
```

Chromium 151. One probe failed in the full suite. Every `ZG-7/*` line in that same run PASSed (repeat of the isolated set). `U3_PRINT_PAGES` still `{nightgarden: 2, quarto: 2, switchyard: 2}` and is not in the `probes.mjs` hunk vs `8842b9c`.

### 4. `just fmt` / clippy pedantic / cargo test (rustc 1.87.0)

| Recipe | Result |
| --- | --- |
| `just fmt` | PASS (renderer + renderer-wasm) |
| `just clippy` | PASS (`-D warnings -D clippy::pedantic`, both crates) |
| `cargo test` renderer | PASS: lib 29, acceptance 10, example 2, fixtures 2, wild 28 |
| `cargo test` renderer-wasm | PASS: 4 |
| `npm run test:unit` | PASS: 154 / 0 |
| `npm run probe` / `just test-frontend` | FAIL only `ZG-11/page-count quarto` 4 vs 3 (carved out) |

No `backend/Cargo.toml`. rust-version left at 1.87.

### 5. MARKET-QUALITY-BAR.md + chrome `rz-`

```text
$ git diff --name-only origin/main...HEAD -- qa/MARKET-QUALITY-BAR.md themes/
# empty

$ git diff --name-only 8842b9c...HEAD -- qa/MARKET-QUALITY-BAR.md themes/
# empty
```

BAR-Q1 name `Independent Product Experience Guardian` still present (file unchanged; `ZG-7/bar-q1` PASS isolated + full). Diff vs `origin/main` is 13 files, all ZG-7 (PBI, execution/reviewer notes, tracking, chrome Elm/CSS, About, ports, probes, README). No theme CSS.

Chrome class/id scan of `frontend/src`, `frontend/css`, `frontend/static` with the static-probe regexes (`class`/`id`/`classList` `rz-`, CSS `#.rz-`) : **none**. Comments may name `.rz-resume` (sandbox contract); chrome does not use the prefix.

HTTPS / DNS / TLS / issue #9 / `U3_PRINT_PAGES` / theme print CSS not touched by this Tester.

## AC checkboxes (Tester-produced evidence)

- [x] `ZG-7/no-jargon` — isolated + full probe PASS (`textContent`, About closed)
- [x] `ZG-7/one-print` — isolated + full probe PASS (one `Print / Save as PDF`; iframe `print()`; unique `Print preview`)
- [x] `ZG-7/badges` — isolated + full probe PASS (Nightgarden Screen, Quarto Paper, Switchyard Screen + paper)
- [x] `ZG-7/about` — isolated + full probe PASS (dialog, Free during the preview, exact GitHub href, Escape + focus)
- [x] `ZG-7/print-on-white` — isolated + full probe PASS; S3/U3 honesty guard green in the same full run
- [x] Existing RZ-3 / S1–S5 / U3 — all PASS; U3 Jordan 2/2/2
- [x] Chrome has no `rz-` class or id; `qa/MARKET-QUALITY-BAR.md` unchanged
- [x] `just verify` recipes green except the carved-out ZG-11 quarto long-resume 4-vs-3

## Rust test gate

ZG-7 added no Rust public API. Regression matrix on rustc 1.87: `just fmt`, pedantic clippy, `cargo test` renderer + renderer-wasm all clean. Arrange = install 1.87 rather than `--ignore-rust-version`; Act = run the recipes; Assert = exit 0. "It works on my machine is not an answer" — these commands were run in this VM.

TEST VERDICT: PASSED

Missing tests:
- none for ZG-7. The only red line this Tester produced is the pre-existing ZG-11 quarto page-count miss.

## Non-goals honored

- U3 print CSS / `U3_PRINT_PAGES` not edited
- DNS / TLS / issue #9 not touched
- Pinto left `in-progress`
- No second ticket or PR
- No merge
- No production deploy

**TESTER BLESS ZG-7**
