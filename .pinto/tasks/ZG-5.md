+++
id = "ZG-5"
title = "Paste or open your own JSON Resume and see it in every Theme"
status = "done"
rank = "m"
labels = ["avril", "round-1", "chrome", "avril-blessed"]
depends_on = ["ZG-2", "ZG-3", "ZG-4"]
start_at = "2026-08-24T20:48:27.173149Z"
done_at = "2026-08-24T22:54:11.693793Z"
commits = ["32ef15b", "e33212f"]
created = "2026-08-23T23:54:23.454780Z"
updated = "2026-08-24T22:54:15.349109Z"
+++

## Why
Priya walked away because there was no step where she could put her résumé in; with this slice an Author pastes or opens their file, sees themselves in the Garden, and gets a plain-English message when the file is wrong (Priya, Elena, Marcus).
## Covers
A1, A4 — Priya, Elena, Marcus
## Scope in
- A visible "Use my résumé" control on the first screen (sidebar, above Themes) that opens a panel with: a `<textarea id="paste-input">`, an "Open a file" `<input type="file" accept=".json,application/json">`, and a drop zone (`[data-drop-zone]`) accepting a dropped file
- Rendering runs through ZG-4 in the browser; only `article.rz-resume` in the sandbox changes; Theme switch and Print preview keep working on the Author's data
- Humane errors rendered in a `[data-paste-error]` element, each with a plain-language sentence and the line/column when known: `empty`, `invalid-json` (with a hint for the two most common causes: trailing comma, unquoted text), `not-a-resume` (JSON parsed but a known key has the wrong shape — name the key), `missing-name`, `not-json-file` (an opened/dropped file whose content is not JSON — names the file it received), `render-failed` (JSON parsed and shaped like a résumé but `window.resumezen.render` rejected — "We could not draw this résumé" plus a link to report it; the raw error is kept in `console.debug` only)
- File classification is by content, then extension: content that parses as JSON is accepted whatever the extension; `.json` content that fails to parse → `invalid-json` with line/column; any other unparseable file → `not-json-file`
- No error text ever contains a Rust/serde token: `expected`, `EOF`, `invalid type`, `serde`, `Err(`, `panicked` (one shared assertion applied to every class)
- The last accepted Resume is kept in `localStorage` (`resumezen.resume`) and restored on reload; a stored value that does not parse or does not render is discarded silently (key removed, Jordan shown, no banner); a "Forget my résumé" button clears it and restores Jordan Hale
- Sidebar copy near the control states "Nothing leaves your browser until you publish"
- Shared fixtures (owner: this PBI): `frontend/fixtures/trailing-comma.json` = `{"basics":{"name":"Elena",}}`; `frontend/fixtures/not-a-resume.pdf` = the bytes `%PDF-1.4\n1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj\n2 0 obj << /Type /Pages /Kids [] /Count 0 >> endobj\ntrailer << /Root 1 0 R >>\n%%EOF\n`; `frontend/fixtures/ada.json` is ZG-4's
## Scope out
- Explaining the format / copyable example / sample buttons (ZG-6)
- Publishing, hosted URLs (ZG-21/22)
- A form editor, PDF/LinkedIn import, Bridge dialects (Phase 5 / RZ-7, RZ-9)
- Field-level warnings (unknown keys) — the renderer ignores them by contract §1.8
- Download HTML/CSS as a headline (BAR-X1 / lock 8)
## Acceptance criteria
- [x] Probe `ZG-5/paste-sample`: pasting `skeleton/resume.json` into `#paste-input` and pressing the panel's "Show it" button yields sandbox `.rz-name` = `Jordan Hale` with `data-rz-schema="1.0"` and no `[data-paste-error]`
- [x] Probe `ZG-5/paste-ada`: pasting `frontend/fixtures/ada.json` yields `.rz-name` = `Ada Lovelace`, no `Jordan Hale` anywhere in the iframe document, iframe `src` unchanged, and `#theme-stylesheet` href unchanged
- [x] Probe `ZG-5/paste-then-switch`: after the Ada paste, selecting Quarto changes `#theme-stylesheet` to `themes/quarto.css` and `.rz-name` is still `Ada Lovelace`; Print preview then shows `.rz-name` `Ada Lovelace`
- [x] Probe `ZG-5/paste-empty`: pasting `""` and `"   \n"` shows `[data-paste-error="empty"]` and `.rz-name` is unchanged
- [x] Probe `ZG-5/paste-trailing-comma`: pasting `frontend/fixtures/trailing-comma.json` shows `[data-paste-error="invalid-json"]` whose text contains `line 1` and the word `comma`
- [x] Probe `ZG-5/paste-not-resume`: pasting `{"basics":{"name":"E"},"work":"nope"}` shows `[data-paste-error="not-a-resume"]` whose text contains `work`
- [x] Probe `ZG-5/paste-missing-name`: pasting `{"basics":{"label":"Junior Developer"}}` shows `[data-paste-error="missing-name"]` whose text contains `name`
- [x] Probe `ZG-5/render-failed`: with `window.resumezen.render` overridden in the page to reject with `new Error("expected value at line 3 column 1")`, pasting `ada.json` shows `[data-paste-error="render-failed"]` whose text contains `could not` and `.rz-name` is unchanged; no `pageerror`
- [x] Probe `ZG-5/no-serde-tokens`: after each of the five error probes above, the `[data-paste-error]` text contains none of `expected`, `EOF`, `invalid type`, `serde`, `Err(`, `panicked` (case-sensitive)
- [x] Probe `ZG-5/open-pdf`: setting the file input to `frontend/fixtures/not-a-resume.pdf` shows `[data-paste-error="not-json-file"]` whose text contains `not-a-resume.pdf` and `JSON Resume`
- [x] Probe `ZG-5/open-json`: setting the file input to `skeleton/resume.json` renders `Jordan Hale` without using the textarea
- [x] Probe `ZG-5/file-classes`: setting the file input to `frontend/fixtures/trailing-comma.json` shows `invalid-json` (not `not-json-file`) with `line 1`; a temporary `resume.txt` whose content is `ada.json`'s renders `Ada Lovelace` with no error; a temporary `notes.txt` containing `hello` shows `not-json-file` naming `notes.txt`
- [x] Probe `ZG-5/drop-json` and `ZG-5/drop-pdf`: dispatching a `drop` event with a `DataTransfer` holding `skeleton/resume.json` on `[data-drop-zone]` renders `Jordan Hale`; the same with `not-a-resume.pdf` shows `not-json-file`
- [x] Probe `ZG-5/restore`: after the Ada paste, a reload of the same origin shows `.rz-name` `Ada Lovelace`; clicking "Forget my résumé" restores `Jordan Hale` and `localStorage.getItem('resumezen.resume')` is `null`
- [x] Probe `ZG-5/corrupt-storage`: with `localStorage['resumezen.resume']` set to `{` and, in a second run, to `{"basics":{"label":"x"}}`, a reload shows `Jordan Hale`, no `[data-paste-error]`, no console error or `pageerror`, and `localStorage.getItem('resumezen.resume')` is `null` afterwards
- [x] Probe `ZG-5/no-network`: the paste flow issues no HTTP request besides page assets and `themes/*.css`
- [x] Probe `ZG-5/copy`: sidebar `textContent` contains `Nothing leaves your browser`; the control's accessible name contains `résumé`; chrome HTML/CSS still has no `rz-` class or id
- [x] A stub that renders the paste by string-replacing `Jordan Hale` fails the Ada `no Jordan Hale` and the `work: "nope"` probes
## Dependencies
- ZG-2
- ZG-3
- ZG-4 (owner of `frontend/fixtures/ada.json` and `window.resumezen.render`)
## Notes
- ZG-6 sample buttons must be a new `Intent`, not `ShowIt` (`ShowIt` writes `resumezen.resume`). Architect phase-2.

