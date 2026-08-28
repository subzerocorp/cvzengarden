# ZG-13 Reviewer — PR #27

Branch `cursor/zg-13-self-host-fonts-c1ee` (`dd50da3…7b0744a`) vs `main` (`7dc0550`). Review only. Pinto left `in-progress`. No merge. No ready. No deploy. U3 print CSS / `U3_PRINT_PAGES` / `LONG_PRINT_PAGES` / DNS / TLS / issue #9 not touched.

## Verdict

**REVIEWER BLESS ZG-13**

## Must-verify (walked)

| # | Result | Evidence |
| --- | --- | --- |
| 1 scope | pass | Diff vs `7dc0550`: 36 files, all ZG-13. Theme CSS hunks are the thirteen `url("https://cdn.jsdelivr.net/…")` → `url("fonts/…")` lines only (quarto 8, switchyard 8, nightgarden 10). `probes.mjs` is import + `zg13Probes()` + banner. No Elm, no `frontend/css/`, no renderer/backend, no `qa/MARKET-QUALITY-BAR.md`, no netlify/HTTPS. |
| 2 @font-face | pass | `grep -rn jsdelivr themes/*.css` empty. `grep -c @font-face`: quarto 4, switchyard 4, nightgarden 5. Every `src` is `local("…")` then relative `url("fonts/<family>/….woff2")`. Family names, weights, styles unchanged (EB Garamond / IBM Plex Sans / Syne / Outfit). Themes remain one pure `.css` file. No webfont-loader JS. |
| 3 vendor + copy-dist | pass | 13 `wOF2` files under `themes/fonts/{eb-garamond,ibm-plex-sans,syne,outfit}/` plus `OFL.txt` each. `copy-dist.mjs` fail-loud-copies `themes/fonts/` → `dist/themes/fonts/`. `serve.mjs` already maps `.woff2` → `font/woff2` (untouched). |
| 4 README policy | pass | `themes/README.md` Fonts paragraph has `Font Library`, `CC BY 4.0`, `HTTPS CDN`, no host allowlist, JS loaders forbidden. Matches `docs/plans/fonts-decision.md` / CONTEXT Font Library. |
| 5 named probes | pass | `zg-13.mjs` exports `ZG-13/no-third-party`, `font-files`, `fonts-load`, `fallback`, `BAR-L1`. Wired in `probes.mjs`. Calculations in `theme-fonts.mjs` (brace-matched `topLevelBlocks`, loopback host filter, pair differ, FontFace reasons, console filter). `document.fonts.check` unused. BAR-L1 prints `BAR-L1 PASS`. |
| 6 fallback convention | pass | Fresh context, `page.route("**/themes/fonts/**", abort)` before `goto`. Fails on `pageerror` (`pageErrorReasons`, same stance as ZG-4 `wasm-load-failure`). Console `error` fails unless `locationUrl` or `text` contains `/themes/fonts/`. Pass line prints ignored count. `.rz-name` height > 0, S2 date-geometry, BAR-U2 `scrollWidth <= clientWidth`. |
| 7 locks | pass | `U3_PRINT_PAGES` / `LONG_PRINT_PAGES` absent from the `probes.mjs` hunk; still `{nightgarden:2,quarto:2,switchyard:2}` / `{3,3,3}`. Theme `@page` / print rules untouched. Chrome has no new `rz-` class or id. Typefaces not swapped. |

## Non-goals honored

- Font Library submit product — policy sentence only.
- Subsetting / new faces / dropped faces — counts 4/4/5.
- Print-page re-baseline — constants not edited; Generator U3 2/2/2.
- CDN host allowlist — none added.
- HTTPS / issue #9 / `qa/MARKET-QUALITY-BAR.md` — not in the diff.

## Checks run here

- Full name list vs `7dc0550`: 36 paths, ZG-13 only.
- `grep -c @font-face` 4/4/5; jsDelivr absent from `themes/*.css`.
- Thirteen woff2 files begin `wOF2`.
- `node --test frontend/scripts/probes/lib/theme-fonts.test.mjs frontend/scripts/probes/zg-13.test.mjs frontend/scripts/probes/lib/request-log.test.mjs` → 18/18.
- `U3_PRINT_PAGES` still `{nightgarden: 2, quarto: 2, switchyard: 2}`.
- Chrome Elm/CSS: not in the diff. No chrome `rz-`.

Could not re-execute Chromium probes or `just verify` in this VM: `elm` / `wasm-pack` absent, rustc 1.83 (crate wants 1.87). Generator PASS lines in `docs/plans/zg-13-execution.md` match the source wiring. Not a reject.

## Notes (not blockers)

- Fallback rolls its own context instead of `openGarden({ beforeNavigate })`. PBI asked for a fresh context; pageerror + filtered console still match ZG-4 + the abort clause.
- `isGardenAsset` comment still says “themes/*.css”; the predicate now also allows `/themes/fonts/*.woff2` so origin faces are not off-garden leaks.
- `just verify` AC left unchecked because of pre-existing `ZG-11/page-count quarto` 4 vs 3. Human instruction: not a ZG-13 hold. `U3_PRINT_PAGES` did not move.
- Pinto `in-progress`; DoD triple-BLESS still open. Tracking only.

**REVIEWER BLESS ZG-13**
