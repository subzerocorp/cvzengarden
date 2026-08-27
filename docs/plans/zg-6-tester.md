# ZG-6 Tester — PR #22

Branch `cursor/zg-6-explain-sample-3d9c` @ `8db67f3` (Reviewer BLESS note) vs `main` `aa5b037`.
Tester only. Pinto left `in-progress`. No merge. No second PR. No product change.

Mandates applied: AXEL conductor (sequence/record/gate only) + rust-code-tester (run the suite, do not rubber-stamp).

## Environment (honest)

Snapshot rustc was **1.83.0**. Crates pin `rust-version = "1.87"`. On 1.83, `cargo test` refuses the crate; `--ignore-rust-version` then fails on `u32::is_multiple_of` (`renderer/src/date.rs:122`). The bar was **not** lowered. Tester installed `rustc 1.87.0 (17067e9ac 2025-05-09)` in this VM, plus a prebuilt `wasm-pack 0.15.0` and `just 1.43.1` (neither on PATH in the snapshot). `just verify` as a single recipe was not re-run after the full probe pass; the four recipes were run separately (see Verification).

## Verdict

**TESTER BLESS ZG-6**

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
static/render.test.mjs
# count: 18 (includes build-wasm, every scripts/probes/lib/*.test.mjs, static/render.test.mjs)

$ npm run test:unit
ℹ tests 147
ℹ pass 147
ℹ fail 0
```

`package.json` `test:unit` is `node --test --test-reporter=spec $(find scripts static -name '*.test.mjs')`. Under `sh`, `find` is an explicit file list. The Reviewer glob reject is gone.

### 2. Isolated ZG-6 probes (after `npm run build`)

`PROBE_PORT=4313 node /tmp/zg-6-isolated.mjs` — tester-only runner; starts `serve.mjs`, calls `zg6Probes` from `frontend/scripts/probes/zg-6.mjs`. Not committed.

```text
PASS  ZG-6/schema-vendored schema sha256 8911e912ee487954b10cb59da39265c7e62ef7cba5973706d125448adc853969; README names b25e3f4bbafd349c2c5bbaa62602c03c228762db
PASS  ZG-6/schema-junior skeleton/samples/junior.json validates against the vendored schema
PASS  ZG-6/schema-jordan skeleton/resume.json validates against the vendored schema
PASS  ZG-6/schema-example pre[data-example] payload validates against the vendored schema
PASS  ZG-6/schema-rejects rejects a numeric name and a numeric score with the schema instancePaths
PASS  ZG-6/junior-no-image-key skeleton/samples/junior.json has zero "image" keys
PASS  ZG-6/format-named open panel names JSON Resume and links https://jsonresume.org/schema
PASS  ZG-6/sidebar-sentence closed sidebar has the small-text-file sentence
PASS  ZG-6/example-copy Copy example writes the 8–12 line Alex Rivera snippet and shows Copied
PASS  ZG-6/example-copy-failed rejected writeText shows Copy failed and never Copied
PASS  ZG-6/example-renders Show it on the example draws Alex Rivera with one experience entry
PASS  ZG-6/start-sample Jordan's sample fills the box with skeleton/resume.json and draws Jordan Hale with no fetch
PASS  ZG-6/start-junior short sample draws Sam Okoro, one job, three projects, GPA 3.7, no photo or extras
PASS  ZG-6/sample-not-stored sample click does not Store; Show it after an edit does
PASS  ZG-6/junior-all-themes junior sample has no horizontal overflow on Nightgarden, Quarto, Switchyard and shell-print is ≤ 2 pages

All isolated ZG-6 probes passed.
```

### 3. `cd renderer && cargo test --test acceptance -- junior_sample_html_is_crate_output`

```text
test junior_sample_html_is_crate_output ... ok
test result: ok. 1 passed; 0 failed; 0 ignored; 0 measured; 9 filtered out
```

Lock asserts byte equality plus 1 `rz-entry--experience`, 3 `rz-entry--project`, `<p class="rz-score">GPA 3.7</p>`, no `rz-photo`.

### 4. Static greps (PBI)

```text
$ grep -c '"image"' skeleton/samples/junior.json
0

$ git diff --name-only aa5b037..HEAD -- skeleton/samples | grep -E '\.(svg|png|jpe?g|webp|gif)$'
# empty

