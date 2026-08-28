# ZG-8 PETC — Copy a link to this exact view; say so when `?theme=` is unknown

**PBI:** ZG-8 (avril-blessed) · deps none (ZG-7 already on main as `f0a5ab2`)
**AXEL:** Generator `code-writer` (Elm + JS + probes); adversaries reviewer → tester → architect (Elm/JS)
**Decomposition mode:** off

## Goal
Elena copies a link to the exact view she sees (theme + screen/print). Unknown `?theme=` keeps the sender's URL and names the miss. She stops screenshotting.

## Approach
Phase 1: `ThemeId.fromQuery → Known id | Unknown raw | Absent` (pure). `view=print|screen` mirrored with the preview toggle via the same `gardenSearch` generation as `theme` (history stays in `ports.js`). `.copy-link` writes `location.href`; 2 s `Copied` / reject → `Copy failed — select the address bar and copy it` (never `Copied`). Dismissible `[data-theme-notice=unknown]` built with Elm `text` (raw query is literal). Empty/absent `theme` and invalid `view` show no notice; URL is never rewritten to the fallback.
Phase 2: named `ZG-8/*` probes + unit-tested calculations; existing S4 permalink + Back, S5, U3, ZG-7 stay green.

## Files
`frontend/src/{ThemeId,Main,CopyLink}.elm`, `frontend/static/{garden-query,ports,clipboard}.js`, `frontend/css/chrome.css`, `frontend/scripts/copy-dist.mjs`, `frontend/scripts/probes/{zg-8.mjs,zg-8.test.mjs,probes.mjs,lib/page.mjs,lib/request-log.mjs}`, `frontend/README.md`, this file, `progress.md`, `features.json`, `.pinto/tasks/ZG-8.md`.

## Test strategy
Named probes `ZG-8/copy-link`, `copy-failed`, `view-url`, `view-back`, `unknown-theme`, `notice-escaped`, `no-notice`, `invalid-view`. Clipboard happy path grants both permissions. Failure path `addInitScript` rejects `NotAllowedError`. Notice asserts `textContent` + `querySelector('b') === null`. Existing RZ-3 / S1–S5 / U3 / ZG-4/5/6/7 stay green. `U3_PRINT_PAGES` untouched. Pre-existing carved-out miss: `ZG-11/page-count quarto`.

## Risk
`onCopied` is Paste's. Copy link uses its own `copyLink` / `onLinkCopied` so a reject cannot flip the example button to `Copied`. Popstate must deliver theme **and** view in one message or Back restores the sheet and loses Print preview.

## Phases
1. **Phase 1 of 2** — ThemeId result, view query, copy-link, unknown notice, history calc.
2. **Phase 2 of 2** — probes, unit tests, README, evidence.

## Unresolved questions
- none (copy, notice, and view param are prescribed; hosted résumé links are ZG-22)

## Execution Evidence

_Filled after probes run._
