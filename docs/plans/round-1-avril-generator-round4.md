# AVRIL round 1 — Generator revise pass (cycle 4, after QA Architect cycle 3)

**Generator:** `planning-architect-agent` · **Date:** 2026-08-23 · **Board:** Pinto `ZG` (labels `avril`, `round-1`)
**Inputs read in full:** `docs/plans/round-1-avril-qa-round3.md` (the six REJECT sections and the set-level notes), `docs/plans/round-1-avril-generator-round3.md` (conventions, fixture owners), `docs/plans/round-1-avril-intent.md`, `pinto show ZG-11 ZG-12 ZG-13 ZG-19 ZG-20 ZG-21 --plain` (rejected), `pinto show ZG-4 ZG-14 ZG-22 --plain` (QA-blessed references), `pinto list --json`, plus `themes/*.css`, `frontend/scripts/probes.mjs`, `frontend/scripts/serve.mjs`, `frontend/scripts/copy-dist.mjs`, `frontend/scripts/generate.mjs`, `frontend/generated/sandbox.html`, `frontend/css/chrome.css`, `renderer/src/emit.rs`.

Only the six QA-cited REJECTs were applied, plus three QA non-blocking notes that were one-line and strictly improved falsifiability (ZG-13 `@font-face` counts and `FontFace.status === 'error'`; ZG-11 `page1-fill` numerator; ZG-20 `url-origin` on relative URLs; ZG-21 CORS statement). ZG-6, ZG-10, ZG-17 (with QA in cycle 4) and the QA-blessed ids (ZG-1, 2, 3, 4, 5, 7, 8, 9, 14, 15, 16, 18, 22) are untouched. ZG-22 stays unchanged because ZG-21's pinned error body is the shape ZG-22's `api-errors` stubs already assume. Nothing is BLESSed by this document.

## Facts verified before writing AC

| Fact | How | Used by |
| --- | --- | --- |
| `@page`: Quarto Letter `0.55in 0.7in 0.6in` (`:first` top `0.48in`); Switchyard A4 `14mm 16mm 16mm`; Nightgarden Letter `0.36in 0.5in 0.28in`. Printable widths 682 / 673 / 720 px, heights 952 / 1009 / 995 px. | `grep -A3 @page themes/*.css` | ZG-11 `printableWidthPx` / `printableHeightPx` |
| In `@media print` every theme sets `.rz-resume { max-width: none; margin: 0; padding: 0 }` (Quarto also `width: auto`), and all three set `body { margin: 0 }` at top level — so a top-level `sandbox.html` at a viewport of `printableWidthPx` lays the article out at exactly that width (headless Chromium has no classic scrollbar). | read quarto 335–345, switchyard 340–350, nightgarden 404–426, 74/64/112 | ZG-11 `article-width` guard |
| `sandbox.html` is generated into `frontend/generated/` by `generate.mjs` from `skeleton/example.html`, copied to `dist/sandbox.html` by `copy-dist.mjs`, links `themes/nightgarden.css` via `#theme-stylesheet`; `pdfPagesForTheme` already opens it top-level with `page.goto(origin + "/sandbox.html")` + `waitThemeReady(page, href)`. | read | ZG-11 `openResumePage` (seeded from the existing top-level load) |
| `.garden-frame { width: 100%; height: 100%; min-height: 100vh }` — a viewport-height internal scroller. | `chrome.css` 368–383 | ZG-11 scope_out, ZG-12 scope |
| Nightgarden `rz-rise`: `@keyframes rz-rise { from { opacity: 0; transform: translateY(1.15rem) } }` top level (line 68); `.rz-section { animation: rz-rise 0.7s … both }` top level (line 225); `:nth-of-type` delays top level (231–235); `@supports (animation-timeline: view())` adds only `animation-timeline: view(); animation-range: entry 0% entry 32%` (364); `@media print, (prefers-reduced-motion: reduce)` guard (390). No `.rz-section { opacity: 0 }` anywhere. | read | ZG-12 `rise-css-structure`, rest-state decision |
| Bullet markers: Quarto `::before { content: "– " }`; Switchyard `::before { content: ""; width: 0.55rem; height: 2px; background: #b45309 }`; Nightgarden `::before { content: ""; 0.4rem dot; background: var(--rz-mint) }` with no print override and no `print-color-adjust`. | read | ZG-11 Nightgarden marker in scope |
| Universal selector in first-party themes: `html *`, `html *::before`, `html *::after` (all three), `.rz-entry-header > *` (Nightgarden 274, Switchyard 121). No `#id`, no non-`rz-` class. | `grep -n '\*' themes/*.css` | ZG-20 `*` rule + unit cases |
| `probes.mjs`: `fail()` pushes to `failures` and prints `FAIL  …` — it never exits early; `staticProbes()` fails `Generated Themes.elm is missing <id>` for any uncatalogued `themes/*.css`; `pass`/`fail` use two spaces. | read 28–36, 174–210 | ZG-20 meta-test |
| `@font-face` counts: quarto 4, switchyard 4, nightgarden 5, `_blank` 0. `serve.mjs` maps `.woff2` → `font/woff2` and `.svg` → `image/svg+xml`. | `grep -c`, read | ZG-13 AC 1, ZG-19 `curl` content-type |
| `emit.rs` writes `basics.image` verbatim as `src` (line ~120) with `alt="Portrait of {name}"`. ZG-14 copies `skeleton/samples/*.{html,json,svg}` to `dist/skeleton/samples/`. | read | ZG-19 photo path (`portrait.svg`, sibling) |
| ZG-22 `api-errors` stubs `422 {"error":"name"}` and expects the chrome text to contain `name`; it assumes a JSON body with a string `error` field. | `pinto show ZG-22` | ZG-21 error-body shape (`error` + `message`) |
| ZG-4 `wasm-load-failure` asserts `pageerror` only and says nothing about console errors — the pattern for route-abort probes. | `pinto show ZG-4` | ZG-13 `fallback` |
| Graph before this pass: ZG-14 → ZG-7; ZG-19 → {ZG-16, ZG-17}; ZG-11, ZG-12, ZG-13 have no deps; nothing upstream of ZG-14 or ZG-11 depends on ZG-19/ZG-20 or ZG-12. | `pinto list --json` | edge additions cannot cycle |

