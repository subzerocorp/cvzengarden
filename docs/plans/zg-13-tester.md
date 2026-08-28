# ZG-13 Tester — PR #27

Branch `cursor/zg-13-self-host-fonts-c1ee` @ `83d4a09` (Reviewer BLESS note) vs merge-base `7dc0550` (PR #26 on `main`).
Tester only. Pinto left `in-progress`. No merge. No ready. No product change.

Mandates applied (recited before the run):

- code-writer: “Write code that is layered, modular, and built from pure calculations operating on immutable data; isolate all actions; prefer the language’s standard library; use abstraction and higher-order functions to control complexity so that any human reader can understand and safely modify the system.”
- rust-code-writer: “Write stratified, functionally pure Rust with flat combinators and `?` first, dedicated thiserror enums per layer plus From impls, aggressive newtypes and exhaustive matching, zero `.unwrap()` in production paths, and pedantic tooling — delivering code that is obvious, safe, and a delight for any human maintainer.”
- rust-code-tester: “Ensure every calculation and public item has complete, layered, deterministic tests following Arrange-Act-Assert with exhaustive error-path coverage so the codebase stays reliably maintainable, verifiable, and handover-clean — zero tolerance, delegate all fixes.”

AXEL Tester: run the suite, do not rubber-stamp. rust-code-tester: run fmt / clippy pedantic / cargo test on rustc 1.87; do not lower rust-version.

## Environment (honest)

Snapshot rustc was **1.83.0**. Crates pin `rust-version = "1.87"`. The bar was **not** lowered. Tester installed `rustc 1.87.0 (17067e9ac 2025-05-09)` in this VM, plus prebuilt `wasm-pack 0.13.1` and `just 1.43.1` (neither on PATH in the snapshot). Playwright Chromium 151.0.7922.34. `just verify` as a single recipe was not re-run after the full probe pass; the four recipes were run separately (see Verification). Frontend half of `just verify` is `npm test` and would exit 1 on the carved-out ZG-11 miss.

## Verdict

**TESTER BLESS ZG-13**

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
scripts/probes/lib/theme-fonts.test.mjs
scripts/probes/zg-10.test.mjs
scripts/probes/zg-11.test.mjs
scripts/probes/zg-13.test.mjs
scripts/probes/zg-4.test.mjs
scripts/probes/zg-7.test.mjs
scripts/probes/zg-8.test.mjs
scripts/probes/zg-9.test.mjs
static/garden-query.test.mjs
static/render.test.mjs
# count: 26 (ZG-10's 24 plus theme-fonts.test.mjs and zg-13.test.mjs)

$ npm run test:unit
# script is still: node --test --test-reporter=spec $(find scripts static -name '*.test.mjs')
ℹ tests 206
ℹ pass 206
ℹ fail 0
```

ZG-13 unit files green: `theme-fonts.test.mjs` (brace-matched `@font-face`, host filter, fetch reasons, FontFace reasons, BAR-L1 pair differ, fallback console filter, S2 + BAR-U2 layout) and `zg-13.test.mjs` (re-export stability). Generator's 206/206 reproduced.

### 2. Named ZG-13 probes (isolated + full suite)

Isolated tester-only runner (`PROBE_PORT=4521`, not committed) after `npm run build`. Same five lines in the full suite (`PROBE_PORT=4522`, log `/tmp/zg13-tester-probes.log`):

```text
PASS  ZG-13/no-third-party cycled nightgarden → quarto → switchyard and printed; 27 request(s), all 127.0.0.1/localhost
PASS  ZG-13/font-files 13 @font-face url(s) 200 font/woff2 under /themes/fonts/ and frontend/dist/themes/fonts/
PASS  ZG-13/fonts-load EB Garamond @ quarto; IBM Plex Sans @ switchyard; Syne @ nightgarden; no watched family in error
PASS  ZG-13/fallback aborted **/themes/fonts/**; .rz-name height 65.421875; S2 + BAR-U2 green; ignored 11 font-load error(s)
PASS  BAR-L1 PASS
```

### 3. jsDelivr / `@font-face` counts / U3 locks

```text
$ grep -rn jsdelivr themes/*.css
# empty (exit 1)

$ grep -c "@font-face" themes/quarto.css themes/switchyard.css themes/nightgarden.css
themes/quarto.css:4
themes/switchyard.css:4
themes/nightgarden.css:5

$ git diff 7dc0550 -- frontend/scripts/probes.mjs
# hunk is import + zg10Probes() + zg13Probes() + banner only
# U3_PRINT_PAGES / LONG_PRINT_PAGES / 4173 not in the hunk
```

`U3_PRINT_PAGES` still `{nightgarden: 2, quarto: 2, switchyard: 2}`. `LONG_PRINT_PAGES` still `{3, 3, 3}`.

### 4. Existing S1–S5, S3, U3, ZG-4…12 (same full-suite run)

U3 Jordan print still 2/2/2:

```text
PASS  S3 Nightgarden print is 2 pages (Quarto 2, Switchyard 2)
PASS  U3 nightgarden Garden/iframe printToPDF is 2 pages and ends at Projects
PASS  U3 quarto Garden/iframe printToPDF is 2 pages and ends at Projects
PASS  U3 switchyard Garden/iframe printToPDF is 2 pages and ends at Projects
PASS  U3 nightgarden: chrome-shell printToPDF is 2 pages and ends at Projects
PASS  U3 quarto: chrome-shell printToPDF is 2 pages and ends at Projects
PASS  U3 switchyard: chrome-shell printToPDF is 2 pages and ends at Projects
```

S1–S5, RZ-3, and every `ZG-4/*`, `ZG-5/*`, `ZG-6/*`, `ZG-7/*`, `ZG-8/*`, `ZG-9/*`, `ZG-10/*`, `ZG-12/*` line PASSed in the same run. Same-face swap did not reflow.

Full suite: 164 PASS, 1 FAIL. Pre-existing environment miss (not a ZG-13 reject; theme print CSS and `U3_PRINT_PAGES` untouched):

```text
FAIL  ZG-11/page-count quarto example.html 2 page(s), long-resume.html 4 page(s): long-resume.html is 4 page(s), LONG_PRINT_PAGES is 3; long-resume.html is 4 page(s), want <= 3
```

Chromium 151. One probe failed in the full suite. Every `ZG-13/*` and `BAR-L1` line in that same run PASSed.

### 5. `just fmt` / clippy pedantic / cargo test (rustc 1.87.0)

| Recipe | Result |
| --- | --- |
| `just fmt` | PASS (renderer + renderer-wasm) |
| `just clippy` | PASS (`-D warnings -D clippy::pedantic`, both crates) |
| `cargo test` renderer | PASS: lib 29, acceptance 10, example 2, fixtures 2, wild 28 |
| `cargo test` renderer-wasm | PASS: 4 |
| `npm run test:unit` | PASS: 206 / 0 |
| `npm run probe` / `just test-frontend` | FAIL only `ZG-11/page-count quarto` 4 vs 3 (carved out) |

No `backend/Cargo.toml`. rust-version left at 1.87.

### 6. Chrome `rz-` + locks

```text
$ git diff --name-only 7dc0550...HEAD -- qa/MARKET-QUALITY-BAR.md
# empty
```

Chrome class/id scan of `frontend/src`, `frontend/css`, `frontend/static` (excluding generated wasm) with the static-probe regexes (`class`/`id`/`classList` `rz-`, CSS `#.rz-`): **none on chrome markup**. Comments and sandbox queries may name `.rz-resume` (skeleton contract); chrome does not use the prefix. ZG-13 did not edit chrome Elm/CSS.

HTTPS / DNS / TLS / issue #9 / `U3_PRINT_PAGES` / `LONG_PRINT_PAGES` / theme print CSS not touched by this Tester.

`themes/fonts/{eb-garamond,ibm-plex-sans,syne,outfit}/OFL.txt` present. `themes/README.md` contains `Font Library`, `CC BY 4.0`, and `HTTPS CDN`.

## AC checkboxes (Tester-produced evidence)

- [x] `grep -rn "jsdelivr" themes/*.css` empty; `@font-face` 4 / 4 / 5
- [x] `ZG-13/no-third-party` — isolated + full-suite PASS (27 requests, all 127.0.0.1/localhost)
- [x] `ZG-13/font-files` — isolated + full-suite PASS (13 urls, 200, `font/woff2`, on disk)
- [x] `ZG-13/fonts-load` — isolated + full-suite PASS (EB Garamond / IBM Plex Sans / Syne loaded; no watched family in error)
- [x] `ZG-13/fallback` — isolated + full-suite PASS (`.rz-name` height 65.421875; S2 + BAR-U2; ignored 11 font-load errors)
- [x] `themes/fonts/*/OFL.txt` + README `Font Library` / `CC BY 4.0` / `HTTPS CDN`
- [x] `BAR-L1` — isolated + full-suite `PASS  BAR-L1 PASS`
- [x] `U3_PRINT_PAGES` / `LONG_PRINT_PAGES` not in the `probes.mjs` hunk; S3/U3 Jordan 2/2/2
- [x] `just verify` recipes green except the carved-out ZG-11 quarto long-resume 4-vs-3

## Rust test gate

ZG-13 added no Rust public API. Regression matrix on rustc 1.87: `just fmt`, pedantic clippy, `cargo test` renderer + renderer-wasm all clean. Arrange = install 1.87 rather than `--ignore-rust-version`; Act = run the recipes; Assert = exit 0. "It works on my machine is not an answer" — these commands were run in this VM.

JS calculations in `theme-fonts.mjs` are isolated from probe actions. Checklist against the public calculations:

- Coverage: every exported calculation has an Arrange-Act-Assert unit (`extractFontFaceBlocks`, `fontFaceUrls`, `fontFileListReasons`, `resolveThemeUrl`, `themeFontDistPath`, `fontFetchReasons`, `isLoopbackHost`/`thirdPartyRequests`, `fontsLoadReasons`, `themePairs`, `barL1PairReasons`, `isIgnoredFontLoadError`/`unexpectedConsoleErrors`/`ignoredFontLoadCount`, `dateGeometryReasons`/`fallbackLayoutReasons`).
- Error paths: empty `@font-face` list, 404 / wrong Content-Type / missing disk, missing loaded family, watched family `status === "error"`, non-loopback host, unexpected console error, `.rz-name` height 0, BAR-U2 overflow, missing resume geometry.
- `document.fonts.check` unused (fonts-load uses `document.fonts.ready` + `status === "loaded"`).
- No `dbg!` / `println!` / commented-out tests.

TEST VERDICT: PASSED

Missing tests:
- none for ZG-13. The only red line this Tester produced is the pre-existing ZG-11 quarto page-count miss.

## Non-goals honored

- U3 print CSS / `U3_PRINT_PAGES` / `LONG_PRINT_PAGES` not edited
- DNS / TLS / issue #9 not touched
- `qa/MARKET-QUALITY-BAR.md` not edited
- Pinto left `in-progress`
- PR left draft
- No merge
- No production deploy
- Font Library submit product not implemented
- Subsetting / new faces / dropped faces — counts stayed 4/4/5
- CDN host allowlist — none added
- Tester wrote no product code

**TESTER BLESS ZG-13**
