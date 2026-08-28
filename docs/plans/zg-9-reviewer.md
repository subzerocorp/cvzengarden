# ZG-9 Reviewer — PR #25

Branch `cursor/zg-9-phone-theme-sheet-d6dc` (`6b36edb…b66dabc`) vs `main` (`bc664a9`). Review only. Pinto left `in-progress`. No merge. No second PR. U3 print CSS / `U3_PRINT_PAGES` / DNS / TLS / issue #9 not touched.

## Verdict

**REVIEWER BLESS ZG-9**

## Must-verify (walked)

| # | Result | Evidence |
| --- | --- | --- |
| 1 mobile-first | pass | ≤720px `@media screen`: `.garden-stage` / `--print` get `order: -1`, `flex: 1 1 auto`, `padding: 0`; `.app-shell` is `100dvh` column flex with `overflow: hidden`. `#garden-frame` is `height: 100%`. Probe `ZG-9/mobile-first` at 390×844 wants `frameTop < 80` and `.rz-name` intersecting the chrome viewport (`nameInViewport`). |
| 2 sheet | pass | Closed bar is sticky `bottom: 0`; `.app-sidebar__sheet { display: none }`; `.btn.sidebar-toggle` is `inline-flex` 100%. Open class is `.app-sidebar--open` (fixed bottom sheet, `max-height: min(90dvh, 100%)`). Elm `sidebarOpen : Bool`; toggle `#theme-toggle` text `Theme`, `aria-expanded` true/false, `aria-controls="theme-sheet"`. `applyTheme` sets `sidebarOpen = False`. Probe clicks Theme → `#theme-option-quarto` → `themes/quarto.css` + `aria-expanded="false"`. |
| 3 escape + scroll lock | pass | `sidebarKeys` is `Events.onKeyDown` only while `sidebarOpen`. `closeSidebar` sends `focusId "theme-toggle"` (same double-rAF port as About). Body lock is `html:has(.app-shell--sidebar-open), body:has(...) { overflow: hidden }` **inside** the 720px query only. Probe `ZG-9/escape` waits for `aria-expanded="false"` and `activeElement.id === "theme-toggle"`. |
| 4 desktop-unchanged | pass | Root `.btn.sidebar-toggle { display: none }` beats `.btn { display: inline-flex }`. 720px query is an override **after** the existing `52rem` single column; grid stays `18.5rem \| 1fr` at 1280×800. Phone rules are `@media screen` so print chrome is untouched. Probe hides `#theme-toggle` at 1280×800 and re-checks S1–S5 date geometry on all three Themes. |
| 5 no-hscroll | pass | `hscrollReasons` is `scrollWidth <= 390`. Probe opens `/?theme=` nightgarden / quarto / switchyard at 390×844. |
| 6 probes named | pass | `frontend/scripts/probes/zg-9.mjs` exports `ZG-9/mobile-first`, `sheet`, `escape`, `desktop-unchanged`, `no-hscroll`. Wired in `probes.mjs` after ZG-8. Calculations unit-tested in `zg-9.test.mjs` (10 tests). `test:unit` still `node --test --test-reporter=spec $(find scripts static -name '*.test.mjs')` — package.json not in the hunk. |
| 7 existing S1–S5 / U3 / ZG-4–8 | pass | Probe imports only add `zg9Probes`. `U3_PRINT_PAGES` still `{nightgarden: 2, quarto: 2, switchyard: 2}` (not in the `probes.mjs` hunk). View toggle still **Print preview**. `.preview-controls__print` kept. ZG-8 `.copy-link` / `ThemeId.fromQuery` / unknown `?theme=` not in this diff. |
| 8 locks + one PBI | pass | New chrome names: `sidebar-toggle`, `app-sidebar__sheet`, `app-sidebar--open`, `app-shell--sidebar-open`, `#theme-toggle`, `#theme-sheet`. No `rz-` class or id. `qa/MARKET-QUALITY-BAR.md`, `themes/`, `Paste.elm`, `CopyLink.elm`, `ports.js` not in the diff vs `bc664a9`. Sample Intent still does not Store. Pinto `in-progress`; `just verify` AC left open for the carved-out `ZG-11/page-count quarto` miss. 10 files, all ZG-9. |

## Non-goals honored

- Mobile theme-card restyle, swipe / gestures, native share sheet — not present.
- ZG-10, ZG-14, auth, payments, PDF, hosted résumé — not present.
- Theme print CSS and `U3_PRINT_PAGES` / `LONG_PRINT_PAGES` not edited.
- HTTPS / DNS / TLS / issue #9 / Netlify production not touched.
- `qa/MARKET-QUALITY-BAR.md` not in the diff.
- Residual ZG-8 Copied flash not touched (`CopyLink.elm` absent from this PR).
- Pinto not marked `done` or `review`.
- Print preview toggle not renamed; `.preview-controls__print` kept.
- No second ticket or PR.

## Checks run here

- Full diff vs `bc664a9`: 10 files, +652/−13.
- `npm run test:unit` → 177/177, including `frontend/scripts/probes/zg-9.test.mjs`.
- `U3_PRINT_PAGES` still `{nightgarden: 2, quarto: 2, switchyard: 2}`.
- Chrome Elm/CSS: no `rz-` class or id on new markup.
- `test:unit` remains a `find` walk (no unquoted glob under `sh`).

Could not re-execute Chromium probes or `just verify` in this VM: `elm` / `wasm-pack` / `pinto` absent, rustc 1.83 (crate wants 1.87). Generator PASS lines in `docs/plans/zg-9-execution.md` match the source wiring. Not a reject.

## Notes (not blockers)

- About and the sheet both subscribe to Escape when both are open (phone path only). Desktop About is unchanged (`sidebarKeys` is `Sub.none` while closed). One Escape may close both and race `focusId`; AC only requires the sheet + Theme focus.
- Theme pick closes the sheet via `applyTheme` without `focusId`. AC `ZG-9/sheet` does not require focus return; `ZG-9/escape` does.
- `just verify` AC left unchecked because of pre-existing `ZG-11/page-count quarto` 4 vs 3. Human instruction: not a ZG-9 reject. Print CSS / `U3_PRINT_PAGES` did not move.

**REVIEWER BLESS ZG-9**