## Execution Evidence (commits 32ef15b, e33212f)

Tester-run `PROBE_PORT=4430 npm test` and `PROBE_PORT=4431 just verify` both exit 0 (`/tmp/zg5-p2-probes-4430.log`, `/tmp/zg5-p2-verify-4431.log`). node:test 147/147.

- [x] paste-sample — `.rz-name` Jordan Hale, `data-rz-schema="1.0"`, no error
- [x] paste-ada — Ada Lovelace, no Jordan Hale in iframe, src/href unchanged
- [x] paste-then-switch — Quarto + Print preview still Ada Lovelace
- [x] paste-empty — `""` and `"   \n"` → empty; name unchanged
- [x] paste-trailing-comma — invalid-json, line 1, comma
- [x] paste-not-resume — not-a-resume names `work`
- [x] paste-missing-name — missing-name, word name
- [x] render-failed — could not; debug-only serde; no pageerror
- [x] no-serde-tokens — empty, invalid-json, not-a-resume, missing-name, render-failed, not-json-file, 13 scanner-hints rows
- [x] open-pdf — not-json-file names `not-a-resume.pdf` and `JSON Resume`
- [x] open-json — Jordan Hale via file input, textarea unused
- [x] file-classes — trailing-comma.json invalid-json line 1; resume.txt → Ada; notes.txt → not-json-file
- [x] drop-json / drop-pdf — Jordan Hale; not-json-file
- [x] restore — Ada survives reload; Forget → Jordan Hale, key null
- [x] corrupt-storage — both `{` and missing-name JSON → Jordan, no banner, no pageerror, key null
- [x] no-network — paste + file-open: only page assets / themes/*.css
- [x] copy — Use my résumé; Nothing leaves your browser; chrome rz- static probe
- [x] anti-stub — Ada hasJordan + work:nope; mutation dropping content-first made file-classes FAIL then restored
- [x] just verify exit 0 (PROBE_PORT=4431)

GAN: phase-1 BLESS ×3; phase-2 Reviewer BLESS | Tester BLESS | Architect BLESS — `docs/plans/zg-5-gan-report.md`
