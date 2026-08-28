# ZG-7 Reviewer — PR #23

Branch `cursor/zg-7-plain-language-chrome-e9ad` (`2fbb4ff…797a7a0`) vs `main` (`8842b9c`). Review only. Pinto left `in-progress`. No merge. No second PR. U3 print CSS / `U3_PRINT_PAGES` / DNS / TLS / issue #9 not touched.

## Verdict

**REVIEWER BLESS ZG-7**

## Must-verify (walked)

| # | Result | Evidence |
| --- | --- | --- |
| 1 no-jargon | pass | Closed About is `Html.text ""` (dialog off the tree). Lede is the prescribed sentence. Heading `Appearance` (not `Chrome`/`CHROME`). Required substrings `Appearance`, `For paper`, `Print / Save as PDF`, `Pick a look for your résumé` are `Html.text` / button copy. Banned tokens `rz-target`, `@media`, `Skeleton`, `judged on hover` are gone from Elm view strings; compiled `garden.js` has none of them. Hidden paste panel stays in `textContent` and is still ZG-6-clean. Probe uses `document.body.textContent`, not `innerText`. |
| 2 one-print | pass | One control whose accessible name starts with `Print /`: aria-label + text `Print / Save as PDF` on `.preview-controls__print`. `PrintRequested` → `printGarden ()` → `ports.js` `printChildDocument()` → `iframe.contentWindow.print()`. View toggle still exactly `Print preview`. Playwright locators in `ZG-7/one-print` match both. |
| 3 badges | pass | `targetLabel`: Nightgarden `Web` → `Screen`; Quarto `Print` → `Paper`; Switchyard `Both` → `Screen + paper`. Badge `textContent` is those strings (CSS `text-transform: uppercase` is pre-existing and does not change `textContent`). No badge text equals `web`/`print`/`both`. Class names `badge--web` etc. stay CSS-only. |
| 4 about | pass | Open tree is `[role="dialog"].about-panel` (`aria-modal`, labelled by `#about-title`). Copy includes `Free during the preview. Pricing is not announced.` `href` is exactly `https://github.com/subzerocorp/cvzengarden` (`About.repoHref`; probe string-equality, request log rejects a GitHub fetch). Escape → `Dismissed` → `Focus "about-open"` → `focusId` (double rAF). Close button also dismisses. |
| 5 print-on-white + S3/U3 guard | pass | Switcher note: `Every theme prints in dark ink on white paper`. `git diff origin/main...HEAD -- themes/` empty. `U3_PRINT_PAGES` still `{nightgarden: 2, quarto: 2, switchyard: 2}` (not in the `probes.mjs` hunk). S3/U3 still click `.preview-controls__print` and `Print preview`. Chrome `@media print` only adds `.about-panel { display: none }` beside the existing sidebar hide — not theme print CSS. ZG-11 quarto 4-vs-3 leftover is pre-existing; print CSS untouched, so not a ZG-7 reject. |
| 6 RZ-3 / S1–S5 / U3 selectors | pass | `#theme-option-${id}` still on each option. `.preview-controls__print` kept. Button name `Print preview` kept. Existing `getByRole('button', { name: 'Screen' })` now `{ exact: true }` so `For screen` / `Nightgarden Screen` cannot steal the View toggle. S4 still accepts `Print preview` in the tab walk. |
| 7 chrome `rz-` / BAR-Q1 / one PBI | pass | New ids: `about-open`, `about-panel`, `about-title`, `about-designers-title`, `about-close`. Classes: `app-footer`, `about-*`. No `rz-` class or id in chrome Elm/CSS. Static chrome scan roots (`src/`, `css/`, `static/`) unchanged. `qa/MARKET-QUALITY-BAR.md` not in the diff; BAR-Q1 name `Independent Product Experience Guardian` still present. Diff is 12 files, all ZG-7. Pinto AC boxes still unchecked; status `in-progress` only. |
| 8 For designers / no invented price | pass | `about-panel__designers` is an `h3` “For designers” and nothing else (ZG-14 slot). No kit links, no Coming soon, no fake submit. Price line is the prescribed “Free during the preview. Pricing is not announced.” — no dollar amount, no launch date. |

## Non-goals honored

- Theme print CSS and `U3_PRINT_PAGES` / `LONG_PRINT_PAGES` not edited.
- HTTPS / DNS / TLS / issue #9 / Netlify production not touched.
- Pinto not marked `done` or `review`.
- Print preview toggle not renamed.
- Designer-kit links left to ZG-14; share controls left to ZG-8; mobile layout left to ZG-9.

## Checks run here

- Full diff vs `origin/main` (`8842b9c`): 12 files, +731/−29.
- `elm make src/Main.elm` → 8 modules, including `About`.
- `npm run test:unit` → 154/154, including `frontend/scripts/probes/zg-7.test.mjs`.
- Compiled Elm has the prescribed copy and the exact GitHub href; no `Html.text` of `Chrome`/`Skeleton`/`rz-target`.

Could not re-execute Chromium probes or `just verify` in this VM: `wasm-pack` absent, rustc 1.83 (crate wants 1.87), no Playwright browsers. Generator PASS lines in `docs/plans/zg-7-execution.md` match the source wiring. Not a reject.

## Notes (not blockers)

- `page.waitForFunction` in `ZG-7/one-print` (and the existing U3 print stub) returns a JSHandle, so `if (!called)` is dead; a missed `print()` throws instead of a clean FAIL. Same pattern as U3. Tester’s problem if they want a quieter fail.
- Badge labels render as SCREEN / PAPER / SCREEN + PAPER via pre-existing `.badge { text-transform: uppercase }`. AC and probe are `textContent`.
- `just verify` AC left unchecked because of pre-existing `ZG-11/page-count quarto` 4 vs 3. Human instruction: not a ZG-7 reject unless print CSS moved. It did not.

**REVIEWER BLESS ZG-7**
