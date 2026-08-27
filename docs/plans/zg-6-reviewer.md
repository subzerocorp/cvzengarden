# ZG-6 Reviewer — PR #22

Branch `cursor/zg-6-explain-sample-3d9c` vs `main` (`aa5b037…e2d1894`). Review only. Pinto left `in-progress`. No merge.

## Verdict

**REVIEWER REJECT ZG-6**

## Blockers

1. `frontend/package.json` `scripts.test:unit` — the glob `scripts/**/*.test.mjs static/**/*.test.mjs` is expanded by `sh` (npm scripts), not bash globstar. `sh -c 'echo scripts/**/*.test.mjs'` is only `scripts/probes/zg-4.test.mjs` and `scripts/probes/zg-11.test.mjs`. `npm run test:unit` therefore runs **16** tests, not the **147** the Generator recorded. Dropped: `scripts/build-wasm.test.mjs`, every `scripts/probes/lib/*.test.mjs`, `static/render.test.mjs`. `just verify` → `npm test` → this script, so the matrix is no longer the ZG-5 suite. Restore a runner that actually walks those trees (quote the globs so Node expands them, or `node --test --test-reporter=spec` plus an explicit `find … -name '*.test.mjs'`). Do not keep a shell glob that silently drops lib tests.

## Must-verify (walked)

| # | Result | Evidence |
| --- | --- | --- |
| 1 Sample Intent, no Store | pass | `Paste.Intent` = `Author \| Restore \| Sample`. `keep Sample` emits `[Swap html]` only; `accepted` unchanged. `keep Author` still `[Swap, Store]`. `sampleNotStoredProbe` asserts Ada bytes survive a junior click and a cleared sample leaves `resumezen.resume` `null`. |
| 2 Sidebar + schema href | pass | Closed lede is the exact `sidebarSentence`. Open panel `<a class="paste__schema">` `href` is `https://jsonresume.org/schema`. |
| 3 Alex 8–12, copy states | pass | `exampleJson` is 10 lines, `Alex Rivera`, one `work`. `[data-copy-example]` + `data-copy-state=copied\|failed`. Failed label is the ZG-8 sentence. Clipboard is `writeClipboard` → `navigator.clipboard.writeText`. |
| 4 Jordan / junior, no fetch | pass | `Generated.Samples` from `generate.mjs` `elmStringLiteral` of the fixture files. `classify` returns the original string. `start-sample` request log after the click allows only `themes/*.css`. |
| 5 junior.json / html lock | pass (source) | Sam Okoro, `"score": "3.7"`, `grep -c '"image"'` = 0, no awards/publications/references/certificates. `junior_sample_html_is_crate_output` in `acceptance.rs` (byte equality + 1 experience / 3 projects / `GPA 3.7` / no `rz-photo`). `skeleton/resume.json` and `example.html` diffs empty. Could not execute `cargo test` here (`rustc` 1.83, crate wants 1.87). |
| 6 Schema pin, ajv, rejects | pass | sha256 `8911e912…53969`, 15 018 bytes. README names `b25e3f4bbafd349c2c5bbaa62602c03c228762db`. `validateFormats: false` (plus `strict: false` so draft-07 `additionalItems` compiles). Isolated Ajv: junior/jordan/example validate; `{"basics":{"name":5}}` → `/basics/name`; `{"education":[{"score":3.7}]}` → `/education/0/score`. Missing ajv `FAIL`s, never skips. |
| 7 junior-all-themes print | pass | Uses `printToPdf` (CDP `Page.printToPDF`, `preferCSSPageSize: true`). No `page.pdf()`. No `themes/` diff. `U3_PRINT_PAGES` untouched. |
| 8 Chrome `rz-`, no second PBI, HTTPS | pass* | No chrome `class`/`id` `rz-`. No DNS/TLS/netlify/issue #9. *The `test:unit` glob is the reject, not a second product PBI. |
| 9 Probes + anti-stub | pass | `frontend/scripts/probes/zg-6.mjs` imported from `probes.mjs`. Score is `GPA ` + fixture `education[0].score`. Copy reads `navigator.clipboard`. Start-sample fails a post-click fetch. |
| 10 just verify / U3 honesty | pass (print) | No theme print CSS. `U3_PRINT_PAGES` still `{2,2,2}`. The reported ZG-11 quarto 4-vs-3 miss was not “fixed” in this PR. The unit-runner glob (blocker 1) is a separate honesty miss on the `npm test` half of `just verify`. |

## Non-goals honored

- U3 print page counts and theme print CSS not edited.
- HTTPS / DNS / TLS / issue #9 not touched.
- Pinto not marked done.
- ZG-14 still owns `skeleton/samples/*` → `dist/` (this PR only copies `clipboard.js`).
- Sample buttons are a new `Intent`, not `ShowIt` (ZG-5 handoff).

## Notes (not blockers)

- `Ajv({ strict: false })` is required to compile the vendored draft-07 `additionalItems`; formats stay off.
- `schema-example` validates the Elm `exampleJson` constant (same bytes as `pre[data-example]`), not a live page scrape — acceptable for an offline schema probe.
- `openGarden({ permissions })` opens a second BrowserContext and never closes it. Leak, not an AC miss.
- ZG-11/page-count quarto 4 vs 3 on Chromium 151 is a pre-existing environment miss. Not a ZG-6 reject.

## Re-review (`fa35ea8` + `e815371`)

Blocker 1 only. `test:unit` is now `node --test --test-reporter=spec $(find scripts static -name '*.test.mjs')`. Under `sh`, `find` returns all 18 `*.test.mjs` files (including `build-wasm`, every `scripts/probes/lib/*.test.mjs`, `static/render.test.mjs`). `npm run test:unit`: 147 pass / 0 fail. Those commits touch only `frontend/package.json` and `docs/plans/zg-6-execution.md` — product AC files unchanged. U3 / HTTPS untouched.

**REVIEWER BLESS ZG-6**
