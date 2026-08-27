+++
id = "ZG-6"
title = "Explain the résumé format in plain words and start from a sample"
status = "done"
rank = "n"
labels = ["avril", "round-1", "chrome", "avril-blessed"]
depends_on = ["ZG-5"]
done_at = "2026-08-27T23:10:00.000000Z"
commits = ["7859ba0", "5790337", "fa35ea8", "56893b3"]
created = "2026-08-23T23:54:23.466605Z"
updated = "2026-08-27T23:10:00.000000Z"
+++

## Why
Priya never learned the site wants "JSON Resume" and Elena could only start from the sample by hand-editing View Source; naming the format, showing a copyable example that is proven to render, and one-click "Start from a sample" (including a short junior sample) lets a first-timer begin (Priya, Elena).
## Covers
A2, A3 — Priya, Elena
## Scope in
- In the paste panel (ZG-5): one sentence naming **JSON Resume** with an `<a href="https://jsonresume.org/schema">`, and a copyable 8–12 line example in a `<pre data-example>` with `basics.name` = `Alex Rivera`, `label`, `email`, and one `work` entry, plus a "Copy example" button (`[data-copy-example]`) that writes the `<pre>` text to the clipboard and shows `[data-copy-state="copied"]` ("Copied") for ~2 s; when the clipboard write rejects it shows `[data-copy-state="failed"]` with the text "Copy failed — select the text and copy it" and never "Copied" (same state names as ZG-8)
- Buttons in the panel: "Start from Jordan's sample" (fills `#paste-input` with the exact bytes of `skeleton/resume.json` and renders) and "Start from a short sample" (same with `skeleton/samples/junior.json`). The sample bytes are embedded at build time by `generate.mjs` (`frontend/generated/Samples.elm`, two string constants) so a click issues no HTTP request and nothing under `skeleton/` needs to be served for this PBI
- A sample click renders through ZG-5's accept path but does **not** write `localStorage['resumezen.resume']` — a sample is a starting point, not the Author's résumé; the stored file (if any) survives an accidental click and is restored on reload. Editing the sample text and pressing "Show it" stores it exactly as a paste does (ZG-5 rule, unchanged)
- New `skeleton/samples/junior.json` (owner: this PBI): Elena's thin résumé — `basics.name` = `Sam Okoro`, `label` = `Junior Web Developer`, `email`, `summary`; **no `image`**; one retail `work` entry with two highlights; `education` with `"score": "3.7"` (a string — the JSON Resume schema type; numeric scores are ZG-3's tolerance, not this file) and `courses`; three `projects`; two `skills` groups; every date `YYYY`, `YYYY-MM` or `YYYY-MM-DD`; no `awards`, `publications`, `references`, `certificates`. Nothing in the file a first-timer must delete by hand
- `skeleton/samples/junior.html` (owner: this PBI) = the exact `render_json(junior.json)` document, locked by a new test `junior_sample_html_is_crate_output` appended to `renderer/tests/acceptance.rs` (byte equality; `RZ_UPDATE_FIXTURES=1 cargo test --test acceptance` regenerates it — same env var as ZG-11, no shared file)
- Vendored schema (owner: this PBI): `skeleton/resume-schema.json`, byte-identical to `jsonresume/resume-schema` `schema.json` at commit `b25e3f4bbafd349c2c5bbaa62602c03c228762db` (draft-07, 15 018 bytes, sha256 `8911e912ee487954b10cb59da39265c7e62ef7cba5973706d125448adc853969`); `skeleton/README.md` records that URL + commit. Every later schema assertion in this round (ZG-19 `contract.json` if desired) references this file
- Schema runner (offline): `probes.mjs` imports `ajv` (v8, dev-only, see Notes) with `validateFormats: false` (string `format`s `email`/`uri` are not judged; the schema's `iso8601` date `pattern` is) and validates the files named in the AC; `ajv` missing → `FAIL  ZG-6/schema-<slug> prerequisite missing: ajv devDependency (Notes)`, never `SKIPPED`
- Sidebar copy under "Use my résumé" (visible with the panel closed): "Your résumé is a small text file (JSON Resume). Paste it, open it, or start from a sample."
## Scope out
- A photo (`basics.image`) or any bundled image asset in the junior sample — it is Elena's starting file, not a contract-coverage fixture; Designer proofing of `rz-photo` / `rz-score` lives in ZG-19 (`skeleton/samples/contract.json`)
- Serving `skeleton/resume.json` or `skeleton/samples/*` — not needed (bytes are embedded at build); ZG-14 remains the only owner of the `skeleton/samples/*` → `dist/` copy step ("when present"); this PBI owns the source files only and does not depend on ZG-14
- Numeric `education[].score` — ZG-3 (the sample uses the schema's string type, so this PBI needs nothing from ZG-3 beyond the ZG-5 edge)
- Fetching the schema at test time — `just verify` stays offline; the schema is vendored and pinned above
- A guided form editor (Phase 5 "ingest"); converting PDF/DOCX/LinkedIn into JSON Resume
- Editing the sample in place inside the iframe (`contenteditable`) — the JSON is the document of record
- Changing `skeleton/resume.json` / `example.html` (keeps the RZ-2 lock stable)
## Acceptance criteria
- [x] Probe `ZG-6/format-named`: with the paste panel open, chrome `document.body.textContent` contains `JSON Resume` and the panel contains an `<a>` whose `href` equals `https://jsonresume.org/schema` (string equality; never fetched)
- [x] Probe `ZG-6/sidebar-sentence`: with the paste panel **closed**, the sidebar `textContent` contains `small text file` and `start from a sample`
- [x] Probe `ZG-6/example-copy`: in a context with `context.grantPermissions(['clipboard-read','clipboard-write'])`, `pre[data-example]` text is 8–12 lines, parses as JSON with `basics.name` = `Alex Rivera`, `basics.label`, `basics.email` and `work.length === 1`; clicking "Copy example" puts exactly that text on the clipboard and `[data-copy-state="copied"]` appears with text `Copied`
- [x] Probe `ZG-6/example-copy-failed`: with `navigator.clipboard.writeText` overridden via `page.addInitScript` to reject with `NotAllowedError`, clicking "Copy example" shows `[data-copy-state="failed"]` whose `textContent` contains `Copy failed`; `Copied` never appears (sampled for 500 ms); no `pageerror`
- [x] Probe `ZG-6/example-renders`: pasting the `pre[data-example]` text into `#paste-input` and pressing "Show it" yields sandbox `.rz-name` = `Alex Rivera`, exactly one `.rz-entry--experience`, and no `[data-paste-error]`
- [x] Probe `ZG-6/start-sample`: after the ZG-5 Ada paste (`.rz-name` = `Ada Lovelace`), clicking "Start from Jordan's sample" makes `#paste-input.value` byte-equal to `fs.readFileSync('skeleton/resume.json','utf8')` and `.rz-name` = `Jordan Hale`; the click issues no HTTP request (`page.on('request')` log has no new entry besides `themes/*.css`)
- [x] Probe `ZG-6/start-junior`: clicking "Start from a short sample" makes `#paste-input.value` byte-equal to `skeleton/samples/junior.json` and the sandbox shows `.rz-name` = `Sam Okoro`, exactly one `.rz-entry--experience`, three `.rz-entry--project`, a `.rz-score` whose text is `GPA 3.7`, **no** `.rz-photo`, and **no** `#rz-awards`, `#rz-publications`, `#rz-references`, `#rz-certificates`
- [x] Probe `ZG-6/sample-not-stored`: after the Ada paste, clicking "Start from a short sample" leaves `localStorage.getItem('resumezen.resume')` equal to the Ada bytes and a reload shows `.rz-name` = `Ada Lovelace`; with storage cleared, a sample click then reload shows `Jordan Hale` and the key is `null`; editing the sample text in `#paste-input` (change the name) and pressing "Show it" stores it and a reload shows the edited name
- [x] Probe `ZG-6/junior-all-themes`: with the junior sample rendered, for each of Nightgarden, Quarto, Switchyard at 1280×800: iframe `document.documentElement.scrollWidth <= clientWidth` (no horizontal scrollbar); then the chrome shell-print route — `.preview-controls__print` click stubbed as in the U3 probe, `window.dispatchEvent(new Event('beforeprint'))` hoists `#garden-print-host`, `printToPdf(page)` (existing CDP helper, `preferCSSPageSize: true`), `countPdfPages` ≤ 2, `afterprint` dispatched; never `page.pdf()`
- [x] Probe `ZG-6/schema-vendored`: `skeleton/resume-schema.json` exists, its sha256 is `8911e912ee487954b10cb59da39265c7e62ef7cba5973706d125448adc853969`, and `grep -n "b25e3f4bbafd349c2c5bbaa62602c03c228762db" skeleton/README.md` hits
- [x] Probes `ZG-6/schema-junior`, `ZG-6/schema-example`, `ZG-6/schema-jordan`: `skeleton/samples/junior.json`, the `pre[data-example]` text, and `skeleton/resume.json` each validate against the vendored schema with `ajv` (`validateFormats: false`); when `ajv` cannot be imported each prints `FAIL  ZG-6/schema-<slug> prerequisite missing: ajv devDependency (Notes)`
- [x] Probe `ZG-6/schema-rejects`: the same validator rejects `{"basics":{"name":5}}` with an error whose `instancePath` is `/basics/name`, and rejects `{"education":[{"score":3.7}]}` (`/education/0/score`) — the runner is proven to say no
- [x] `cd renderer && cargo test --test acceptance`: `junior_sample_html_is_crate_output` passes (`skeleton/samples/junior.html` byte-equals `render_json(junior.json)`) and asserts the HTML contains exactly 1 `rz-entry--experience`, 3 `rz-entry--project`, `<p class="rz-score">GPA 3.7</p>`, and no `rz-photo`
- [x] `grep -c '"image"' skeleton/samples/junior.json` prints `0`; `git diff --name-only <base>..HEAD -- skeleton/samples | grep -E '\.(svg|png|jpe?g|webp|gif)$'` prints nothing
- [x] `git diff --stat <base>..HEAD -- skeleton/resume.json skeleton/example.html` is empty
- [x] Anti-stub: a build that hard-codes the junior HTML instead of rendering the JSON fails `ZG-6/start-junior` once `score` in `junior.json` is changed to `"3.8"` (the probe reads the fixture and asserts `GPA ` + the fixture's value); a stub Copy that never touches the clipboard fails `example-copy`; a stub that fetches the sample at click time fails `start-sample`'s request log
- [x] `just verify` green
## Dependencies
- ZG-5 (owner of the paste panel, `#paste-input`, "Show it", `[data-paste-error]`, `resumezen.resume`)
- Not ZG-14 (serving is not needed; ZG-14's `skeleton/samples/*` copy applies "when present"), not ZG-3 (string `score`), not ZG-11 (the lock lives in `acceptance.rs`)
## Notes
- Third-party for human approval: `ajv` (^8) as a `frontend/` devDependency, used only by `probes.mjs` for the schema assertions; it runs offline against the vendored file. If declined, the fallback is the Rust `jsonschema` crate as a `renderer` dev-dependency with the same four assertions in `renderer/tests/schema.rs`; either way the probe lines exist and FAIL (never skip) until a runner is installed.
- Upstream note: `jsonresume/resume-schema` master (commit above) says the schema moved to the `jsonresume.org` monorepo (`packages/schema`); the vendored file is that commit's `schema.json`. Re-pinning is a one-line change to the sha256 and commit in this AC.

## Execution Evidence (commits 7859ba0, 5790337, fa35ea8, 56893b3)

Full probe/unit evidence: `docs/plans/zg-6-execution.md`, `docs/plans/zg-6-tester.md`. GAN close: `docs/plans/zg-6-completion.md`.

- [x] format-named / sidebar-sentence / example-copy / example-copy-failed / example-renders — isolated + full `ZG-6/*` PASS
- [x] start-sample / start-junior / sample-not-stored — Sample Intent Swap-only; Show it Stores; Ada key survives; no post-click fetch
- [x] junior-all-themes — Nightgarden / Quarto / Switchyard no overflow; shell-print ≤ 2 via `printToPdf`
- [x] schema-vendored / schema-junior / schema-example / schema-jordan / schema-rejects — sha256 pin, README commit, ajv `validateFormats: false`
- [x] `junior_sample_html_is_crate_output` — `cargo test --test acceptance` ok
- [x] `grep -c '"image"'` = 0; no image files under `skeleton/samples`; `resume.json` / `example.html` diff empty
- [x] Anti-stub: fixture score, clipboard read, request log after click
- [x] `just verify` recipes green except carved-out pre-existing `ZG-11/page-count quarto` 4-vs-3

GAN: Reviewer REJECT (`765a4aa`, `test:unit` glob) → find walk (`fa35ea8`) → Reviewer BLESS → Tester BLESS (`56893b3`) → Architect BLESS. PR #22 left open. Production not published.