---

## Shared-helper / fixture ownership additions

| Helper / fixture | Content (in the owner's body) | Owner | Consumers (and how they depend) |
| --- | --- | --- | --- |
| `openResumePage(browser, { theme, width, height = 800, fixtureHtml })` in `probes.mjs` | opens `/sandbox.html` **top-level** in a fresh page at the given viewport, applies the theme via the existing `waitThemeReady`, optionally swaps `article.rz-resume` with the fixture's article; returns the page | **ZG-11** (earliest in dependency order of the two that need it; both are dep-free, ZG-11 ranks first) | **ZG-12** (new dep ZG-12 → ZG-11) for `painted-without-support`, `painted-with-support`, `reduced-motion`. ZG-13 does not need it (its `fallback` is a screen-width check) and stays dep-free |
| `printableWidthPx(themeId)` = 682 / 673 / 720 | next to `printableHeightPx` | **ZG-11** | ZG-11 geometry probes only |
| Error body `{"error": <code>, "message": <sentence>}`, `Content-Type: application/json`, codes `too-large` `invalid-json` `unknown-theme` `not-a-resume` `missing-name` `not-found` | in scope; asserted by `error_body_shape` | **ZG-21** | ZG-22 (existing dep) — its `{"error":"name"}` stubs match the shape; no edit |
| Console-error convention for route-aborted probes | forbid `pageerror` and console errors *not* caused by the aborted URLs | stated in **ZG-13** (first consumer); ZG-4 already follows it | future route-abort probes |
| `skeleton/samples/portrait.svg` | neutral vector, explicit `width="96" height="96"` + `viewBox`, sibling of `contract.html` | **ZG-19** (unchanged owner; path fixed) | served by ZG-14 (new dep ZG-19 → ZG-14) |

Unchanged owners from cycle 3: `ada.json` (ZG-4), `trailing-comma.json` / `not-a-resume.pdf` (ZG-5), `long-resume.*` + print constants (ZG-11), `bad-theme.css` (ZG-20), `wild.rs` (ZG-2), `BAR-L1` (ZG-13), `local-theme.css` (ZG-15).

---

## Per-item: QA blocker → exact AC change

### ZG-11
| QA blocker | Change |
| --- | --- |
| Geometry oracle has no layout width; inside the Garden iframe the article lays out at ~980 px, not 682/673/720 px | Scope adds `printableWidthPx(themeId)` (682 / 673 / 720 px, derivations stated) beside `printableHeightPx`; adds the shared helper `openResumePage` (owner: this PBI) that loads `/sandbox.html` top-level at a stated viewport; the geometry probes (`fixture-trips-e1`, `page1-fill`, `entry-intact`) run on `openResumePage({ theme, width: printableWidthPx(theme), fixtureHtml })` in print emulation. New AC `ZG-11/article-width`: `article.rz-resume.getBoundingClientRect().width` within 2 px of 682 / 673 / 720 — the width assumption is itself an assertion, and every geometry probe stops with `FAIL  ZG-11/<slug> article width …` if it does not hold. The former "replace the article in `#garden-frame`'s `contentDocument`" line is gone; scope_out forbids measuring inside the iframe |
| `bullets-print` demands an inked `background-color` + `print-color-adjust: exact` on Nightgarden's mint dot, which no scoped change touches | Scope-in gains "Nightgarden `@media print .rz-bullet::before` gets a printed marker (ink bar/dot ≥ 4.5:1 with `print-color-adjust: exact`, or a glyph)"; Covers adds E2 for Nightgarden; `bullets-print` now holds all three themes to the same assertion honestly (no "regression guard" hedge) |
| Non-blocking: `page1-fill` numerator | Fill = (bottom of last page-1 block − top of first block) ÷ printable height, stated in the `paginate` spec |
| Set-level anti-vacuity | `page1-fill` additionally runs against the pre-change sheets (`git show <base>:themes/<theme>.css` injected) and must report < 0.85 for Quarto and Switchyard; that FAIL line is recorded in evidence |
| Fixture sizing at paper width ("marginal at ~110 chars/line") | Fixture spec says "sized so that `fixture-trips-e1` holds at paper width — stay inside the stated ranges but lean long; the AC decides, not the counts"; `fixture-trips-e1` prints both measured heights |

### ZG-12
| QA blocker | Change |
| --- | --- |
| `painted-with-support` measures a region a page-level screenshot cannot contain (iframe is a viewport-height internal scroller) | All `rz-rise` probes open the résumé document as the top-level page via ZG-11's `openResumePage({ theme: 'nightgarden', width: 1280, height: 800 })`; scope states why; **dep added ZG-12 → ZG-11** |
| Scope and AC disagree on the in-support outcome (Chromium keeps below-fold sections at `opacity: 0` via `view()` + fill `both`) | Scope now states today's mechanism verbatim (lines 68 / 225 / 364) and the decided rest state: the `.rz-section` animation (`rz-rise`, timing, `animation-timeline: view()`, `animation-range: entry 0% entry 32%`) is declared only inside `@supports (animation-timeline: view())` with `animation-fill-mode: forwards` (never `both`/`backwards`), so before a section enters the scrollport it sits at its natural style (`opacity: 1`) and the fade plays only while it enters; `:nth-of-type` delays move inside or go; outside the block `.rz-section` has no `animation`. Scope_out records that removing the rise is rejected (locked decision 4) |
| Anti-vacuity for the pixel probe | `painted-with-support` first asserts `#rz-volunteer` / `#rz-projects` are below the fold (`top > 800`, mis-set-up guard) and compute `opacity` `1` without scrolling, then the pixel count (≥ 200 px differing > 32 in a channel inside the `#rz-projects` box, document coordinates); the same probe run with the pre-change sheet must FAIL with computed `opacity` `0` and that FAIL line is evidence — a deterministic pre-change failure independent of screenshot semantics |
| `rise-css-structure` looks for `.rz-section { opacity: 0 }` declarations that do not exist (vacuous) | Redefined on the real mechanism: (a) every `animation`/`animation-name` containing `rz-rise` on `.rz-section` lies inside the `@supports` block (none top-level / plain `@media`); (b) inside it `.rz-section` declares `animation-timeline: view()` and fill `forwards` — `both`/`backwards` absent; (c) no `opacity` < 1 / `translateY(` on `.rz-section`/`.rz-rise` outside `@keyframes rz-rise`. The AC states it FAILs on the pre-change sheet on (a) (line 225) and requires that line in evidence |
| `innerText` clause cannot fail | Dropped; the computed-`opacity` assertion is the Cmd-A oracle |
| `painted-without-support` | Kept (QA: sound), moved to the top-level page; states that the pre-change sheet fails it (`getAnimations()` still reports the finished fill-`both` animation) |

### ZG-13
| QA blocker | Change |
| --- | --- |
| `fallback` forbids any console error while its own route-abort makes Chromium log `Failed to load resource: net::ERR_FAILED` | Scope adds the convention (same stance as ZG-4's `pageerror`-only `wasm-load-failure`); `ZG-13/fallback` now: `page.route(…, route => route.abort())` on `**/themes/fonts/**`, cycle the three themes, no `pageerror`, and no console `error` other than resource-load failures whose `location().url` (or text) contains `/themes/fonts/` — those are counted and printed on the pass line, not failed on; the rest of the probe (`.rz-name` height > 0, S2 green, no horizontal overflow) unchanged |
| Non-blocking: `@font-face` count "unchanged from before" | Pinned: quarto 4, switchyard 4, nightgarden 5 |
| Non-blocking: `fonts-load` masking by `local()` | Added: no `FontFace` in the three families has `status === 'error'` |

### ZG-19
| QA blocker | Change |
| --- | --- |
| `basics.image = "samples/portrait.svg"` resolves to `/skeleton/samples/samples/portrait.svg` (404) and no AC checks the photo loads | `basics.image` = `portrait.svg` (sibling of `contract.html` inside `skeleton/samples/`; resolves from disk and at `/skeleton/samples/portrait.svg`); the SVG has explicit `width="96" height="96"` + `viewBox` so `naturalWidth` is non-zero. New ACs: `curl` → `200 image/svg+xml` for `/skeleton/samples/portrait.svg` and `200` for `contract.html`; probe `ZG-19/photo-loads`: `img.rz-photo-img` `complete && naturalWidth > 0`, in-page `fetch(new URL(img.src, location.href))` → 200, `.rz-score` text `GPA 3.9`, zero console errors / `pageerror`s; the lock AC also asserts `src="portrait.svg"`. Scope_out rejects `samples/…` and absolute paths with the reason |
| `blank-readable` and the served-fixture claim depend on ZG-14 without an edge | **Dep added ZG-19 → ZG-14** (rationale in the Dependencies line); scope states ZG-14 serves `/skeleton/example.html` and `skeleton/samples/*`. "Served" wording kept (disk-based alternative not taken — the README points designers at the served file) |

### ZG-20
| QA blocker | Change |
| --- | --- |
| Selector rule silent on `*`; Nightgarden `.rz-entry-header > *` makes "first-party exit 0" a guess | Rule pins it: `*` is allowed like a type selector in a complex selector that has an `html`/`body`/`.rz-*`/`[data-rz-*]` compound; a selector whose compounds are only `*`/type/pseudo is an error. Unit cases added: `.rz-entry-header > *{}`, `html *{}`, `html *::before{}` → no error; `*{}`, `*::before{}`, `*, .rz-name{}` → `selector`. AC 1 says explicitly that Nightgarden's and every theme's `*` selectors pass by rule, not leniency |
| `probes.mjs` meta-test passes today with no lint wired (`staticProbes` already exits 1 for an uncatalogued file) | Scope: the lint runs as the **first** step of `staticProbes()`, prints `PASS  ZG-20/lint <file> 0 errors` per clean file and `FAIL  ZG-20/lint <file>:<line> error <code>` per error (`fail()` records and continues — verified). Meta-test AC now asserts the three `FAIL  ZG-20/lint zz-bad.css:{3,4,5} error {selector,content,print-ink}` lines are present (other FAIL lines such as the catalog one are expected and ignored — "the exit code alone proves nothing"), and after removal no `FAIL  ZG-20/lint` line and exactly three `PASS  ZG-20/lint` lines |
| Non-blocking: `url-origin` on relative URLs | Warning is for non-https **absolute** origins only; unit cases `url("fonts/a.woff2")` and `url(/themes/fonts/a.woff2)` → no warning, `url(http://cdn.example/a.woff2)` → `url-origin` |

### ZG-21
| QA blocker | Change |
| --- | --- |
| Valid JSON that is not a résumé shape has no status (500 vs 422 is a guess) | Validation is an ordered contract in scope: 413 `too-large` → 400 `invalid-json` → 422 `unknown-theme` → pure `domain` shape check mirroring ZG-5's `not-a-resume` (`resume` not an object, `basics` not an object, any of the 11 known section keys present but not an array → 422 naming the key) → 422 `missing-name` → `render_json` `Err` → 422 `not-a-resume` (never 500, never a panic). A row is written only after `render_json` succeeded on the bytes being stored, so `GET /r/{id}` cannot 500 on a stored row. New test `wrong_shape_is_422_never_500` (`work: "nope"` → 422 naming `work`; `basics: "E"` → 422 naming `basics`; `work[0].highlights: "x"` → 422 via the renderer; ZG-3's `score: 3.7` → 201; zero inserts for the 422s); `put_validates_like_post` gains the `work: "nope"` case; scope_out declines field-level schema validation / `serde_path_to_error` |
| Error body shape unowned while ZG-22 stubs `{"error":"name"}` | Pinned in scope (owner: ZG-21): every non-2xx under `/api/` is `application/json` `{"error": "<code>", "message": "<plain sentence>"}` with the six codes; `message` is the humane sentence (contains `name` / the key / `line N column M`) and never a serde token (ZG-5's ban list); `/r/{id}` 404/410 stay HTML. New test `error_body_shape` (content type, exactly the two keys, code in list, non-empty message, no banned tokens) over the 400/413/422 cases and `/api/resumes/abc`. The shape has the string `error` field ZG-22's stubs assume, so **ZG-22 is unchanged**; README AC documents the shape |
| Non-blocking: `tower-http` CORS in scope with no AC | `tower-http` is `fs` only, no CORS layer (same-origin; keeps ZG-22's "unavailable on Netlify" story true); scope_out names cross-origin access as Phase 5; new test `no_cors` (no `Access-Control-Allow-Origin` on a request with `Origin`; no `Access-Control-Allow-*` on a preflight) |

---

## Dependency changes

- Added `ZG-12 → ZG-11` (owner of `openResumePage`; both edit `themes/nightgarden.css`, print block first).
- Added `ZG-19 → ZG-14` (serves `/skeleton/example.html` and `skeleton/samples/*`). Designer chain is now `ZG-7 → ZG-14 → {ZG-18, ZG-19}` joined with `ZG-16 → ZG-17 → {ZG-18, ZG-19} → ZG-20`.
- No edge removed. Graph verified acyclic with a DFS over `pinto list --json`. Ready-at-start set: ZG-1, ZG-7, ZG-8, ZG-9, ZG-11, ZG-13, ZG-15, ZG-16 (ZG-12 leaves it; nothing else moves).
- `pinto list --json` timestamps confirm only the six ids below were written; ZG-14's record is untouched (the new edge lives on ZG-19).

## Changed ids

Every PBI whose body or deps changed in this pass (prior blessings invalidated; full PO → QA → CTO chain required):

- **ZG-11** — body (printable widths, `openResumePage` owner, `article-width` guard, geometry probes at paper width on a top-level page, Nightgarden print marker in scope + Covers E2, `page1-fill` numerator + pre-change anti-vacuity, fixture sizing note)
- **ZG-12** — body (top-level page oracles, `animation-fill-mode: forwards` rest state inside `@supports`, `rise-css-structure` on the real mechanism with pre-change FAIL, `painted-with-support` computed-opacity + pixel with pre-change FAIL, `innerText` dropped) and deps (+ZG-11)
- **ZG-13** — body (`fallback` ignores only aborted `/themes/fonts/` load errors, `pageerror` forbidden; `@font-face` counts pinned 4/4/5; no `FontFace` `status === 'error'`)
- **ZG-19** — body (`basics.image` = `portrait.svg` sibling, `photo-loads` probe, SVG `curl`, `src="portrait.svg"` in the lock, scope_out on rejected paths) and deps (+ZG-14)
- **ZG-20** — body (`*` allowed inside an anchored selector, six new selector unit cases, lint first in `staticProbes()` with named `PASS`/`FAIL  ZG-20/lint` lines, meta-test asserts the lint's own lines, `url-origin` relative-URL cases)
- **ZG-21** — body (ordered validation contract with the pure shape check and 422-never-500 rule, pinned `{error, message}` body + `error_body_shape`, `wrong_shape_is_422_never_500`, no CORS + `no_cors`, README documents the shape)

Untouched: ZG-1, ZG-2, ZG-3, ZG-4, ZG-5, ZG-7, ZG-8, ZG-9, ZG-14, ZG-15, ZG-16, ZG-18, ZG-22 (QA-blessed; ZG-11 and ZG-14 gain dependents only), ZG-6, ZG-10, ZG-17 (with QA in cycle 4).
