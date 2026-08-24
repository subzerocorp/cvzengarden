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
1. **Phase 1 of 2** — panel, classification, errors, render/swap, core probes. **Done** (`32ef15b`, GAN BLESS ×3).
2. **Phase 2 of 2** — file/drop, storage, remaining probes. In progress.

## Phase 2 plan (2026-08-24)

**Goal.** Open a file, drop a file, restore on reload, forget, no network, remaining copy.

**Approach.**
- `not-json-file` is a `Problem` with the filename. Classification stays content-first (JSON bytes win over extension).
- File/drop reading is ports wiring (`FileReader`); **no new Elm/npm deps** (`elm/file` not installed, do not add).
- Extend `Paste.Effect` with `Store String` and `Forget`. Store the raw accepted JSON string (`resumezen.resume`), never HTML. Restore sets `text` + accepted datum and `Render`s; Forget clears both and restores Jordan (crate sample already in the iframe — do not re-fetch).
- Corrupt / unparseable / un-renderable stored value: drop the key, show Jordan, no banner, no console error / pageerror.
- `Main.update` does not grow past `applyPaste` + mapping incoming file/restore ports onto `Paste.Msg`. Smell to reject: new product branches in `Main`.
- Drop zone: `[data-drop-zone]`; file input: `accept=".json,application/json"`.
- Copy AC remainder: accessible name contains `résumé`; chrome still has no `rz-` class/id. Hint sentence already landed in phase 1.

**Files.** `frontend/src/Paste.elm`, `Paste/Classify.elm`, `Main.elm` (seam only), `frontend/static/ports.js`, `frontend/css/chrome.css`, `frontend/scripts/probes/zg-5.mjs` + `lib/paste.mjs` tests, `frontend/fixtures/not-a-resume.pdf`.

**Probes (must PASS).** `open-pdf`, `open-json`, `file-classes`, `drop-json`, `drop-pdf`, `restore`, `corrupt-storage`, `no-network`; `copy` still green; all phase-1 `ZG-5/*` stay green.

**Risk.** Playwright `setInputFiles` + synthetic `DataTransfer` drop; restore race with sandbox load.

## Unresolved questions
- none
