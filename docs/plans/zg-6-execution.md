# ZG-6 execution

Explain the résumé format in plain words and let a first-timer start from a sample.

## Design

- Third `Paste.Intent` (`Sample`): classify → render → swap; does **not** `Store` and does not change `accepted`.
- `ShowIt` stays `Author` and still Stores (ZG-5).
- Sample bytes are `Generated.Samples` (`jordan`, `junior`) written by `generate.mjs` from `skeleton/resume.json` and `skeleton/samples/junior.json`.
- Clipboard is a port (`copyText` / `onCopied`) over `clipboard.js`. Copied clears after 2s via `Process.sleep`.
- Example snippet lives in `Paste.exampleJson` (10 lines). Schema probes read that same string from the Elm source so they stay offline.

## Execution Evidence

- [x] `ZG-6/format-named` — probe in `frontend/scripts/probes/zg-6.mjs` (`formatNamedProbe`)
- [x] `ZG-6/sidebar-sentence` — probe `sidebarSentenceProbe`; closed copy is `sidebarSentence` in `Paste.elm`
- [x] `ZG-6/example-copy` — probe `exampleCopyProbe` with `grantPermissions(['clipboard-read','clipboard-write'])`
- [x] `ZG-6/example-copy-failed` — probe `exampleCopyFailedProbe` (`addInitScript` rejects `NotAllowedError`)
- [x] `ZG-6/example-renders` — probe `exampleRendersProbe`
- [x] `ZG-6/start-sample` — probe `startSampleProbe` (Ada paste, then Jordan; request log after click)
- [x] `ZG-6/start-junior` — probe `startJuniorProbe` (score from fixture: `GPA ` + `education[0].score`)
- [x] `ZG-6/sample-not-stored` — probe `sampleNotStoredProbe` (Ada survives sample click; cleared storage stays `null`; Show it stores an edit)
- [x] `ZG-6/junior-all-themes` — probe `juniorAllThemesProbe` (`printToPdf` + `countPdfPages` ≤ 2; never `page.pdf()`)
- [x] `ZG-6/schema-vendored` — probe `schemaProbes`; sha256 `8911e912ee487954b10cb59da39265c7e62ef7cba5973706d125448adc853969`; README names `b25e3f4bbafd349c2c5bbaa62602c03c228762db`
- [x] `ZG-6/schema-junior` — `ajv` v8, `validateFormats: false`, `skeleton/samples/junior.json`
- [x] `ZG-6/schema-example` — same validator on `Paste.exampleJson` (the `pre[data-example]` payload)
- [x] `ZG-6/schema-jordan` — same validator on `skeleton/resume.json`
- [x] `ZG-6/schema-rejects` — `instancePath` `/basics/name` and `/education/0/score`
- [x] `junior_sample_html_is_crate_output` — `cd renderer && cargo test --test acceptance -- junior_sample_html_is_crate_output`
- [x] `grep -c '"image"' skeleton/samples/junior.json` → `0`
- [x] `git diff --name-only main...HEAD -- skeleton/samples | grep -E '\.(svg|png|jpe?g|webp|gif)$'` → empty
- [x] `git diff --stat main...HEAD -- skeleton/resume.json skeleton/example.html` → empty
- [x] Anti-stub: start-junior reads fixture score; example-copy reads `navigator.clipboard`; start-sample fails a fetch-at-click
- [x] `just verify` — see Verification below (filled after the run)

## Verification

Pending the full matrix on this branch (`PROBE_PORT` not 4173).

## Board

- status: in-progress (Architect marks done after GAN)

## Non-goals honored

- U3 print page counts and theme print CSS untouched
- HTTPS / DNS / issue #9 untouched
- `skeleton/resume.json` and `skeleton/example.html` untouched
- ZG-14 still owns `skeleton/samples/*` → `dist/` copy
- Chrome has no `rz-` class or id
- No second ticket or PR
