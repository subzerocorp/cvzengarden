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

Log: `/tmp/zg8-probes.log` (`PROBE_PORT=4488 node scripts/probes.mjs` after `npm run build`). Rust half (`cargo fmt --check`, clippy pedantic, `cargo test` on renderer + renderer-wasm) was green on rustc 1.87.0 before that run.

- [x] `ZG-8/copy-link` — `PASS  ZG-8/copy-link Copy link writes ?theme=quarto&view=print and shows Copied for ≥ 1s`
- [x] `ZG-8/copy-failed` — `PASS  ZG-8/copy-failed rejected writeText shows Copy failed and never Copied`
- [x] `ZG-8/view-url` — `PASS  ZG-8/view-url ?theme=&view=print opens Print preview; Nightgarden print body is white; reload keeps view`
- [x] `ZG-8/view-back` — `PASS  ZG-8/view-back Back after Print preview returns to Screen and drops or sets view=screen`
- [x] `ZG-8/unknown-theme` — `PASS  ZG-8/unknown-theme unknown ?theme=banana keeps the URL, names the miss, and Close dismisses it`
- [x] `ZG-8/notice-escaped` — `PASS  ZG-8/notice-escaped unknown theme notice renders the raw query as text, not markup`
- [x] `ZG-8/no-notice` — `PASS  ZG-8/no-notice /?theme=Quarto, /, and /?theme= show no theme notice`
- [x] `ZG-8/invalid-view` — `PASS  ZG-8/invalid-view ?view=sideways opens Screen with no notice and no crash`
- [x] Existing S4 permalink + Back and S5 — all PASS in the same run (S5 `?theme=quarto` / Back Nightgarden / cold `switchyard` / empty+unknown default).
- [x] Existing RZ-3 / S1–S5 / U3 / ZG-4/5/6/7 — all PASS. `U3_PRINT_PAGES` still `{nightgarden: 2, quarto: 2, switchyard: 2}`; Garden/iframe and chrome-shell printToPDF 2/2/2. View toggle still **Print preview**. `.preview-controls__print` unchanged. Chrome markup/CSS `rz-` check silent (no FAIL).
- [ ] `just verify` exit 0 — rust + every ZG-8 / U3 / S4 / S5 / ZG-7 probe green. Same-run leftover: `FAIL  ZG-11/page-count quarto … long-resume.html is 4 page(s), LONG_PRINT_PAGES is 3` (pre-existing on main / PR #23 Tester note; sandbox-only; chrome and `U3_PRINT_PAGES` untouched). Not fixed here.

Unit tests: `npm run test:unit` 167/167 including `frontend/scripts/probes/zg-8.test.mjs` and `frontend/static/garden-query.test.mjs`.
