# ZG-8 Reviewer — PR #24

Branch `cursor/zg-8-copy-link-unknown-theme-f031` (`f7af6b0…7a88fa6`) vs `main` (`f0a5ab2`). Review only. Pinto left `in-progress`. No merge. No second PR. U3 print CSS / `U3_PRINT_PAGES` / DNS / TLS / issue #9 not touched.

## Verdict

**REVIEWER BLESS ZG-8**

## Must-verify (walked)

| # | Result | Evidence |
| --- | --- | --- |
| 1 copy-link | pass | `.copy-link` lives in View (`viewPreviewControls`). Port `copyLink` writes `window.location.href` via `writeClipboard` (not Paste's `copyText` / `onCopied`). Success → `Copied` + `data-copy-state="copied"` + `Process.sleep 2000` then `Clear`. Probe grants `clipboard-read` + `clipboard-write`, waits `view=print`, asserts order-insensitive `theme=quarto&view=print`, held ≥ 1 s, then detached. |
| 2 copy-failed | pass | `Finished False` sets `Failed` only — label is the prescribed sentence, never `Copied`. `begin` returns to `Idle` before the write. Fail probe `addInitScript` rejects `NotAllowedError`; reasons require `select the address bar`, exact sentence, empty `sawCopied` over 500 ms, no `pageerror`. |
| 3 view-url / view-back | pass | `SetPreview` batches `setPreviewMedia` + `pushViewQuery`. `gardenSearch` is the same generation as `theme`; `pushState` stays in `ports.js`. `previewFromQuery` is only `print` → Print preview, else Screen. Cold `?theme=&view=print` sets `aria-pressed` on **Print preview**; Nightgarden print body uses existing sheet (white). Reload keeps `view`. Back after Screen → Print preview restores Screen and drops or sets `view=screen`. |
| 4 unknown theme / escape / no-notice / invalid-view | pass | `ThemeId.fromQuery` is `Known id \| Unknown raw \| Absent` (pure). `applyLoadedQuery` does not `pushThemeQuery` — `?theme=banana` stays. Notice is `[data-theme-notice=unknown]` + Elm `Html.text raw` (literal, no markup). Close → `DismissNotice`. `Quarto` / `/` / `?theme=` → `Known` or `Absent` → no notice. `?view=sideways` → Screen, no notice. |
| 5 ThemeId + history seam | pass | History math is `garden-query.js` (`gardenSearch` / `readGardenQuery`); `popstate` sends both fields on `onGardenQuery`. Elm never builds a URL. Unknown theme is never rewritten to Nightgarden. Author résumé is not added to the search string. |
| 6 probes named | pass | `frontend/scripts/probes/zg-8.mjs` exports `ZG-8/copy-link`, `copy-failed`, `view-url`, `view-back`, `unknown-theme`, `notice-escaped`, `no-notice`, `invalid-view`. Wired in `probes.mjs`. Calculations unit-tested in `zg-8.test.mjs` + `garden-query.test.mjs`. `openGarden` `path` defaults to `/` for existing callers. |
| 7 existing S4 / S5 / U3 / ZG-4–7 | pass | S5 Back still reads `theme` from the URL and `onGardenQuery` restores the sheet. S4 still finds **Print preview** / **Screen** / `#theme-option-*`. `U3_PRINT_PAGES` still `{nightgarden: 2, quarto: 2, switchyard: 2}` (not in the `probes.mjs` hunk). `.preview-controls__print` and the Print preview name are unchanged. |
| 8 locks + one PBI | pass | Chrome classes/ids: `copy-link`, `theme-notice*`. No `rz-` class or id. `qa/MARKET-QUALITY-BAR.md` and `themes/` not in the diff. Sample intent still `Swap` only (Paste untouched). JSON Resume remains the only stored Resume. `test:unit` still `node --test --test-reporter=spec $(find scripts static -name '*.test.mjs')` (package.json not touched). Pinto status `in-progress`; `just verify` AC left open for the carved-out `ZG-11/page-count quarto` miss. 20 files, all ZG-8. |

## Non-goals honored

- Hosted résumé / Publish (ZG-22), ZG-9 mobile, ZG-10, ZG-14, auth, payments, PDF — not present.
- Unknown `?theme=` is not rewritten to the fallback.
- Author Resume is not persisted in the URL.
- Theme print CSS and `U3_PRINT_PAGES` / `LONG_PRINT_PAGES` not edited.
- HTTPS / DNS / TLS / issue #9 / Netlify production not touched.
- Pinto not marked `done` or `review`.
- Print preview toggle not renamed; `.preview-controls__print` kept.
- No second ticket or PR.

## Checks run here

- Full diff vs `f0a5ab2`: 20 files, +954/−92.
- `npm run test:unit` → 167/167, including `zg-8.test.mjs` and `garden-query.test.mjs`.
- `U3_PRINT_PAGES` still `{nightgarden: 2, quarto: 2, switchyard: 2}`.
- Chrome Elm/CSS: no `rz-` class or id on new markup.

Could not re-execute Chromium probes or `just verify` in this VM: `elm` / `wasm-pack` absent, rustc 1.83 (crate wants 1.87). Generator PASS lines in `docs/plans/zg-8-execution.md` match the source wiring. Not a reject.

## Notes (not blockers)

- `CopyLink.finish` does not key on `gen` (same shape as Paste's example copy). A stale in-flight write could theoretically flip state; AC paths are single-click and the fail path never sets `Copied`.
- Init flags still parse `theme`/`view` with `URLSearchParams` instead of `readGardenQuery`. Same `|| ""` semantics.
- `just verify` AC left unchecked because of pre-existing `ZG-11/page-count quarto` 4 vs 3. Human instruction: not a ZG-8 reject. Print CSS / `U3_PRINT_PAGES` did not move.

**REVIEWER BLESS ZG-8**
