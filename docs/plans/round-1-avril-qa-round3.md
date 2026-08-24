# AVRIL round 1 — QA Architect review (cycle 3)

**Role:** `qa-architect-agent` (second adversary) · **Date:** 2026-08-23 · **Cycle:** 3 (fresh review of the Generator's QA-driven revise)
**Scope:** the 13 ids revised in `round-1-avril-generator-round3.md` and re-blessed by the PO in cycle 3 — ZG-1, ZG-3, ZG-4, ZG-5, ZG-7, ZG-8, ZG-11, ZG-12, ZG-13, ZG-19, ZG-20, ZG-21, ZG-22. (ZG-6, ZG-10, ZG-17 are with the Generator concurrently; not reviewed. ZG-2, ZG-9, ZG-14, ZG-15, ZG-16, ZG-18 carry their cycle-1 BLESS.)
**Inputs read in full:** `docs/plans/round-1-avril-qa-round1.md` (my cycle-1 blockers and set-level conventions), `docs/plans/round-1-avril-generator-round3.md` (claimed changes, fixture-ownership table, dependency delta), `docs/plans/round-1-avril-po-round3.md`, `docs/plans/round-1-avril-intent.md`, the 13 current bodies (`pinto show … --plain`), `pinto list --json`, and the repo files each AC leans on (listed below).

Mandate: *BLESS only PBIs whose acceptance criteria are complete, falsifiable, and hostile to happy-path theater; otherwise REJECT with the missing cases.*

Prior blessings do not carry forward. For each item I checked (1) that every cycle-1 blocker was actually resolved, not paraphrased; (2) that every AC is falsifiable without reading source; (3) that each named fixture is fully specified by its owner and every consumer depends on the owner; (4) that negative/edge/regression cases are present; (5) that a stub fails at least one AC; (6) that no AC of the PBI's own may print `SKIPPED`; (7) that no oracle is unsatisfiable in the toolchain we have. I do not author, do not touch the board, and do not reopen product scope.

## Facts I verified before judging (they change verdicts)

| Fact | How | Affects |
| --- | --- | --- |
| `renderer/tests/` holds only `acceptance.rs`; `#[test]` count is 9 + 10 unit = 19. `renderer/examples/` and `frontend/fixtures/` do not exist. | `ls`, `grep -c '#[test]'` | ZG-1 (≥ 19), every fixture owner |
| `probes.mjs`: `pass()`/`fail()` print `PASS  ` / `FAIL  ` (two spaces); `countPdfPages` regexes `/Type /Page`; `U3_PRINT_PAGES = {nightgarden: 2, quarto: 3, switchyard: 3}` asserted with `!==`; the View toggle is `getByRole('button', {name: 'Print preview'})`; no `BAR-L1` probe; `staticProbes()` fails `Generated Themes.elm is missing <id>` for any `themes/*.css` not in the catalog. | read | ZG-7, ZG-11, ZG-13, ZG-20 meta-test |
| Only Chromium (+ headless shell) is installed for Playwright; `pdftoppm`/`pdftocairo` exist on this machine but nothing in the repo uses them; no PNG decoder in `frontend/package.json` (deps: `elm`, `playwright`). | `ls ~/Library/Caches/ms-playwright`, `which`, read | ZG-11, ZG-12 |
| `@page` margins: Quarto Letter `0.55in 0.7in 0.6in`, `:first` top `0.48in`; Switchyard A4 `14mm 16mm 16mm`; Nightgarden Letter `0.36in 0.5in 0.28in`. ZG-11's 952 / 1009 / 995 px heights are correct. **Printable widths** (not stated anywhere in ZG-11): Quarto 8.5in − 1.4in = 7.1in = 682 px; Switchyard 210mm − 32mm = 178mm = 673 px; Nightgarden 8.5in − 1.0in = 7.5in = 720 px. | `grep -A3 @page` | ZG-11 geometry oracle |
| In `@media print` every theme sets `.rz-resume { width: auto; max-width: none; margin: 0 }` (Quarto 340, Switchyard 346, Nightgarden 422). In print emulation inside the Garden iframe the article therefore lays out at the iframe's width, not the paper's. | read | ZG-11 `fixture-trips-e1`, `page1-fill` |
| Bullet markers today: Quarto `::before { content: "– " }` (glyph, inherits text colour); Switchyard `::before { content: ""; width: 0.55rem; height: 2px }` (bar); **Nightgarden `::before { content: ""; width/height 0.4rem; border-radius: 50%; background: var(--rz-mint) }` with no print override and no `print-color-adjust`** (its print block only sets `.rz-bullet { margin }`). | read lines 256–275, 250–262/437–441, 303–320/520–532 | ZG-11 `bullets-print` regression guard |
| Nightgarden `rz-rise` mechanism: `@keyframes rz-rise { from { opacity: 0; transform: translateY(1.15rem) } }` at **top level** (line 68); `.rz-section { animation: rz-rise 0.7s … both }` at **top level** (line 225); the `@supports (animation-timeline: view())` block (line 364) only adds `animation-timeline: view(); animation-range: entry 0% entry 32%`. No `.rz-section { opacity: 0 }` declaration exists anywhere. Reduced-motion/print guard at line 390. | read | ZG-12 `rise-css-structure`, `painted-*` |
| `.garden-frame { height: 100%; min-height: 100vh }` inside `.app-shell { min-height: 100vh }`; `ports.js` has no `ResizeObserver`/`scrollHeight` sizing. The iframe is a viewport-height box that scrolls **internally**; below-fold résumé content is outside the iframe's painted box. | read `chrome.css` 368–383, grep `ports.js` | ZG-12 `painted-with-support` |
| Themes use `@font-face` with `local(…)` then `url("https://cdn.jsdelivr.net/fontsource/…woff2")`: Quarto 4, Switchyard 4, Nightgarden 5 blocks. `serve.mjs` maps `.woff2` → `font/woff2`. | grep | ZG-13 |
| Chromium reports every aborted or failed subresource load as a console message of type `error` (`Failed to load resource: net::ERR_FAILED`); Playwright surfaces it on `page.on('console')`. | Playwright/Chromium behaviour | ZG-13 `fallback` |
| First-party selectors contain no `#id`, no non-`rz-` class, no attribute selector; they do contain `.rz-entry-header > *` (Nightgarden 274) and `.rz-tag:not(:last-child)::after`. `content:` values are `""`, `" "`, `", "`, `": "`, `" · "`, `"– "`. Print backgrounds are `#f3ead8` / `#ffffff` / `transparent`. | grep | ZG-20 selector rule vs "first-party exit 0" |
| `CLASS-CONTRACT.md` §5.2 line 48 lists exactly the 11 profile modifiers and line 50 exactly the 5 contact types ZG-19 expands; §6 (`## 6.` … `## 7.`) has only `rz-contact--{type}` / `rz-link--{type}` as brace tokens. `themes/README.md` today contains neither `never only in` nor `résumé words` and does contain `(§2)`. `docs/planning/resumezen-avril-blessed-backlog.md` exists. | awk/grep | ZG-19 |
| `emit.rs` line 120 writes `basics.image` verbatim as `src`. ZG-14 copies `skeleton/samples/*.{html,json,svg}` to `dist/skeleton/samples/`. So `contract.html` served at `/skeleton/samples/contract.html` with `basics.image = "samples/portrait.svg"` requests `/skeleton/samples/samples/portrait.svg`. | read | ZG-19 proofing fixture |
| Dependency graph: ZG-19 → {ZG-16, ZG-17}; ZG-16 → none; ZG-17 → ZG-16; ZG-14 → ZG-7. **ZG-19 does not reach ZG-14**, which is the item that serves `/skeleton/example.html` and `skeleton/samples/*`. | `pinto show` | ZG-19 `blank-readable` |
| ZG-2's AC names `cargo test --test wild`; ZG-3 now depends on ZG-2. `ThemeId.fromQuery` exists. `ports.js` preserves `url.hash` (line 205). `render_json(&str) -> Result<String, serde_json::Error>`. `Main.elm` today has a filter chip `"Print"`, the `Print preview` toggle and a `.preview-controls__print` button labelled `Print`. | grep | ZG-3, ZG-7, ZG-8, ZG-22 |

---

## ZG-1 — Make the renderer pass clippy pedantic so `just verify` is green

Cycle-1 blockers: AC 5 now excludes `progress.md`/`features.json` by pathspec (`git diff --name-only -- . ':!progress.md' ':!features.json'`) — exact command, resolved. AC 4 is now "`0 failed` in every binary, every `cargo test -- --list` name preserved, total ≥ 19" — resolved, and 19 is the verified count. The no-`allow(clippy` grep, the exit-0 clippy command and `git diff --stat skeleton/` empty are all exit-code or empty-output oracles. A stub that adds `#[allow]` fails AC 3; a stub that deletes a test fails the `--list` preservation.

**BLESS ZG-1 — every AC is a command with an exit code or an empty-output check, the DoD contradiction is gone, and the test-count oracle survives ZG-2/3 landing first.**

## ZG-3 — Render wild JSON Resume files: numeric score, url-only entries, CRLF, bad URLs

Cycle-1 blockers, each checked against the body: the bad-URL/no-username profile now has an outcome (no `<li class="rz-link`, no `<nav class="rz-links"` at all) — resolved and stronger than asked; the empty link/contact regex `<li class="rz-(link|contact)[^>]*>\s*(<span class="rz-(link|contact)-label">[^<]*</span>\s*)?</li>` is applied over every fixture in `renderer/tests/` — resolved; `javascript:` + username pins `<span class="rz-link-value">marcus</span>` and no `href` — resolved; publications url-only pins the exact anchor — resolved; `"score":4` → `GPA 4` — resolved; `wild.rs` ownership stated and the ZG-2 dependency exists on the board — resolved; `omitted entirely` grep — present. The `dir="auto"` AC regenerates `example.html` and keeps the tree-lock green; BAR-R1 negative retained. A stub that leaves the old `Option<f64>` score fails the string/integer cases; a stub emitting a label-only `<li>` fails the regex.

Non-blocking: the "no `javascript:` anywhere" clause is good; consider one `mailto:`/`tel:` positive so scheme allow-listing is not over-tightened. Not required for BLESS.

**BLESS ZG-3 — every cycle-1 gap is an exact input/output pair or a corpus-wide negative regex, and the shared test file has an owner and a dependency edge.**

## ZG-4 — Run the Renderer in the browser via Wasm and prove it matches the crate

Cycle-1 blockers: the parity oracle is now crate output produced in the same run via `renderer/examples/render.rs` (owned here, spec'd: stdin → stdout unchanged, `Err` → stderr + exit 1) and locked by `example_render_matches_render_json` — resolved; parity runs on three inputs including `ada.json` and a timestamp-`releaseDate` document that does not panic pre-ZG-2 — resolved; `wasm-load-failure` (route-abort `*_bg.wasm`, rejection with `renderer`, no `pageerror`, Jordan still shown) — resolved; `wasm-large` (≥ 4.8 MB built in-probe, ≤ 5 s, last entry present) — resolved; the prerequisite line `FAIL  ZG-4/wasm-parity prerequisite missing: cargo example render` follows the convention — no `SKIPPED`. `ada.json` content is stated by this owner and ZG-5/ZG-22 depend on it transitively. The anti-stub AC (a `render` that returns `sandbox.html` markup fails the swap and all three parity cases) is real.

Non-blocking (implementer, no re-review): the "no stack trace" check `at ` absent also bans the English word "at" in a plain-words message — use `/\n\s+at /` instead. `wasm-no-network` should say the module's own `.wasm`/glue fetch at page load counts as a page asset (the parenthetical already implies it).

**BLESS ZG-4 — the parity oracle is now the crate itself in the same run on three inputs, and load-failure, size and no-network are each a probe with a concrete negative; a stale or stubbed module fails at least three ACs.**

## ZG-5 — Paste or open your own JSON Resume and see it in every Theme

Cycle-1 blockers: `not-a-resume.pdf` bytes are stated in scope by this owner — resolved; `trailing-comma.json` restated as owned — resolved; drop zone has `drop-json`/`drop-pdf` with a `DataTransfer` mechanism — resolved; `render-failed` class exists with a probe that overrides `window.resumezen.render` to reject with a serde-looking message and asserts `could not`, `.rz-name` unchanged, no `pageerror` — resolved; `no-serde-tokens` applies to the five error probes with an explicit list — resolved; `file-classes` pins content-first classification with three concrete files — resolved; `corrupt-storage` covers `{` and a non-résumé shape → Jordan, no banner, no console error, key removed — resolved. `copy` uses `textContent`. Consumers depend on ZG-4 (owner of `ada.json` and `render`). The string-replace stub AC still bites.

Non-blocking: scope says the serde-token ban is "applied to every class", but `no-serde-tokens` names only the five paste probes and omits `not-json-file` (`open-pdf`, `file-classes`, `drop-pdf`); the implementer should run the same assertion there. Not a verdict changer — the five listed are the classes that carry parser text.

**BLESS ZG-5 — every error class has a fixture, a selector, a required substring and a shared forbidden-token list; the drop zone, renderer-`Err` and corrupt-storage paths are now probes that a happy-path build fails.**

## ZG-7 — Rewrite the chrome in plain language with an About panel and a free-during-preview line

Cycle-1 blocker: `one-print` is now "exactly one button whose accessible name starts with `Print /`", with `Print preview` still resolving to exactly one — resolved; scope and scope_out say the toggle keeps its name, so S4/U3 selectors survive. Today's second `Print` (the filter chip) is renamed to `For paper` by scope, and `no-jargon` asserts `For paper` — the chip cannot silently keep the word. `textContent` is used for the jargon and heading checks; the print-honesty sentence is tied to the S3/U3 probes being green in the same run; GitHub `href` is asserted by string equality, offline.

**BLESS ZG-7 — the contradicted `one-print` is pinned to `Print /` with the toggle explicitly retained, every text AC is a `textContent` substring with a negative list, and About has an Escape/focus-return check.**

## ZG-8 — Copy a link to this exact view and say so when a theme in the URL does not exist

Cycle-1 blockers: `copy-failed` overrides `navigator.clipboard.writeText` via `addInitScript` to reject and asserts `[data-copy-state="failed"]`, `select the address bar`, `Copied` never shown (sampled 500 ms), no `pageerror` — deterministic and headless-safe, resolved; `no-notice` now includes `/?theme=` — resolved; `notice-escaped` asserts literal `<b>x</b>` text and `querySelector('b')` null — resolved; `copy-link` states `grantPermissions` — resolved. `view-url`, `view-back`, `unknown-theme`, `invalid-view` are unchanged and exact.

**BLESS ZG-8 — the clipboard failure state, the empty-query no-notice case and the escaping case are each a probe with a forbidden outcome, and the mechanics needed to run them headless are stated.**

## ZG-11 — Print a real résumé without blank pages, lost bullets, or pale ink

Cycle-1 blockers, checked: the rasterisation oracle is gone (geometry helpers `printableHeightPx`/`paginate`, heights verified correct) — resolved in principle; `U3_PRINT_PAGES` re-baselined to exact `{2, 2, 2}` plus `LONG_PRINT_PAGES ≤ 3`, `!==` — resolved; `fixture-trips-e1` proves E1 — present; fixture provenance locked by `fixtures.rs::long_resume_html_is_crate_output` with counts — resolved; four ink selectors — resolved; "unchanged" replaced by a regression assertion — present; `entry-intact` uses the same oracle and states the approximation — resolved; the sandbox DOM-swap loading mechanism is stated — resolved. Two of the new oracles do not hold up against the repo:

1. **The geometry oracle has no layout width, and the width it will get is not the paper's.** In `@media print` every theme sets `.rz-resume { width: auto; max-width: none }`, so in print emulation inside the Garden iframe the article lays out at the iframe's width (≈ 980 px at the probes' 1280×800 viewport with the 18.5 rem sidebar), not at Quarto's 682 px / Switchyard's 673 px / Nightgarden's 720 px printable width. `fixture-trips-e1` (`#rz-experience` > 952 px) and `page1-fill ≥ 0.85` therefore measure a layout the printer never produces: lines wrap ~45 % less, so a fixture that clearly trips E1 on paper may not exceed 952 px in the probe (4 jobs × 4–6 highlights of 12–25 words is marginal at ~110 characters per line), and the 0.85 fill is a number about the wrong page. Two harnesses with different viewports also get different verdicts. Required: state the printable width per theme next to the heights and that the geometry probes (`fixture-trips-e1`, `page1-fill`, `entry-intact`) lay the article out at it — either by setting the sandbox article/iframe width to `printableWidthPx(theme)` during those probes or by loading `sandbox.html` as a top-level page at that viewport width. The real page counts via `printToPdf` are unaffected (Chromium paginates at paper width there).
2. **`bullets-print` on Nightgarden cannot pass without a change the scope does not contain.** The AC applies the inked-marker assertion to all three themes "as a regression guard". Nightgarden's marker today is `::before { content: ""; background: var(--rz-mint) }` with no print override and no `print-color-adjust: exact`; the AC's bar branch demands `background-color` ≥ 4.5:1 against white **and** `print-color-adjust: exact` computed. Mint on white is nowhere near 4.5:1 and the property is absent, so Nightgarden fails by construction. Scope-in lists for Nightgarden only the four secondary-text colours; the marker is not in scope. Either the scope gains "Nightgarden print marker inked (`print-color-adjust: exact`, ≥ 4.5:1)" — which is E2 again, on a second theme, and fine by me — or the regression clause names Quarto only. As written the AC and the scope contradict each other.

Non-blocking: `page1-fill` should say the numerator is measured from the first block's top (not the iframe's), otherwise a theme's top padding leaks into the ratio.

**REJECT ZG-11 — the geometry probes never state a layout width and will measure the iframe's (~980 px) rather than the paper's (682/673/720 px), so `fixture-trips-e1` and `page1-fill ≥ 0.85` are numbers about the wrong page and their satisfiability depends on the harness viewport; and `bullets-print` demands an inked `background-color` + `print-color-adjust: exact` on Nightgarden's mint dot, which no scoped change touches, so it fails by construction. State `printableWidthPx` per theme and apply it in the geometry probes; put the Nightgarden marker in scope or limit the regression clause to Quarto.**

## ZG-12 — Fit long names in Nightgarden, paint sections without scrolling, keep bullet line breaks

Cycle-1 blockers, checked: Firefox/WebKit dropped — resolved; pixel threshold stated (≥ 200 px, > 32/channel) — stated; `pre-line` compares to a sibling — resolved; the phantom BAR-L1 claim dropped with an owner named — resolved; name injection stated — resolved. `name-fits`, `reduced-motion`, `pre-line` are exact and fine. The three `rz-rise` probes do not survive contact with `nightgarden.css` and `chrome.css`:

1. **`painted-with-support` is unsatisfiable as written.** It takes a `fullPage: true` screenshot of the chrome page and counts pixels "within the `#rz-projects` bounding box" against "the iframe `body` background". The Garden iframe is `height: 100%; min-height: 100vh` with no content-height sizing — a viewport-height box that scrolls internally. `#rz-projects` for Jordan sits below that box; a page-level screenshot (with or without `captureBeyondViewport`) contains the iframe's painted box only, never its scrolled-out content. The region the AC measures is not in the image. The probe must load the résumé document as the **top-level** page (`sandbox.html`, or `/skeleton/example.html` with the theme link swapped) so a full-page capture reaches the section — and then say so, because the scrollport changes what `view()` does.
2. **Scope and AC disagree on what happens in a supporting browser.** Today the hidden start state is `@keyframes rz-rise { from { opacity: 0 } }` + `.rz-section { animation: rz-rise … both }` at top level, with `@supports (animation-timeline: view())` merely swapping the timeline to `view()` with `animation-range: entry 0% entry 32%`. In Chromium (the only probe browser, and the browser Marcus used for Cmd-A) that keeps every below-fold section at opacity 0 until it enters the scrollport. Scope-in keeps exactly that ("the hidden start state … exists only inside `@supports`"), while `painted-with-support` demands the below-fold `#rz-projects` be painted in Chromium without scrolling. Both cannot be true. The body must state the in-support outcome the probe expects — e.g. `animation-fill-mode: none` / a non-zero rest opacity / a range that never hides content wholly outside the scrollport — or drop the pixel probe and keep only the without-support oracle. And because Playwright's beyond-viewport capture semantics for scroll-driven animations are not something two testers will agree on from memory, the AC needs an anti-vacuity clause: the same probe **fails** on the pre-change sheet (recorded in evidence).
3. **`rise-css-structure` checks for declarations that do not exist and so cannot fail today.** It looks for `opacity: 0` / `transform: translateY(` "whose selector matches `.rz-section` or `.rz-rise`". The only such declarations are inside `@keyframes rz-rise` under `from`, and the mechanism that hides sections is the top-level `animation: … both` on `.rz-section`. On the current sheet the check passes vacuously. Define it on the real mechanism: the `animation`/`animation-name: rz-rise` (and any `animation-fill-mode` of `both`/`backwards`) on `.rz-section` must lie inside the `@supports` block, and `opacity: 0` inside `@keyframes rz-rise` counts as the hidden start state.
4. `painted-with-support`'s `innerText` clause cannot fail: `innerText` includes text of `opacity: 0` elements (only `display: none` / `visibility: hidden` remove it). Drop it or make it a `visibility`/`opacity` assertion. Non-blocking on its own; listed because it is the "Cmd-A oracle" the AC claims.

`painted-without-support` is sound: stripping `@supports` today leaves a finished time-based animation with fill `both`, which `getAnimations()` still reports, so the probe fails pre-fix and passes once nothing animates outside the block.

**REJECT ZG-12 — `painted-with-support` measures a region a page-level screenshot cannot contain (the Garden iframe is a viewport-height internal scroller), and even on a top-level page it contradicts scope-in, which keeps Chromium's below-fold sections hidden via `view()` + fill `both`; `rise-css-structure` looks for `.rz-section { opacity: 0 }` declarations that do not exist, so it passes vacuously on the buggy sheet. Load the résumé as the top-level page, state the in-support rest state the probe expects, add "fails on the pre-change sheet", and define the static check on the real `animation`/`@keyframes` mechanism.**

## ZG-13 — Self-host first-party theme fonts so a résumé page never calls jsDelivr

Cycle-1 blockers, checked: `fonts-load` uses `document.fonts.ready` + `FontFace.status === 'loaded'` and explicitly not `fonts.check` — resolved; `font-files` fetches every `@font-face` `url()` (non-empty list) with `200` + `font/woff2` and checks `dist/themes/fonts/` — resolved and machine-independent; `BAR-L1` is owned here with the pairwise assertion and `BAR-L1 PASS` line — resolved; the constants-untouched AC plus green S3/U3 is a real reflow guard — resolved. One oracle remains unsatisfiable:

- **`fallback`: "with `**/themes/fonts/**` requests aborted via `page.route` … no console error … is recorded."** Chromium emits a console message of type `error` (`Failed to load resource: net::ERR_FAILED`) for every aborted subresource, fonts included, and Playwright delivers it on `page.on('console')`. The very setup the probe requires produces the console error the probe forbids; a tester following the AC literally fails it on a correct build. Required: forbid `pageerror` and any console error **other than** resource-load failures for URLs under `/themes/fonts/` (or route-fulfil with `204` and an empty body and state that), so the assertion can distinguish "fonts missing, page fine" from "fonts missing, page broke". The rest of `fallback` (`.rz-name` height > 0, S2 green, no horizontal overflow) is good.

Non-blocking: `grep -c "@font-face" themes/quarto.css` "unchanged from before" — state the number (4) so the tester does not need git; and `fonts-load` should also assert no `FontFace` in the three families has `status === 'error'` (a broken relative `url()` with a working `local()` on the dev machine would otherwise pass).

**REJECT ZG-13 — `ZG-13/fallback` forbids any console error while its own setup (route-aborted font requests) makes Chromium log `Failed to load resource` as a console error, so the AC fails on a correct build; scope the assertion to `pageerror` plus console errors not caused by the aborted `/themes/fonts/` loads (or fulfil with 204 instead of aborting). Everything else is falsifiable and the BAR-L1 owner is settled.**

## ZG-19 — Put the print-honesty rule, a full blank scaffold, and contract fixes where designers look

Cycle-1 blockers, checked: the §6 expansion table is defined and matches the contract exactly (5 contact types at §5.2 line 50, 11 profile modifiers at line 48; §6 has no other `{` token) and the test fails on an unknown `{` token — resolved; ZG-16/ZG-17 dependencies exist on the board and the five header fields are asserted exactly once — resolved; fonts sentence and single-statement `content:` rule have greps, and the README negatives are satisfiable (README today has neither string and already cites `(§2)`) — resolved; `blank-readable` is a visibility probe — resolved. Two things the revise introduced or left unwired:

1. **The proofing fixture's photo cannot resolve, and no AC would notice.** Scope sets `basics.image` to the relative path `samples/portrait.svg`; `emit.rs` writes `src` verbatim; ZG-14 serves the file at `/skeleton/samples/contract.html`. The browser therefore requests `/skeleton/samples/samples/portrait.svg` → 404, and the one class this fixture exists to proof (`rz-photo-img`) renders as a broken image. The ACs assert only that the strings `class="rz-photo-img"` and `alt="…"` are present. Required: an AC that the served `contract.html`'s `rz-photo-img` actually loads (`naturalWidth > 0` in Playwright, or `fetch(new URL(img.src, location))` → 200) — which forces the path to be right (`portrait.svg`, or an absolute `/skeleton/samples/portrait.svg`, either is fine) — and a `curl` 200 for the SVG itself.
2. **Test-order dependency on ZG-14 without an edge.** `blank-readable` applies `_blank.css` to "the served `/skeleton/example.html`", and the README AC points designers at `samples/contract.html` "(ZG-14 already serves `skeleton/samples/*`)". ZG-19 depends on ZG-16 and ZG-17 only; neither reaches ZG-14 (ZG-16 has no deps, ZG-17 → ZG-16, ZG-14 → ZG-7). If ZG-19 executes before ZG-14 — which the graph permits — `blank-readable` and the proofing fixture are unreachable from the served Garden and the probe cannot run. Add ZG-19 → ZG-14, or change `blank-readable` to open `skeleton/example.html` from disk (`file://`) and drop the "served" claim.

Non-blocking: the `Historical` banner grep is `head -5` — fine; the `License:` "exactly once" count could collide with ZG-17's wording if that wording itself contains `License:` — ZG-17's revise should avoid it.

**REJECT ZG-19 — the proofing fixture's `basics.image` path (`samples/portrait.svg` from a file inside `skeleton/samples/`) resolves to `/skeleton/samples/samples/portrait.svg` and no AC checks the photo loads, so the fixture's stated purpose (proof `rz-photo`) has no oracle; and `blank-readable` plus the served-fixture claim depend on ZG-14, which ZG-19 does not reach in the graph. Add a photo-loads assertion and the ZG-14 edge (or a disk-based probe).**

## ZG-20 — Ship `npm run lint-theme` so a Designer knows pass or fail before opening a PR

Cycle-1 blockers, checked: complex-selector semantics with eleven pass/fail unit cases — resolved; `\p{L}{3,}` with `"名前"` and the `content-counter` warning decision — resolved; `bad-theme.css` is five stated lines with three named errors at named line numbers and a `3 errors` summary — resolved; `background-color` and `var()` → `print-ink-unresolved` — resolved; exit-code contract with a warnings-only case — resolved. Two ACs are still not decided by the body:

1. **The selector rule is silent on the universal selector, and a first-party theme uses it.** Nightgarden line 274 is `.rz-entry-header > * { … }`. The rule allows "type selectors, pseudo-classes and pseudo-elements" in a selector that has an `rz-` compound; `*` is none of those, and no unit case covers it. A strict implementation flags Nightgarden and AC 1 ("first-party exit 0 with `0 errors`") fails; a lenient one passes; the unit tests cannot tell them apart. Decide it and pin it: `.rz-entry-header > * {}` → no error (and `* {}` alone → `selector`).
2. **The probes.mjs meta-test is over-determined and cannot detect a missing lint.** "probes.mjs fails (exit 1) when a temporary `themes/zz-bad.css` is present" is already true today with no lint at all: `staticProbes()` fails `Generated Themes.elm is missing zz-bad` for any theme file absent from the catalog (and, if the catalog is regenerated first, the three-button count and the `theme-switcher` checks fail instead). A `checkTheme` that is never wired into `probes.mjs` passes this AC. Required: the meta-test asserts the lint's own line — `FAIL  ZG-20/lint zz-bad.css:3 error selector` (or equivalent naming the file and the code) — not merely the exit code.

Non-blocking: after ZG-13 every first-party `@font-face` uses a relative `url("fonts/…")`; whether `url-origin` ("non-https origin") warns on a relative URL is unspecified — warnings exit 0 either way, but add the unit case so the message designers see is deliberate.

**REJECT ZG-20 — the selector rule does not decide `*`, and Nightgarden's `.rz-entry-header > *` makes "first-party exit 0" pass or fail depending on the implementer's guess; and the probes.mjs meta-test passes today with no lint wired in (`staticProbes` already exits 1 for an uncatalogued theme file), so the integration AC is theater. Pin the universal-selector case and make the meta-test assert the lint's own FAIL line.**

## ZG-21 — Publish a résumé to a stable public URL with an unguessable edit link (API)

Cycle-1 blockers, checked one by one: `no-store`/`noindex` on 200 and 410 — `public_page_headers_and_purity`, resolved; wrong/absent key on PUT and DELETE with row-unchanged and PUT-on-deleted — `put_and_delete_require_key`, resolved; PUT validation — `put_validates_like_post`, resolved; malformed ids with zero store calls — `malformed_ids_are_404`, resolved; 1 000 distinct keys — resolved; §1.8 round trip — `unknown_keys_round_trip`, resolved; purity — resolved; exact 1 MiB boundary — resolved; local run, missing `dist`, README env vars — resolved; header-only key — `key_only_in_header`, resolved. Two validation cases the domain plainly has are still unspecified:

1. **Valid JSON that is not a résumé shape.** `{"basics":{"name":"E"},"work":"nope"}` — the exact class ZG-5 calls `not-a-resume` and the most common real error (Elena's half-filled sections) — is neither "not JSON" (400) nor "name missing" (422) in the validation list. A tester cannot say whether 400, 422 or 500 is correct, and a serde error escaping the handler gives 500. Required: state the status (422, naming the offending key, mirrors ZG-5) and add it to `rejects_bad_input`/`put_validates_like_post`; state that POST/PUT validate by rendering (`render_json` `Err` → 422, never 500) so `GET /r/{id}` can never 500 on a stored row.
2. **The error body shape is unowned, and ZG-22 already consumes one.** ZG-22's `api-errors` stubs `422 {"error":"name"}` and expects the chrome to surface `name`; ZG-21 says only "422 mentioning `name`" and never states whether the body is JSON, which field carries the code and which the sentence. Two correct implementations (`{"error":"name"}` vs `{"message":"Add basics.name"}` vs `text/plain`) both pass ZG-21, and only one makes ZG-22's chrome say the right thing against the real backend. Required: pin the error body (`Content-Type` and shape, e.g. `{"error": <code>, "message": <plain sentence>}`) in ZG-21 and assert it in the 400/413/422 tests; ZG-22's stubs then reference the owner. If the pinned shape is the one ZG-22 already assumes, ZG-22 needs no edit.

Non-blocking: `tower-http` CORS is in scope with no AC — since the backend serves `dist` same-origin, say CORS is not enabled (or pin the allowed origin) so the "unavailable on Netlify" story stays true.

**REJECT ZG-21 — valid-JSON-wrong-shape input (ZG-5's `not-a-resume`, the commonest real error) has no status in the validation contract, so 500 vs 422 is a guess, and the 400/413/422 response body shape that ZG-22's `api-errors` already stubs as `{"error":"name"}` is not pinned by its owner. Add the shape case with a 422-never-500 rule and pin the error body.**

## ZG-22 — Publish, copy your link, delete — with plain answers to who can see it

Cycle-1 blockers, checked: `SKIPPED` is forbidden, the harness starts the ZG-21 backend on `PROBE_PORT + 1` with `RESUMEZEN_DB=:memory:`, and a start failure is `FAIL  ZG-22/<slug> prerequisite missing: backend` — resolved; `publish-twice` asserts one `PUT`, no second `POST`, URL unchanged — resolved; `api-errors` covers 413/422/500 with required substrings, no spinner, no `pageerror`, and `unavailable` asserts no `pending` remains — resolved; `delete-cancel` — resolved; the key moved to the fragment with `replaceState`, `edit-link` asserts `location.hash === ""`, and `key-never-in-url` walks the request log and requires the `Authorization` header on every `/api/resumes/{id}` call — resolved and stronger than asked; `tampered-key` — resolved. `ada.json` is consumed via ZG-5 → ZG-4; `.copy-link` via ZG-8; the backend via ZG-21 — all edges exist. A stub that fakes `published` without a network call fails `publish` (the public URL is fetched and must contain `Ada Lovelace`) and `key-never-in-url`.

Non-blocking: the publish probes must load the Garden from the backend origin (`http://127.0.0.1:PROBE_PORT+1/`) for relative `/api/resumes` calls to reach it — the body implies this ("against the backend on `PROBE_PORT + 1`"); say it in the harness line. `api-errors` runs against route stubs; the real-backend error shape is ZG-21's blocker above, and its fix must adopt the `{"error":…}` shape these stubs assume or ZG-22 returns through the chain.

**BLESS ZG-22 — every failure and repeat path a Publish control must survive (update-not-duplicate, 413/422/5xx, cancel, tampered and wrong keys, key never in a URL) is a probe with a forbidden outcome, the backend prerequisite fails loudly instead of skipping, and every fixture it uses has an owner it depends on.**

---

## Summary

| id | verdict | one-line reason |
| --- | --- | --- |
| ZG-1 | BLESS | exact commands; DoD contradiction removed; count oracle survives ZG-2/3 |
| ZG-3 | BLESS | omit rule + corpus-wide empty-node regex; all cycle-1 cases pinned; `wild.rs` owner + edge |
| ZG-4 | BLESS | crate-in-the-same-run parity on three inputs; load-failure, size, no-network probes |
| ZG-5 | BLESS | every error class has fixture, selector, substring, shared token ban; drop/corrupt-storage covered |
| ZG-7 | BLESS | `one-print` pinned to `Print /` with toggle retained; `textContent` throughout |
| ZG-8 | BLESS | deterministic clipboard failure, empty-query no-notice, escaping |
| ZG-11 | REJECT | geometry oracle has no layout width (iframe ≠ paper); Nightgarden marker AC contradicts scope |
| ZG-12 | REJECT | screenshot oracle cannot see below the iframe fold; scope keeps Chromium sections hidden; static check vacuous |
| ZG-13 | REJECT | `fallback` forbids the console error its own route-abort produces |
| ZG-19 | REJECT | photo path resolves to `samples/samples/`, no load assertion; ZG-14 dependency missing |
| ZG-20 | REJECT | `*` undecided vs Nightgarden `> *`; meta-test passes with no lint wired |
| ZG-21 | REJECT | wrong-shape JSON status unspecified (500 vs 422); error body shape unowned while ZG-22 stubs it |
| ZG-22 | BLESS | failure/repeat paths are probes; no `SKIPPED`; all fixture owners are dependencies |

7 BLESS, 6 REJECT.

## Set-level notes for the Generator

### What the revise got right (keep)

- Fixture ownership is now real: `ada.json` (ZG-4), `trailing-comma.json`/`not-a-resume.pdf` (ZG-5), `long-resume.*` (ZG-11), `bad-theme.css` (ZG-20), `wild.rs` (ZG-2), `BAR-L1` (ZG-13), the print constants (ZG-11). Every consumer I traced has an edge to its owner except ZG-19 → ZG-14 (above).
- No AC in the set prints `SKIPPED`; prerequisite failures are `FAIL … prerequisite missing: <what>` lines in ZG-4 and ZG-22.
- `textContent`, offline `href` equality, `grantPermissions`, and `addInitScript` overrides are used consistently.

### Cross-item facts the rejected bodies must share

- **Print geometry width.** ZG-11's `printableWidthPx` (682 / 673 / 720 px) should live next to `printableHeightPx`; ZG-12's `name-fits` at 390×844 and ZG-13's `fallback` overflow check are screen-width checks and do not need it.
- **Top-level résumé page for pixel/scroll oracles.** ZG-12's screenshot probe must open the résumé document itself (not the Garden iframe). If ZG-11's geometry probes also move to a top-level page at paper width, one helper (`openResumePage(theme, fixtureHtml, widthPx)`) serves both; whichever lands first owns it and the other references it.
- **Console-error assertions with aborted routes** (ZG-13 `fallback`, and any future route-abort probe): forbid `pageerror` and console errors *not* caused by the aborted URLs. ZG-4 `wasm-load-failure` already asserts `pageerror` only — correct.
- **Error body shape.** ZG-21 owns it; ZG-22's `api-errors` stubs must match it. Pin once, reference once.
- **Anti-vacuity clauses.** Where a probe's pre-fix behaviour depends on browser semantics nobody can recite (ZG-12 screenshot vs `view()`; ZG-11 `fixture-trips-e1`), the AC should say "this probe FAILs on the pre-change sheet/fixture" and require that failure in evidence. ZG-11 already does this for E1; ZG-12 needs it.

### Execution-order facts (unchanged from cycle 1, still true)

- `_blank.css` header: ZG-16 → ZG-17 → ZG-19 → ZG-20; ZG-19 additionally needs ZG-14's serving (above).
- ZG-11 and ZG-13 both touch print page counts; ZG-13's "constants untouched + S3/U3 green" AC is the guard, and its scope_out sends a reflow back to planning rather than editing constants — good.
- ZG-3's `dir="auto"` regenerates every crate-output lock (`example.html`, `long-resume.html`, `samples/contract.html`); the PO's ordering note stands.
