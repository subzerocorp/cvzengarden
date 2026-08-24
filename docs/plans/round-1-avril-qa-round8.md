# AVRIL round 1 — QA Architect review (cycle 8)

**Role:** `qa-architect-agent` (second adversary) · **Date:** 2026-08-24 · **Cycle:** 8 (fresh review after the Generator's cycle-8 revise and the PO's cycle-8 BLESS)
**Scope:** ZG-11 and ZG-20 — my cycle-6 REJECTs, revised in `round-1-avril-generator-round8.md`, both blessed by the PO in `round-1-avril-po-round8.md`. Prior verdicts lapsed with the body edits; each item is judged from scratch — every cycle-6 blocker is checked against the **current body** and against the repo (not against the Generator's change log), then the whole body is read again as if for the first time, and every example in every AC is run against its stated rule by hand. ZG-12 and ZG-19 were read for consistency only. Nothing else is judged.
**Inputs read in full:** `docs/plans/round-1-avril-qa-round6.md` (my blockers and set-level notes), `round-1-avril-generator-round8.md`, `round-1-avril-po-round8.md`, `round-1-avril-intent.md`, the two current bodies (`pinto show ZG-11 ZG-20 --plain`; `Depends on` unchanged: ZG-11 none, ZG-20 → ZG-19), `pinto show ZG-12 ZG-19 --plain`, `themes/{quarto,switchyard,nightgarden}.css` with line numbers, `frontend/scripts/probes.mjs` (1126 lines), `frontend/scripts/generate.mjs`, `frontend/package.json`, `justfile`.

Mandate: *BLESS only PBIs whose acceptance criteria are complete, falsifiable, and hostile to happy-path theater; otherwise REJECT with the missing cases.*

I judge testability only. I do not author bodies, touch the board, or reopen product scope. Cycle-1 conventions apply unchanged: one owner per shared fixture or helper; probe lines are `PASS  ZG-n/<slug>` / `FAIL  ZG-n/<slug> <reason>`; a PBI's own AC never prints `SKIPPED`; only Chromium is installed; nothing in the repo rasterises a PDF; `U3_PRINT_PAGES` is asserted with `!==`; `just verify` stays offline.

## Facts I verified before judging (each re-run against today's tree, not carried from cycle 6)

| Fact | How | Affects |
| --- | --- | --- |
| Line numbers cited by both bodies are right today: Quarto `@page :first` 58, `.rz-header` 104, `list-style: none` 148, `.rz-section { break-inside: avoid-page; page-break-inside: avoid }` 174–178 top level, `.rz-bullet::before { content: "– " }` 268–269, `@media print` 334; Quarto's print block mentions `.rz-section` only in `animation: none; transition: none` lists (354, 365) — no break rule there, as scope-in claims. Switchyard `list-style: none` 115, `.rz-entry-header > *` 121, `@media screen` 129, bar 256–264 (inside screen), `@media print` 334, avoid 397–398, `.rz-section--projects { break-before: page; page-break-before: always }` 402–403. Nightgarden `@property --rz-pulse` 62, `@keyframes` 68 / 80 / 90 (all `from`/`to` at 69, 74, 81, 85, 91, 95 — no percentage selector in any first-party sheet), `html`/`body` `#070b14` 100–116, sheen 173, `list-style: none` 199, rise 225, foxfire 271, `.rz-entry-header > *` 274, dot 309–318 (`content: ""`, `0.4rem` × `0.4rem`, `background: var(--rz-mint)`), `@supports` 364, guard 390 | `sed -n`, `grep -n` | ZG-11 scope-in, `no-forced-break`, `bullets-print`; ZG-20 AC 1 |
| **Chromium 151 print emulation:** `.q { break-inside: avoid-page; page-break-inside: avoid }` computes `breakInside` `avoid`; `.p { break-before: page; page-break-before: always }` computes `breakBefore` `page`; a `content: ""` bar with `width: .55rem; height: 2px` reports `getComputedStyle(el, '::before')` `content` `""`, `width` `8.79688px`, `height` `2px`, `backgroundColor` `rgb(180, 83, 9)`; `content: none` reports `content` `none`, `width` `auto`; `"– "` reports `"– "`; `li` `listStyleType` `none`; `Element.prototype.pseudo` is a function but `el.pseudo('::before')` is `undefined` for a generated box | `/tmp/persona-lab/qa6-facts.mjs` re-run today | ZG-11 blockers 1 and 2 |
| **The real pre-change sheets, `.rz-bullet::before` in print emulation** (each theme's full CSS injected as `<style>`, Skeleton stub `article.rz-resume > section.rz-section > ul.rz-bullets > li.rz-bullet`): Switchyard — `content` `none`, `width` `auto`, `height` `auto`, `backgroundColor` `rgba(0, 0, 0, 0)`, `printColorAdjust` `economy` (the bar rule is screen-only, so no box is generated). Nightgarden — `content` `""`, `width` `6.39062px`, `height` `6.39062px`, `backgroundColor` `rgb(159, 243, 200)` (mint), `printColorAdjust` `economy` (Nightgarden's print block sets `print-color-adjust: economy` at ~432; nothing sets `exact`) | `/tmp/persona-lab/qa8-facts.mjs` (new, Playwright Chromium 151, `emulateMedia({ media: 'print' })`) | ZG-11 `bullets-print` anti-vacuity sentence |
| `staticProbes()` (174–317) calls `pass()` fourteen times: `Generated theme list excludes …` 200, `Generated Themes.elm lists …` 213, `Sandbox document contains …` 219, `Sandbox does not link preview.css` 224, and the ten `S1`/`U3`/`U3`/`S3`/`S3`/`S2`/`S5`/`S4`/`U3`/`U3`-prefixed lines at 238, 244, 249, 259, 264, 270, 280, 290, 302, 315. Browser-only strings: `Live sandbox has data-rz-schema="1.0"` 478, `Jordan Hale is in .rz-name` 483, `S2 ${id}:` 647–670, `U3 ${id}` 813–819 and `U3 ${id}:` 856–914, `printToPDF` 690 / 813 / 864–870 / 908–914, `All RZ-3, RZ-S1…S5, and U3 print probes passed.` 1126 — every one inside `rz3BrowserProbes` / `s2Probes` / `s3Probes` / `u3IframePrintProbes` or after `startServer()` (1114). `N probe(s) failed.` at 1122. Today the file has no flag parsing | `grep -n 'pass('`, `grep -n`, `sed -n 1105,1126p` | ZG-20 `--static` AC |
| ZG-20's `content` examples against `/\p{L}{3,}/u` and `/[\p{Script=Han}\p{Script=Hiragana}\p{Script=Katakana}\p{Script=Hangul}]{2,}/u` in Node v20.18.0: `"Jordan Hale"` 1, `"名前"` 1, `"氏"` 0, `"Jr"` 0, `"vs"` 0, `"$ "` 0, `"▌"` 0, `" · "` 0, `"– "` 0, `"Page"` 1, `"Page "` 1, `"이름"` 1; first-party strings `""`, `" "`, `", "`, `": "` 0 | `node -e` | ZG-20 content AC; Notes line |
| First-party selectors outside `@keyframes`: a scan of every `selector {` line in the three sheets that lacks `rz-`, `html` or `body` returns nothing — every complex selector has an `html`/`body`/`.rz-*` compound. At-rule preludes present: `@font-face`, `@page` (Quarto 53 top level and 58 `:first`; Switchyard 335 and Nightgarden 404 inside `@media print`), `@property --rz-pulse` (Nightgarden 62), `@supports`, `@media`; no `::selection` / `::marker` in any first-party sheet | `grep -E` | ZG-20 AC 1, selector rule |
| `package.json`: `probe` = `npm run build && node scripts/probes.mjs`, `test` = `npm run probe`; `justfile`: `test-frontend` sets `PROBE_PORT=4310`, `verify: fmt clippy test`. `frontend/scripts/` holds `copy-dist.mjs generate.mjs probes.mjs serve.mjs` — no `*.test.mjs` yet; `generate.mjs` `parseTheme` at 27 is today's only header parser | read | ZG-20 wiring |
| `frontend/dist/sandbox.html` exists (built); ZG-12's body still says "`@keyframes` bodies excluded from the selector scan" and names `openResumePage(browser, { theme: 'nightgarden', width: 1280, height: 800 })`; ZG-19 owns `blank-theme.test.mjs` and does not edit `package.json` | `ls`, `pinto show` | consistency |

---

## ZG-11 — Print a real résumé without blank pages, lost bullets, or pale ink

### Cycle-6 blockers and notes, checked against the current body and the repo

| Cycle-6 blocker / note | Current body | Verified against | Resolved |
| --- | --- | --- | --- |
| **Blocker 1** — `bullets-print` marker-exists clause required `getBoundingClientRect()` on a `::before` box | Second alternative: `content` `""` / `none` / `normal` **and** `getComputedStyle(el, '::before').width` and `.height` each parse to > 0 px; parenthetical states a pseudo-element is not an Element, the computed read returns the used box size (`8.79688px` / `2px`), and `auto` (no box) fails; closing parenthetical: "both clauses use the one read `getComputedStyle(el, '::before')`". `getBoundingClientRect()` appears in the AC only in the sentence saying it cannot be called on a pseudo-element | Chromium: bar → `8.79688px` / `2px`; `content: none` → `auto`; real pre-change Nightgarden dot → `6.39062px` × `6.39062px` (so a dot passes marker-exists through its box, as the body says); real pre-change Switchyard → `none` / `auto` (fails) | **yes** — one executable read for both clauses, and I ran it on both real sheets |
| **Blocker 2** — `no-forced-break` anti-vacuity said pre-change Quarto computes `avoid-page` | "computes `breakInside` `avoid` in Chromium — line 177's `page-break-inside: avoid` is an alias of `break-inside: avoid`, is declared after line 176's `avoid-page`, and wins the cascade; anything other than `auto` fails — that FAIL line (reading `avoid`) is recorded in evidence" | Chromium: the 176–177 pair computes `avoid`; lines 176–177 are as quoted | **yes** — the recorded FAIL line will match the AC text |
| Non-blocking — `.rz-header` missing from `paginate`'s block list | `.rz-header` is in the leaf list and "is the first block placed on page 1, so the simulated page 1 has no more capacity than the real one" | `skeleton/example.html` has one `rz-header`; Quarto styles it at 104 | yes |
| Non-blocking — both pre-change `bullets-print` failure modes seen once | Appended: Switchyard fails marker-exists (bar in `@media screen` 256–264 → print `content` `none`, `width` `auto`, E2 reproduced); Nightgarden fails the ink clause (box present, mint `background-color`, no `print-color-adjust`); both FAIL lines recorded | Both reproduced today on the real sheets (table above) | yes |

### Fresh review — every AC, run by hand

- **Cargo fixture lock.** Byte equality plus four counts (`4` / `3` / `2` / `≥ 16`) — each a falsifiable assertion on the committed HTML; a fixture that is silently shortened fails the counts, a drifted HTML fails the byte lock.
- **`article-width`.** Three exact targets (682 / 673 / 720, ± 2 px) derived from `@page` sizes I re-checked (Quarto 53–61 Letter with 0.7in sides; Switchyard 335 A4 16mm; Nightgarden 404 Letter 0.5in); the pass line prints the measurement; a surviving UA margin fails it.
- **`fixture-trips-e1`.** `#rz-experience` height > 952 under Quarto and > 1009 under Switchyard, both heights printed; the fixture spec now says "exceed the highlight ranges until it does", so the AC cannot be satisfied by shrinking the résumé.
- **`page1-fill`.** ≥ 0.85 post-change on both, < 0.85 pre-change on both, ratio printed. With `.rz-header` now placed first and the oversize-atomic-block rule, the pre-change Quarto simulation is deterministic: header + summary on page 1, the atomic `#rz-experience` (> 952 px) alone on page 2 → page-1 fill well under 0.85. The oracle is stated as a geometry approximation of browser breaks, and `page-count` cross-checks against the real PDF.
- **`page-count`.** `U3_PRINT_PAGES` = 2/2/2 for Jordan asserted with `!==` in the existing S3/U3 probes (813, 864, 908 today compare `!==`), `LONG_PRINT_PAGES` ≤ 3 each — exact, and the existing probes turn red the day the constants drift.
- **`no-forced-break`.** Computed `breakInside` `auto` on every `.rz-section` for all three themes, `breakBefore` ≠ `page` on Switchyard's projects, a whole-sheet scan of `switchyard.css` (not `extractMediaBlocks`), and a pre-change Quarto FAIL reading `avoid`. I re-derived the pre-change values on all three: Quarto `avoid` (174–178), Switchyard `avoid` (397–398) and `page` (402–403), Nightgarden `auto` (no rule). So pre-change the probe fails on two themes and passes on one — the AC names Quarto as the recorded line, which is the theme that carries E1; fine.
- **`entry-intact`.** Same `paginate` output; header and dates on one simulated page; no atomic block taller than the page. Falsifiable, and the oversize rule means a too-tall `.rz-entry` produces a named FAIL rather than a silent wrap.
- **`bullets-print`.** Marker-exists via three alternatives, ink via contrast or (`width` > 0, `height` > 0, `background-color` ≥ 4.5:1, `print-color-adjust: exact`), all through `getComputedStyle(el, '::before')`. Run by hand on today's sheets: Quarto `"– "` → glyph, ink through inherited `color` → pass today (Quarto has no E2). Switchyard today → `none` / `auto` → FAIL marker-exists (E2). Nightgarden today → `""`, `6.39px`, mint `rgb(159, 243, 200)` (≈ 1.3:1 against white), `economy` → FAIL ink on two counts. Post-change Switchyard bar → `""`, > 0 px, `#b45309`-class ink (≈ 6.1:1), `exact` → pass. Every branch has a way to fail and the two pre-change failures are the two distinct E2 mechanisms.
- **`print-ink`.** Four selectors, ≥ 4.5:1 against `#fff` via `contrastRatio`; `.rz-entry-secondary` today keeps `var(--rz-iris)` in print (cycle 6 fact) — fails pre-change.
- **BAR-T1 / BAR-U3 / `just verify`.** Existing probes, named.

A stub that only removes the section avoid fails `bullets-print` and `print-ink`; a stub that adds a screen-only bar fails `bullets-print` in print emulation; a stub that sets `break-inside: auto` in `@media print` but leaves Quarto's top-level `avoid-page` wins nothing (the top-level rule still computes `avoid` unless overridden with equal or higher specificity later in the cascade — the probe reads computed style, so it catches an override that lost the cascade).

Non-blocking (no re-review needed):

- **Nightgarden pre-change ink wording.** The AC says the dot has "no `print-color-adjust`"; strictly, Nightgarden's print block sets `print-color-adjust: economy` (~432), so the computed value is `economy`, not absent. The ink clause requires `exact` computed, so `economy` fails it either way; the recorded FAIL line will read `economy`. Say "`print-color-adjust` computes `economy`, not `exact`" if the body is reopened for any other reason.
- **Fourteen, not ten, static `PASS` lines** exist in `staticProbes()`; only the ten S/U3-prefixed ones are the subject of ZG-20's sentence. Irrelevant to ZG-11's ACs; noted under ZG-20.

**BLESS ZG-11 — both cycle-6 blockers are closed with reads I executed on today's sheets: `getComputedStyle(el, '::before').width`/`.height` returns `8.79688px`/`2px` for a bar, `6.39062px` for Nightgarden's dot and `auto` for Switchyard's screen-only bar in print, and the pre-change Quarto rule computes `avoid` exactly as the anti-vacuity now states; every probe AC has a named pre-change FAIL or an exact numeric target, and no AC names a method that does not exist.**

## ZG-20 — Ship `npm run lint-theme` so a Designer knows pass or fail before opening a PR

### Cycle-6 blockers and notes, checked against the current body and the repo

| Cycle-6 blocker / note | Current body | Verified against | Resolved |
| --- | --- | --- | --- |
| **Blocker 1** — the `--static` negative forbade `PASS  S1`…`S5`/`U3` lines that `staticProbes()` itself prints | Negative names browser-only lines: no `Live sandbox has data-rz-schema` / `Jordan Hale is in .rz-name`, no `S2 <id>:` / `U3 <id>:` per-theme line, no line containing `printToPDF`, no `All RZ-3` summary, nothing after the last probe line; states the ten static `S1`…`U3` lines (238–315) are expected and are not `PASS  ZG-20/lint` lines; scope-in says success prints nothing after the last probe line | Every named browser-only string is emitted only inside browser functions or after `startServer()` (478, 483, 647–670, 813–914, 690, 1126); the ten static lines are at exactly 238, 244, 249, 259, 264, 270, 280, 290, 302, 315 | **yes** — a correct `--static` (return before 1114, print `N probe(s) failed.` or nothing) passes; one that starts the server or the browser prints at least `Live sandbox …` and fails |
| **Blocker 2** — selector rule made `from`/`to` in `@keyframes` errors; no keyframe unit case | Rule: "does not apply inside `@keyframes` bodies: `from`, `to` and `<percentage>` (`0%`, `50%`) are keyframe selectors, not selectors"; unit case `@keyframes x{from{opacity:0}50%{opacity:.5}to{opacity:1}}` → no `selector` error, `motion` warning also present, case asserts only the named codes | Nightgarden 69/74/81/85/91/95 are the only `from`/`to` lines; no percentage selectors in first-party sheets, so the unit case is the only thing that pins them; ZG-12 states the same exclusion | **yes** |
| Non-blocking — concurrent `node --test` and the `themes/` write | "`node --test` runs test files concurrently, and the meta-test is the only test that writes into `themes/` (it removes `zz-bad.css` in `finally`) — a future test that lists `themes/` must respect that" | ZG-19's test reads `_blank.css` by name; no test lists `themes/` | yes |
| Non-blocking — `CONTRIBUTING.md` ownership | unchanged (ZG-18's; PO's AXEL ordering) | — | n/a |

### Fresh review — every example against its rule, by hand

**Selector rule** ("every complex selector, split on combinators, must contain at least one compound built on `html`, `body`, `.rz-*`, or `[data-rz-*]`; type/`*`/pseudo allowed anywhere alongside such a compound; any non-`rz-` class or `#id` anywhere is an error; a selector whose compounds are only `*`/type/pseudo is an error; not applied inside `@keyframes`"):

| Case | Compounds | Rule outcome | AC says | Agree |
| --- | --- | --- | --- | --- |
| `.rz-resume a` | `.rz-resume`, `a` | rz compound present | no error | yes |
| `.rz-summary p` | `.rz-summary`, `p` | same | no error | yes |
| `.rz-resume a:focus-visible` | `.rz-resume`, `a:focus-visible` | same | no error | yes |
| `.rz-entry-header > *` | `.rz-entry-header`, `*` | same | no error | yes |
| `html *` / `html *::before` | `html`, `*` / `*::before` | html compound | no error | yes |
| `html` / `body` | one compound | allowed base | no error | yes |
| `@page :first{}` | at-rule prelude, not a style rule | not a selector | no error | yes (the body says so explicitly) |
| `.rz-name::selection` | `.rz-name::selection` | rz compound | no error | yes |
| `.rz-resume ::marker` | `.rz-resume`, `::marker` | rz compound | no error | yes |
| `a` / `li` / `*` / `*::before` | only type/`*`/pseudo | error | `selector` | yes |
| `.rz-resume .btn` | `.btn` is a non-`rz-` class | error | `selector` | yes |
| `#root` | `#id` | error | `selector` | yes |
| `.theme-switcher` | non-`rz-` class | error | `selector` | yes |
| `.rz-name, .btn` | per comma: second has `.btn` | error | `selector` | yes |
| `*, .rz-name` | per comma: first is `*` only | error | `selector` | yes |
| `@keyframes x{from{…}50%{…}to{…}}` | inside `@keyframes` — rule not applied | no `selector` error; `@keyframes` without reduced-motion → `motion` | no `selector`, `motion` present | yes |

`@property --rz-pulse` (Nightgarden 62) is an at-rule prelude like `@page :first` and `@property` is in the allowed list; AC 1 (Nightgarden exits 0) pins it without a separate unit case — acceptable, since a lint that treats `--rz-pulse` as a selector fails AC 1 on a first-party sheet.

**Content rule:** all thirteen examples agree with the two regexes under execution (table above); `content:"Page " counter(page)` has a letter-run *and* `counter(` → `content-counter` warning, no error; `content:counter(rz-sec)` and `content:attr(data-rz-type)` have no letter-run → no error. Confirmed, including the CJK-script clause — the `notes` question is answered and may drain.

**Other rules:** each of the twelve "other" cases maps to exactly one code by its stated trigger (`<script`, `@import`, missing / `mobile` `rz-target`, `#000` and `rgb(10,10,10)` luminance < 0.5 without `color-scheme: light`, `var(--ink)` unresolved → warning, `@keyframes` without reduced-motion → `motion`, missing `Author:` → `header`, relative / root-relative `url(` → nothing, `http://` absolute → `url-origin`). No case is ambiguous.

**CLI and fixture:** `bad-theme.css` five lines, three errors at 3/4/5, output lines and `3 errors` summary named; warnings-only file exits 0 with `0 errors, 1 warning`. Exit contract has both branches.

**Meta-test:** spawns `probes.mjs --static` with `themes/zz-bad.css` present → exit 1 and three named `FAIL  ZG-20/lint zz-bad.css:{3,4,5}` lines; after removal → exit 0, zero `FAIL  ZG-20/lint`, exactly three `PASS  ZG-20/lint`. The count of three is undisturbed by the ten static `S…`/`U3` lines and by the four other static `PASS` lines (`Generated theme list …`, `Generated Themes.elm lists …`, `Sandbox document …`, `Sandbox does not link …`) — none begins `PASS  ZG-20/lint`. A stub that hard-codes three PASS lines fails the `zz-bad.css` half; a stub that lints by file name fails it too (the fixture is copied under a new name).

**`--static` AC:** exit 0 on a clean tree, three lint lines, none of the named browser-only strings, nothing after the last probe line, < 10 s, flag-less run unchanged. Falsifiable in both directions.

**Wiring:** `grep -n "node --test scripts" frontend/package.json` inside `test`; `lint-theme` in `package.json` and `CONTRIBUTING.md` (ZG-18's file; the grep hits whichever item writes it — testability unaffected).

Non-blocking:

- The `--static` AC's "ten `PASS  S1`…`S5`/`U3` lines" is exact for S/U3-prefixed lines; four more non-prefixed static `PASS` lines exist (200, 213, 219, 224). A tester counting *all* `PASS` lines on `--static` should expect 14 + 3 today. Fold in only if the body is reopened.
- Dependency order for tests is explicit (meta-test after `npm run build`, inside `npm run probe`), and ZG-19 → ZG-20 orders the `header` warning's source. No cycle.

**BLESS ZG-20 — both cycle-6 blockers are closed against the source: every browser-only string the `--static` negative names is emitted only after `startServer()` or inside a browser probe (verified by line), the ten static `S…`/`U3` lines are correctly declared expected, and the selector rule now excludes `@keyframes` bodies with a unit case that pins `50%` as well as `from`/`to`; all thirty-plus selector, content and other examples agree with their rules by hand, and the CJK `content` clause is confirmed by execution — the `notes` question drains.**

---

## Summary

| id | PO cycle 8 | QA verdict | one-line reason |
| --- | --- | --- | --- |
| ZG-11 | BLESS | **BLESS** | `getComputedStyle(el, '::before').width`/`.height` executed on today's three sheets (`auto` / `6.39px` / glyph) and on a bar (`8.79688px`/`2px`); pre-change Quarto computes `avoid` as the AC now states; every probe has a named pre-change FAIL or exact target |
| ZG-20 | BLESS | **BLESS** | `--static` negative names only strings emitted in browser code or after `startServer()`; `@keyframes` bodies excluded with a `from`/`50%`/`to` case; every AC example agrees with its rule by hand; CJK clause confirmed, `notes` may drain |

2 BLESS, 0 REJECT. Both proceed to the Visionary CTO.

## Set-level notes (for the conductor and AXEL; none blocks)

- **Execute each new oracle once before submitting** remains the discipline that closed cycles 5–8; the Generator did so this cycle and every claim held under re-execution.
- **Nightgarden's print block sets `print-color-adjust: economy`** (~432). ZG-11's Nightgarden marker must set `exact` on `.rz-bullet::before` with equal or greater specificity later in the cascade, or the ink clause fails on the computed value.
- **`--static` must return before `startServer()`** (1114) and may print `N probe(s) failed.` on failure; on success nothing after the last probe line. The implementer should not move the `S…`/`U3` static checks out of `staticProbes()` — the meta-test and the ZG-20 AC assume they stay static.
- **ZG-20 `notes` drains on this BLESS.** The conductor should empty it before the CTO's final gate.