$ git diff --stat aa5b037..HEAD -- skeleton/resume.json skeleton/example.html
# empty
```

Independent pin: `sha256sum skeleton/resume-schema.json` = `8911e912ee487954b10cb59da39265c7e62ef7cba5973706d125448adc853969`; `wc -c` = 15018; `grep -n "b25e3f4bbafd349c2c5bbaa62602c03c228762db" skeleton/README.md` hits line 10.

`git diff --name-only aa5b037..HEAD -- themes/` is empty. `U3_PRINT_PAGES` / `LONG_PRINT_PAGES` not in the `probes.mjs` diff.

### 5. U3 Jordan print 2/2/2

Full `PROBE_PORT=4314 node scripts/probes.mjs` (after the same build):

```text
PASS  U3 nightgarden Garden/iframe printToPDF is 2 pages and ends at Projects
PASS  U3 quarto Garden/iframe printToPDF is 2 pages and ends at Projects
PASS  U3 switchyard Garden/iframe printToPDF is 2 pages and ends at Projects
PASS  U3 nightgarden: chrome-shell printToPDF is 2 pages and ends at Projects
PASS  U3 quarto: chrome-shell printToPDF is 2 pages and ends at Projects
PASS  U3 switchyard: chrome-shell printToPDF is 2 pages and ends at Projects
```

Pre-existing environment miss (not a ZG-6 reject; theme print CSS and `U3_PRINT_PAGES` untouched):

```text
FAIL  ZG-11/page-count quarto example.html 2 page(s), long-resume.html 4 page(s): long-resume.html is 4 page(s), LONG_PRINT_PAGES is 3; long-resume.html is 4 page(s), want <= 3
```

Chromium 151. One probe failed in the full suite. Every `ZG-6/*` line in that same run PASSed (repeat of the isolated set).

### 6. `just verify` recipes

| Recipe | Result |
| --- | --- |
| `just fmt` | PASS (renderer + renderer-wasm) |
| `just clippy` | PASS (`-D warnings -D clippy::pedantic`, both crates) |
| `cargo test` renderer | PASS: lib 29, acceptance 10, example 2, fixtures 2, wild 28 |
| `cargo test` renderer-wasm | PASS: 4 |
| `npm run test:unit` | PASS: 147 / 0 |
| `npm run probe` / `just test-frontend` | FAIL only `ZG-11/page-count quarto` 4 vs 3 (carved out) |

No `backend/Cargo.toml`. HTTPS / DNS / TLS / issue #9 / `U3_PRINT_PAGES` / theme print CSS not touched by this Tester.

## AC checkboxes (Tester-produced evidence)

- [x] `ZG-6/format-named` — isolated + full probe PASS
- [x] `ZG-6/sidebar-sentence` — isolated + full probe PASS
- [x] `ZG-6/example-copy` — isolated + full probe PASS (`grantPermissions` clipboard)
- [x] `ZG-6/example-copy-failed` — isolated + full probe PASS
- [x] `ZG-6/example-renders` — isolated + full probe PASS
- [x] `ZG-6/start-sample` — isolated + full probe PASS
- [x] `ZG-6/start-junior` — isolated + full probe PASS (`GPA 3.7` from fixture `education[0].score`)
- [x] `ZG-6/sample-not-stored` — isolated + full probe PASS
- [x] `ZG-6/junior-all-themes` — isolated + full probe PASS
- [x] `ZG-6/schema-vendored` — probe PASS + `sha256sum` / README grep
- [x] `ZG-6/schema-junior` / `schema-example` / `schema-jordan` — probe PASS (`ajv` v8, `validateFormats: false`)
- [x] `ZG-6/schema-rejects` — probe PASS (`/basics/name`, `/education/0/score`)
- [x] `junior_sample_html_is_crate_output` — `cargo test --test acceptance` ok
- [x] `grep -c '"image"'` = 0; no image files under `skeleton/samples` in the diff
- [x] `skeleton/resume.json` and `example.html` diff empty
- [x] Anti-stub (source, not a mutation): `startJuniorProbe` sets `wantScore = GPA ${junior.education[0].score}`; `exampleCopyProbe` reads `navigator.clipboard.readText()`; `startSampleProbe` fails any post-click request that is not `themes/*.css`. A hard-coded junior HTML, a stub Copy, or a fetch-at-click would fail those probes. Live `start-junior` already asserted the fixture score.
- [x] `just verify` recipes green except the carved-out ZG-11 quarto long-resume 4-vs-3

## Rust test gate (new lock only)

`junior_sample_html_is_crate_output` is an acceptance fixture lock (correct layer: not a unit of a new public API). Arrange = read junior JSON / render; Act = compare committed HTML; Assert = byte equality + the four structural clauses the PBI names. `cargo test` + pedantic clippy clean on 1.87.

TEST VERDICT: PASSED

No missing ZG-6 tests. The only red line this Tester produced is the pre-existing ZG-11 quarto page-count miss.

## Non-goals honored

- U3 print CSS / `U3_PRINT_PAGES` not edited
- DNS / TLS / issue #9 not touched
- Pinto left `in-progress`
- No second ticket or PR
- No merge

TESTER BLESS ZG-6
