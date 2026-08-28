# ZG-10 Reviewer — PR #26

Branch `cursor/zg-10-page-estimate-2615` (`8d2e336…67221cd`) vs `main` (`802c0d5`). Review only. Pinto left `in-progress`. No merge. No second PR. U3 print CSS / `U3_PRINT_PAGES` / DNS / TLS / issue #9 not touched.

## Verdict

**REVIEWER BLESS ZG-10**

## Must-verify (walked)

| # | Result | Evidence |
| --- | --- | --- |
| 1 pure module | pass | `frontend/static/page-estimate.js` is an ES module with no `document` / `window` / DOM. Exports `pageGeometry` / `estimatePages` / `estimateLabel` only. Data: Letter 816×1056, A4 793.7×1122.5, 1 cm = `96/2.54`. Calculations only. Imported by `ports.js` and `page-estimate.test.mjs`. |
| 2 geometry rules | pass | Last base rule (`selector === ""` or `"@page"`) wins. `:first` / named pages ignored. `size` trimmed, compared lower-case. Empty size → Letter / `default`. `8.5in 11in` / `a4 landscape` / `legal` → Letter / `fallback`, no throw. Margins `in`/`cm`/`mm`/`pt`/`px` at 96 dpi; no margins → 1 cm each side. Unit cases hit every prescribed number (0→1, 946→1, 946.5→2, 1892→2, 1893→3; Quarto 681.6×945.6; Switchyard 672.8×1009.1; `A4` upper-case; `:first` alone → default). |
| 3 collectPageRules + measure | pass | `ports.js` walks `CSSPageRule` and recurses `CSSMediaRule` / `CSSSupportsRule` (Nightgarden / Switchyard `@page` in `@media print`). Height: one sync task sets `documentElement.style.width` to `contentWidthPx`, reads `.rz-resume.getBoundingClientRect().height`, `removeProperty("width")` + `removeAttribute("style")`. Observer disconnected for that task so the echo cannot loop. Inbound `pageEstimate` after theme swap settled, View → Print preview, and a rAF-coalesced `ResizeObserver` on iframe `body`. |
| 4 Elm readout + hint | pass | Readout only when `PrintPreview` + `Just estimate`: `.preview-controls__pages` with `data-page-estimate`, `data-page-size`, `data-page-size-source`. Screen is `Html.text ""` (attribute off the tree). Hint is a sibling `<p class="preview-controls__hint" data-pdf-hint>` after ZG-7’s “What you see here is what the printer prints.” Copy is the prescribed Save-as-PDF sentence. Both views. |
| 5 named probes + units | pass | `zg-10.mjs` exports `ZG-10/paper-size`, `paper-size-fallbacks`, `estimate-matches-formula`, `estimate-near-pdf`, `updates-on-switch`, `updates-on-content`, `min-one`, `hint`, `no-guide-lines`. Wired in `probes.mjs`. Formula probe recomputes N (no pinned constants, no `page.emulateMedia`). Fallbacks route `**/themes/switchyard.css` then `unroute`. Content probe is a `cloneNode` DOM edit, not paste / not `long-resume.*`. `page-estimate.test.mjs` + `zg-10.test.mjs` reason helpers. |
| 6 no second ticket | pass | Diff vs `802c0d5`: 14 files, all ZG-10. `git diff 802c0d5...HEAD -- themes/` empty. `U3_PRINT_PAGES` not in the `probes.mjs` hunk (still `{nightgarden: 2, quarto: 2, switchyard: 2}`). No `printableHeightPx` reuse, no paged.js, no overlay, no server PDF, no `qa/MARKET-QUALITY-BAR.md`, no issue #9 / HTTPS. `frontend/package.json` not in the diff — `test:unit` stays `node --test --test-reporter=spec $(find scripts static -name '*.test.mjs')` (no unquoted `sh` glob). |
| 7 locks | pass | View toggle still exactly **Print preview**. `.preview-controls__print` kept; one `Print / Save as PDF` button. New chrome classes/ids: `preview-controls__pages`, `data-page-estimate`, `data-page-size`, `data-page-size-source`, `data-pdf-hint`. No `rz-` class or id. Copy-link still in View. `sidebarOpen` Theme sheet stays. Sample intent untouched (`Swap` only). JSON Resume remains the only stored Resume. Pinto `in-progress`; AC boxes still open. |

## Non-goals honored

- Page-boundary guide lines / paged.js / server PDF — not present. `no-guide-lines` requires one `#garden-frame` child, one `article.rz-resume` in the iframe, no injected `<style>`/`<script>`.
- ZG-11 `printableHeightPx` / `long-resume.*` unused. Content updates are probe-side clones.
- Theme print CSS and `U3_PRINT_PAGES` / `LONG_PRINT_PAGES` not edited.
- HTTPS / DNS / TLS / issue #9 / Netlify production not touched.
- Pinto not marked `done` or `review`.
- Print preview toggle not renamed; `.preview-controls__print` kept.
- No second ticket or PR.

## Checks run here

- Full diff vs `802c0d5`: 14 files, +1076/−5 (GitHub); local `802c0d5...HEAD` name list matches.
- `node --test frontend/scripts/page-estimate.test.mjs frontend/scripts/probes/zg-10.test.mjs` → 16/16.
- `find scripts static -name '*.test.mjs'` from `frontend/` still walks the tree (24 files), including `scripts/page-estimate.test.mjs`.
- `U3_PRINT_PAGES` still `{nightgarden: 2, quarto: 2, switchyard: 2}`.
- Chrome Elm/CSS: no `rz-` class or id on new markup.

Could not re-execute Chromium probes or `just verify` in this VM: `elm` / `wasm-pack` absent, rustc 1.83 (crate wants 1.87). Generator PASS lines in `docs/plans/zg-10-execution.md` match the source wiring. Not a reject.

## Notes (not blockers)

- `measureResumeHeight` also installs a one-shot empty-`style` MutationObserver and strips `style` again on two rAFs after the sync read. The set / measure / clear is still one task; the extra mop exists so a ResizeObserver echo cannot leave `style=""`. AC and `no-guide-lines` still require `getAttribute("style") === null`.
- `isBaseSelector` treats `selector === "@page"` as base in addition to `""`. CSSOM variance; `:first` / named pages still ignored.
- PBI “today” Quarto 3 / Switchyard `|N−pdf| = 1` is informational. Probes recompute: evidence is 2/2/2 and `|N−pdf| = 0`.
- `just verify` AC left unchecked because of pre-existing `ZG-11/page-count quarto` 4 vs 3. Human instruction: not a ZG-10 reject. Print CSS / `U3_PRINT_PAGES` did not move.
- Pinto `commits` lists `8d2e336`, `65e9673`, `59707d4` and omits evidence commit `67221cd`. Tracking only.

**REVIEWER BLESS ZG-10**
