+++
id = "ZG-5"
title = "Paste or open your own JSON Resume and see it in every Theme"
status = "todo"
rank = "m"
labels = ["avril", "round-1", "chrome"]
depends_on = ["ZG-2", "ZG-3", "ZG-4"]
created = "2026-08-23T23:54:23.454780Z"
updated = "2026-08-23T23:59:42.174706Z"
+++

## Why
Priya walked away because there was no step where she could put her résumé in; with this slice an Author pastes or opens their file, sees themselves in the Garden, and gets a plain-English message when the file is wrong (Priya, Elena, Marcus).
## Covers
A1, A4 — Priya, Elena, Marcus
## Scope in
- A visible "Use my résumé" control on the first screen (sidebar, above Themes) that opens a panel with: a `<textarea id="paste-input">`, an "Open a file" `<input type="file" accept=".json,application/json">`, and a drop zone accepting a dropped `.json`
- Rendering runs through ZG-4 in the browser; only `article.rz-resume` in the sandbox changes; Theme switch and Print preview keep working on the Author's data
- Humane errors rendered in a `[data-paste-error]` element, each with a plain-language sentence and the line/column when known: `empty`, `invalid-json` (with a hint for the two most common causes: trailing comma, unquoted text), `not-a-resume` (JSON parsed but a known key has the wrong shape — name the key), `missing-name`, `not-json-file` (a dropped/opened non-JSON file such as a PDF, naming what it received)
- The last accepted Resume is kept in `localStorage` (`resumezen.resume`) and restored on reload, with a "Forget my résumé" button that clears it and restores Jordan Hale
- Sidebar copy near the control states "Nothing leaves your browser until you publish"
## Scope out
- Explaining the format / copyable example / sample buttons (ZG-6)
- Publishing, hosted URLs (ZG-21/22)
- A form editor, PDF/LinkedIn import, Bridge dialects (Phase 5 / RZ-7, RZ-9)
- Field-level warnings (unknown keys) — the renderer ignores them by contract §1.8
- Download HTML/CSS as a headline (BAR-X1 / lock 8)
## Acceptance criteria
- [ ] Probe `ZG-5/paste-sample`: pasting `skeleton/resume.json` into `#paste-input` and pressing the panel's "Show it" button yields sandbox `.rz-name` = `Jordan Hale` with `data-rz-schema="1.0"` and no `[data-paste-error]`
- [ ] Probe `ZG-5/paste-ada`: pasting `{"basics":{"name":"Ada Lovelace"}}` yields `.rz-name` = `Ada Lovelace`, no `Jordan Hale` anywhere in the iframe document, iframe `src` unchanged, and `#theme-stylesheet` href unchanged
- [ ] Probe `ZG-5/paste-then-switch`: after the Ada paste, selecting Quarto changes `#theme-stylesheet` to `themes/quarto.css` and `.rz-name` is still `Ada Lovelace`; Print preview then shows `.rz-name` `Ada Lovelace`
- [ ] Probe `ZG-5/paste-empty`: pasting `""` and `"   \n"` shows `[data-paste-error="empty"]` and `.rz-name` is unchanged
- [ ] Probe `ZG-5/paste-trailing-comma`: pasting `frontend/fixtures/trailing-comma.json` (`{"basics":{"name":"Elena",}}`) shows `[data-paste-error="invalid-json"]` whose text contains `line 1`, the word `comma`, and no Rust/serde token such as `expected` or `EOF`
- [ ] Probe `ZG-5/paste-not-resume`: pasting `{"basics":{"name":"E"},"work":"nope"}` shows `[data-paste-error="not-a-resume"]` whose text contains `work`
- [ ] Probe `ZG-5/paste-missing-name`: pasting `{"basics":{"label":"Junior Developer"}}` shows `[data-paste-error="missing-name"]` whose text contains `name`
- [ ] Probe `ZG-5/open-pdf`: setting the file input to `frontend/fixtures/not-a-resume.pdf` shows `[data-paste-error="not-json-file"]` whose text contains `PDF` and `JSON Resume`
- [ ] Probe `ZG-5/open-json`: setting the file input to `skeleton/resume.json` renders `Jordan Hale` without using the textarea
- [ ] Probe `ZG-5/restore`: after the Ada paste, a reload of the same origin shows `.rz-name` `Ada Lovelace`; clicking "Forget my résumé" restores `Jordan Hale` and `localStorage.getItem('resumezen.resume')` is `null`
- [ ] Probe `ZG-5/no-network`: the paste flow issues no HTTP request besides page assets and `themes/*.css`
- [ ] Probe `ZG-5/copy`: sidebar text contains `Nothing leaves your browser`; the control's accessible name contains `résumé`; chrome HTML/CSS still has no `rz-` class or id
- [ ] A stub that renders the paste by string-replacing `Jordan Hale` fails the Ada `no Jordan Hale` and the `work: "nope"` probes
## Dependencies
- ZG-2
- ZG-3
- ZG-4
## Notes
- none
