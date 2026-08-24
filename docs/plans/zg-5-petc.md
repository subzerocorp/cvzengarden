# ZG-5 PETC — Paste or open your own JSON Resume and see it in every Theme

**PBI:** ZG-5 (triple-blessed) · deps ZG-2, ZG-3, ZG-4 done
**AXEL:** Generator `code-writer` (Elm + JS + probes); adversaries reviewer → tester → architect (Elm/JS)
**Decomposition mode:** off

## Goal
An Author pastes or opens a JSON Resume, sees it in every Theme and in Print preview, gets plain-English errors with line/column, and has it restored on reload — nothing leaves the browser.

## Approach
Phase 1: Elm `Paste` module (pure calcs: `classify : String -> Result PasteError String` with JSON parse via `Json.Decode.decodeString Json.Decode.value` (line/column from Elm's error? — Elm gives no line/col; use a small pure JS `jsonPosition(text)` calc exposed via flag-free port, or compute line/col in Elm by scanning for the first parse failure using a tiny tokenizer — Generator decides, must be pure and unit-tested), known-key shape check for `not-a-resume` naming the key, `missing-name`), view of the panel (sidebar, above Themes: "Use my résumé" button → panel with `#paste-input` + "Show it"), `[data-paste-error=…]` messages, `renderResume`/`onRendered` wiring → `swap`; `render-failed` message with console.debug. Probes `ZG-5/paste-*`, `render-failed`, `no-serde-tokens`, `paste-then-switch`. Phase 2: file input + drop zone + content-first classification (`not-json-file` naming the file), `localStorage` restore/forget/corrupt handling, sidebar copy, probes `open-*`, `file-classes`, `drop-*`, `restore`, `corrupt-storage`, `no-network`, `copy`; fixtures `trailing-comma.json`, `not-a-resume.pdf`.

## Files likely
`frontend/src/{Main,Paste}.elm` (+ `Paste/Classify.elm`), `frontend/static/{ports,render}.js` (thin wiring only), `frontend/css/chrome.css` (GPUI tokens, no rz-), `frontend/scripts/probes/zg-5.mjs` (+ lib calcs + tests), `frontend/fixtures/*`.

## Test strategy
Per AC; anti-stub (string-replace stub fails Ada/no-Jordan and `work: "nope"`); `elm-test` is not installed — pure Elm calcs are exercised through probes; JS calcs via node:test.

## Risk
Line/column for invalid JSON: Elm's decoder error lacks positions — needs a pure tokenizer calc (JS or Elm). Keep it small.

## Phases
1. **Phase 1 of 2** — panel, classification, errors, render/swap, core probes.
2. **Phase 2 of 2** — file/drop, storage, copy, remaining probes.

## Unresolved questions
- none
