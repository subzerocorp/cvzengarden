# AVRIL round 1 — QA Architect review (cycle 1)

**Role:** `qa-architect-agent` (second adversary) · **Date:** 2026-08-23 · **Cycle:** 1
**Scope:** the 19 PBIs the Product Owner blessed in cycle 1 — ZG-1, ZG-2, ZG-3, ZG-4, ZG-5, ZG-7, ZG-8, ZG-9, ZG-11, ZG-12, ZG-13, ZG-14, ZG-15, ZG-16, ZG-18, ZG-19, ZG-20, ZG-21, ZG-22. (ZG-6, ZG-10, ZG-17 are with the Generator; not reviewed.)
**Inputs read in full:** `docs/plans/round-1-avril-intent.md`, the five round-0 reports, `round-1-avril-generator-round1.md`, `round-1-avril-po-round1.md`, all 19 bodies (`pinto show … --plain`), `frontend/scripts/probes.mjs`, `renderer/tests/acceptance.rs`, `renderer/src/{date,slug}.rs`, `frontend/scripts/{generate,serve,copy-dist}.mjs`, `frontend/static/ports.js`, `skeleton/CLASS-CONTRACT.md`, `qa/MARKET-QUALITY-BAR.md`, `themes/README.md`, `justfile`.

Mandate: *BLESS only PBIs whose acceptance criteria are complete, falsifiable, and hostile to happy-path theater; otherwise REJECT with the missing cases.*

I judge testability only. I do not author bodies, touch the board, or reopen product scope.

## Facts I verified before judging (they change verdicts)

| Fact | How | Affects |
| --- | --- | --- |
| The crate's `<article class="rz-resume">` is **not** byte-identical to the one in `skeleton/example.html` (first diff at byte 311, a blank line; 18 311 vs 18 325 bytes). `acceptance.rs` compares trees, not bytes. | temporary cargo test, removed | ZG-4 byte-lock oracle |
| Only Chromium is installed for Playwright (`~/Library/Caches/ms-playwright`: chromium + headless shell only). | `ls` | ZG-12 Firefox/WebKit probe |
| Playwright cannot rasterise a PDF; `probes.mjs` counts pages by regex over the PDF bytes. No PNG decoder or PDF renderer exists in the frontend toolchain. | read `probes.mjs`, `package.json` | ZG-11 fill-ratio / pixel probes |
| No `BAR-L1` probe exists in `probes.mjs` (grep `L1`: nothing). `U3_PRINT_PAGES = {nightgarden: 2, quarto: 3, switchyard: 3}` is asserted with `!==`. | read `probes.mjs` | ZG-11, ZG-12, ZG-13 "still passes" claims |
| First-party themes use descendant type selectors: `.rz-resume a`, `.rz-summary p`, `.rz-prose p`, `.rz-resume a:focus-visible`. First-party `content:` values are `""`, `" "`, `", "`, `": "`, `" · "`, `"– "`. | grep `themes/*.css` | ZG-20 selector allowlist vs "first-party exit 0" |
| `git remote` is `git@github.com:subzerocorp/cvzengarden.git`; the `https://github.com/subzerocorp/cvzengarden` URL in ZG-7/14/16/18 is correct. | `git remote -v` | ZG-7, ZG-14, ZG-16, ZG-18 |
| `frontend/fixtures/` does not exist; `renderer/tests/` holds only `acceptance.rs`; `backend/` holds only a README. | `ls` | every fixture reference below |
| The common DoD requires `progress.md` and `features.json` to change on every PBI. | PBI footer | ZG-1 AC 5 |

---

## ZG-1 — Make the renderer pass clippy pedantic so `just verify` is green

Commands are exact and exit-code observable (AC 1–3), the no-suppression grep is a real anti-stub, and the byte-lock on `skeleton/` is a `git diff` a tester can run. One AC is unsatisfiable by construction: AC 5 says `git diff --name-only` contains no path outside `renderer/`, but the common Definition of Done on the same card requires `progress.md` and `features.json` to be updated. A tester must either fail AC 5 or violate the DoD. AC 4's "same 19 tests" is a snapshot count; it should be "no test removed and the count is ≥ the pre-change count", otherwise ZG-2/ZG-3 landing first (they add tests) makes the number wrong.

Missing/wrong:
- AC 5: allow the harness tracking files (`progress.md`, `features.json`, and the PBI's own evidence) alongside `renderer/`, or move the "only renderer" claim to `git diff --name-only -- . ':!progress.md' ':!features.json'`.
- AC 4: replace "same 19 tests" with "`cargo test` reports 0 failed and at least as many tests as before".

**REJECT ZG-1 — AC 5 ("diff touches only `renderer/`") contradicts the card's own DoD (`progress.md`/`features.json` must change); AC 4's fixed test count breaks as soon as ZG-2/3 add tests. One-line fixes.**

## ZG-2 — Never panic on a wild date: tolerate timestamps, drop unparseable dates

Every AC is a concrete fixture in, a concrete substring out: the panic regression is a named test (`multibyte_start_date_does_not_panic`) with Devon's four exact inputs; the timestamp case asserts the exact `<time … datetime="2023-05-31">May 31, 2023</time>`; unparseable → `<span class="rz-date …">` with a negative (`no datetime="March 2020"`, no `rz-is-current`); `2020-13`, `2020-02-30`, `2024-02-29`, `Present` are all pinned; the Jordan byte-lock stays green; the contract grep is specific. A stub that returns `Ok("")` fails the exact-substring ACs; a stub that keeps `_ => Some((raw, raw))` fails the `no datetime="March 2020"` AC; a stub that computes `is_current` from the raw string fails the `2020-13` AC.

Non-blocking gaps the Generator may fold in without re-review: (a) for `2020-02-30` also assert the raw text `2020-02-30` is still present in the entry (the rule says raw text survives; the AC only says no `<time`); (b) one space-separated timestamp (`2023-05-31 09:00`) since scope names it; (c) `data-rz-entry` for a timestamp start (`talk-2023`) — `iso_year` is the very function that panicked.

**BLESS ZG-2 — every AC is an exact input/output pair including the named round-0 panic regression and the negative attribute cases; a superficial stub fails at least four of them.**

## ZG-3 — Render wild JSON Resume files: numeric score, url-only entries, CRLF, bad URLs

Most ACs are exact and stub-hostile: `3.7` → `<p class="rz-score">GPA 3.7</p>`, the url-only certificate → exact anchor plus a generalised "no empty `<li class="rz-entry…">`" regex over every fixture, the Keybase profile → exact `li` shape, CRLF → exactly two `<p>`, emoji slugs → exact `data-rz-entry` values, `dir="auto"` + contract table, BAR-R1 retained.

Where the AC lets two contradictory implementations both pass:
- **Bad URL with no username (Devon's exact fixture).** Scope says "link omitted (primary emitted as plain text)". For a profile the "plain text" is `username` else hostname; with `url: "https://"` and no `username` there is no text. AC 5 only says "emits no `<a` for that profile". A `<li class="rz-link rz-link--other"><span class="rz-link-label">other</span></li>` satisfies the AC and violates Invariant 5 (omit empties) — Devon's complaint half-fixed. Required: state that a profile whose value would be empty is omitted entirely, and extend the empty-node regex to `.rz-link` and `.rz-contact` (`<li class="rz-(link|contact)[^>]*>\s*(<span[^>]*>[^<]*</span>\s*)?</li>` with no value span).
- **`javascript:` with a username** — expected shape not stated; state `<span class="rz-link-value">{username}</span>` and no `href`.
- **Publications with only `url`** — in scope, no AC; add the mirror of the certificate case.
- **Integer score** (`"score": 4`) — add `GPA 4`; scope says number, AC only tests a float.

**REJECT ZG-3 — the bad-URL/no-username profile (Devon's exact fixture) has no specified outcome, so a label-only empty `<li>` passes while violating Invariant 5; add the omit rule + `.rz-link`/`.rz-contact` empty-node regex, the publications url-only case, the `javascript:`+username shape, and an integer score.**

## ZG-4 — Run the Renderer in the browser via Wasm and prove it matches the crate

The parity oracle is the point of this PBI and it is wrong as written. AC 3 (`ZG-4/wasm-byte-lock`) demands the rendered `<article>…</article>` bytes equal that node in `skeleton/example.html`. I checked: the crate's own output differs from `example.html` at byte 311 (a blank line before `<address>`; 14 bytes over the node). `acceptance.rs` passes because it compares normalised trees. The AC cannot pass against the crate it is meant to prove parity with — an implementer will either "fix" `example.html` by hand (ZG-1 forbids touching `skeleton/`) or weaken the probe silently.

Required changes:
- Replace the reference: compare Wasm output bytes to **crate output produced in the same run** (e.g. a `renderer/examples/render.rs` that reads JSON on stdin and writes HTML to stdout, invoked by the probe; or a fixture written by a cargo test into `renderer/target/`), or apply the same tree-normalisation `acceptance.rs` uses. Either is a real crate parity oracle; `example.html` is not.
- Parity on more than Jordan: at minimum Ada (`{"basics":{"name":"Ada"}}`) and one ZG-2/ZG-3 wild fixture, so a Wasm build pinned to an older crate is caught.
- Module load failure: with `dist/wasm/*_bg.wasm` returning 404 (route abort), `window.resumezen.render` rejects with a message and there is no uncaught exception (this is the error surface ZG-5 will display).
- Size bound: Devon's 4.8 MB résumé renders through the Wasm bridge without exception (state a ceiling, e.g. ≤ 5 s); string marshalling across `wasm-bindgen` is the realistic failure.
- AC 2 (missing `wasm-pack`) is a good negative; keep. AC 8 (stub returning `sandbox.html` markup fails the Ada swap) is a good anti-stub; keep.

**REJECT ZG-4 — the byte-lock against `skeleton/example.html` is unsatisfiable (verified: crate output differs at byte 311; acceptance is tree-equality), so the PBI's only parity oracle is broken; compare against crate output produced in the run, add a second-input parity case, a module-load-failure case, and a large-input bound.**

## ZG-5 — Paste or open your own JSON Resume and see it in every Theme

The happy path and most error classes are pinned to selectors, fixture text, and forbidden tokens (`expected`, `EOF`) — good, and the string-replace stub AC is real. Elena's walk-away trigger is a cryptic error; the ACs leave exactly the paths where cryptic errors leak unspecified:
- `frontend/fixtures/not-a-resume.pdf` is referenced but not specified; state its content (a minimal `%PDF-1.4 … %%EOF` file is enough) — a tester cannot build it from the AC.
- The drop zone is in scope with no AC. Add `ZG-5/drop-json` (Playwright `DataTransfer` drop of `skeleton/resume.json` → Jordan) and `ZG-5/drop-pdf` (→ `not-json-file`).
- JSON parses, shape is a résumé, but the renderer returns `Err` (a ZG-2/ZG-3 regression): which `[data-paste-error]` and what text? Unspecified. Name the class (e.g. `render-failed`) and apply the no-serde-token rule to it.
- The no-serde-token rule (`expected`, `EOF`, `invalid type`) is asserted only on `paste-trailing-comma`; apply it to every error class (`not-a-resume`, `missing-name`, `render-failed`).
- Class boundary: a `.json` **file** whose content has a trailing comma must show `invalid-json` (with line/column), not `not-json-file`; a `.txt` file containing valid JSON — decide and pin.
- `localStorage['resumezen.resume']` holding garbage (`"{"`) or a non-résumé on reload must show Jordan and no error banner/console error — today's code path is "restore on reload", and this is the one place a user cannot recover from without dev tools.
- Copy nit from PO (non-blocking): `Nothing leaves your browser` — the AC already only asserts that substring, fine.

**REJECT ZG-5 — the PDF fixture is unspecified, the drop zone has no AC, a renderer `Err` after a successful parse has no error class, the serde-token ban covers one case only, and corrupted `localStorage` on reload is untested — all paths where Elena's cryptic-error trigger fires.**

## ZG-7 — Rewrite the chrome in plain language with an About panel and a free-during-preview line

Text ACs are exact substrings with an explicit negative list (`rz-target`, `@media`, `Skeleton`, `judged on hover`, `CHROME`), badges are pinned per theme, About has an Escape/focus-return check, and the repo URL matches `git remote`. One AC contradicts the card: `ZG-7/one-print` requires "exactly one button with accessible name starting `Print`", but the View toggle "Print preview" is retained (scope does not rename it; `probes.mjs` clicks `getByRole('button', {name: 'Print preview'})` and `s4Probes` matches `"Print preview"`). Two buttons will start with `Print`; the AC fails by construction or forces an unplanned rename that breaks existing probes.

Required: restate as "exactly one button whose accessible name starts with `Print /`" (or rename the toggle, e.g. "Paper preview", and say so in scope + note the S4/U3 selector updates).

Non-blocking clarifications: `body.innerText` applies `text-transform`; if "Appearance" is uppercased by CSS, `innerText` returns `APPEARANCE` and the mixed-case `Appearance` check fails — use `textContent` or case-insensitive matching, and keep the `CHROME` heading check on `textContent`. The "prints in dark ink on white paper" sentence is a print-honesty claim; BAR-U3 says such a claim with a failing listed theme FAILS — the existing S3/U3 probes are the guard; say so in the AC.

**REJECT ZG-7 — `ZG-7/one-print` ("exactly one button whose name starts with `Print`") is contradicted by the retained "Print preview" toggle; pin it to `Print /` or rename the toggle explicitly and update S4/U3 selectors.**

## ZG-8 — Copy a link to this exact view and say so when a theme in the URL does not exist

Probes are concrete (clipboard content, `aria-pressed`, Back, notice text and close, `?view=sideways`). Missing negative cases the domain plainly has:
- Clipboard write failure (permission denied, non-secure context, no user activation): the control must show a visible failure state (`Copy failed — select the address bar`) and never silently claim `Copied`. Elena's fallback is screenshots; a silent failure sends her back there. Probe: deny `clipboard-write` in the context → `[data-copy-state="failed"]`.
- `/?theme=` (empty) shows no notice — scope says so; AC 5 covers `/` and `/?theme=Quarto` only. The existing S5 probe loads `/?theme=` — add the no-notice assertion there.
- Notice text is the raw query value: `/?theme=%3Cb%3Ex%3C%2Fb%3E` must render the literal `<b>x</b>` text (no element) — one probe line; Elm's `text` makes this cheap, and it pins the behaviour against a future `innerHTML` shortcut.
- Probe mechanics (non-blocking): the clipboard probe needs `context.grantPermissions(['clipboard-read','clipboard-write'])`; state it so the AC is runnable headless.

**REJECT ZG-8 — no clipboard-failure state (silent `Copied` is exactly the screenshot fallback Elena described), `/?theme=` no-notice case in scope but not AC, and no text-escaping case for the echoed theme name.**

## ZG-9 — On a phone show the résumé first and fold the controls into a Theme button

Every AC is a viewport, a selector, and a number: iframe top `< 80px` and `.rz-name` inside the viewport at 390×844; `Theme` button with `aria-expanded` transitions; Escape + focus return; desktop unchanged via the existing S1–S5 geometry probes; `scrollWidth <= 390` for all three themes. A stub that merely reorders DOM without the sheet fails `ZG-9/sheet`; a stub that hides the sidebar fails `#theme-option-quarto is clickable`.

Non-blocking: body scroll-lock is in scope with no AC (`document.body` `overflow` or `scrollY` unchanged while the sheet is open); add `aria-modal`/focus containment if the sheet is a dialog; PO's note that future controls (Use my résumé, Publish) must live in the sheet is for the later PBIs' ACs.

**BLESS ZG-9 — viewport-pinned geometry, ARIA state transitions, and an explicit desktop-unchanged regression make each AC falsifiable and a reorder-only stub fails the sheet probe.**

## ZG-11 — Print a real résumé without blank pages, lost bullets, or pale ink

This is the PBI most in need of a real fixture and it names one (`long-resume.json`/`.html`, four jobs) — right instinct. The ACs then lean on tooling that does not exist and contradict an existing probe:
- **Rasterisation.** `ZG-11/page1-fill` and the `bullets-print` "pixel probe" say "rasterised via Playwright PDF → PNG". Playwright cannot rasterise a PDF, headless Chromium cannot render one, and the frontend has no PNG decoder. Either name the tool (poppler `pdftoppm` as a stated dev prerequisite — a system dependency that needs the human's approval — or a `pdf.js` dev dependency, also outside the approved list) and make its absence a `FAIL`, not a skip; or replace the oracle with print-emulated geometry (e.g. in `emulateMedia({media:'print'})`, the y-extent of content that the browser would place on page 1 relative to the `@page` height, combined with the page-count deltas).
- **Walk-bar contradiction.** `u3IframePrintProbes`/`s3Probes` assert `pages !== U3_PRINT_PAGES[id]` → FAIL with `{quarto: 3, switchyard: 3, nightgarden: 2}`. AC 2 demands Jordan prints to ≤ 2 in Quarto/Switchyard. Both cannot be green. State the new walk-bar constants (exact numbers, not `≤`) and that `U3_PRINT_PAGES` is re-baselined to them.
- **Fixture adequacy.** Jordan never trips E1; the AC must prove `long-resume.html` does: in print emulation, `#rz-experience` height exceeds one printable page height for Quarto (Letter) and Switchyard (A4). Without this, a short "long" fixture passes `page1-fill` before the fix.
- **Fixture provenance.** `long-resume.html` "rendered by the crate": pin it — a cargo test (or the ZG-4 `render` example) regenerates it and asserts equality, otherwise the HTML drifts from the JSON.
- **Print-ink coverage.** Scope lists `.rz-entry-secondary`, `.rz-location`, `.rz-dates`, `.rz-meta`; AC 6 checks only the first. Assert all four ≥ 4.5:1.
- **"Quarto and Nightgarden unchanged"** is not falsifiable; assert their print-emulated `.rz-bullet::before` `content` is non-empty (or `list-style-type` not `none`).
- `entry-intact` via `getBoundingClientRect` against page height assumes the browser's break positions equal multiples of page height; say it is an approximation or use the same geometry oracle as `page1-fill`.

**REJECT ZG-11 — the fill-ratio and pixel probes require PDF rasterisation the toolchain does not have (name the tool or change the oracle), AC 2 contradicts the existing `U3_PRINT_PAGES` walk bar (state the new constants), the long fixture is never proven to trip E1, print-ink checks one of four selectors, and "unchanged" is not an assertion.**

## ZG-12 — Fit long names in Nightgarden, paint sections without scrolling, keep bullet line breaks

`name-fits` (scroll vs client width at 1280 and 390 with a 27-character name) and `reduced-motion` are exact. The centrepiece, `painted-before-scroll`, is not runnable as written:
- It requires Playwright Firefox/WebKit; only Chromium is installed. Either state `npx playwright install firefox webkit` as a prerequisite and make their absence a `FAIL` (not a skip), or use a Chromium-only oracle: a CSS-structural check that the `opacity: 0`/`translateY` start state exists **only** inside `@supports (animation-timeline: view())` and that `.rz-section` outside it computes `opacity: 1`, plus the Chromium runtime check.
- "A full-page screenshot's `#rz-projects` region is not uniformly background-coloured" needs pixel access; feasible without a dependency by loading the PNG into an in-page `<canvas>` and reading `getImageData`, but the AC should say what "not uniformly" means (≥ N pixels differing from the background by > threshold) so two testers get the same verdict.
- `pre-line`: `clientHeight ≥ 2.5 × line-height` fails when `line-height` computes to `normal` (a string). Compare to a single-line bullet in the same list instead.
- "BAR-L1 unchanged" references a probe that does not exist; either drop the claim or add the pairwise `.rz-name` colour/font distinctness probe (ZG-13 needs it too — define once).

**REJECT ZG-12 — the painted-before-scroll oracle depends on Firefox/WebKit that are not installed and on an unspecified pixel threshold; the pre-line oracle breaks on `line-height: normal`; "BAR-L1 unchanged" cites a probe that does not exist.**

## ZG-13 — Self-host first-party theme fonts so a résumé page never calls jsDelivr

`no-third-party` (request log only loopback hosts while cycling and printing) and the `jsdelivr` grep are exact and are the persona complaint. The remaining runtime ACs cannot fail:
- `document.fonts.check('12px "EB Garamond"')` returns `true` when no matching face needs loading — it is `true` on a page with no `@font-face` at all. Use `await document.fonts.ready` then `[...document.fonts].some(f => f.family === 'EB Garamond' && f.status === 'loaded')`.
- With `local("…")` first in `src`, a machine that has EB Garamond installed issues no `/themes/fonts/` request, so "at least one `/themes/fonts/` request returned 200" is machine-dependent. Instead: parse every `url()` inside `@font-face` blocks of `themes/*.css`, `fetch` each against the served origin, assert `200` and `Content-Type: font/woff2`, and assert the file exists under `dist/themes/fonts/`.
- `fallback`: "`.rz-name` computed `font-family` still resolves" is not falsifiable — the computed value is the declared family string whether or not it loaded. Replace with: no console error, S2 date-geometry green, `.rz-name` height > 0 with fonts aborted.
- "BAR-L1 pairwise distinctness probe still passes" — no such probe exists. Add it here (or in ZG-12; define once): for each pair of first-party themes, `.rz-name` computed colour or `font-family` differs. Self-hosting is exactly the change that can regress all three to the same fallback.
- A font swap can reflow print; assert `U3_PRINT_PAGES` unchanged (or state the new constants).
- `OFL.txt` per family and the README sentence are grep-able; fine.

**REJECT ZG-13 — `document.fonts.check` and "computed font-family still resolves" are oracles that cannot fail, `local()` makes the request-count AC machine-dependent, and "BAR-L1 still passes" cites a probe that does not exist; replace with loaded-face status, direct fetch of every `@font-face` url, and add the pairwise probe.**

## ZG-14 — Serve and link the designer kit: sample HTML, contract, blank CSS, second sample

Every AC is an HTTP status, a header, or a substring: the four 200s and the BAR-T2 404 via `curl`, `text/markdown`, `no preview.css` plus `.rz-name` visible, `_blank.css` excluded from the catalog (existing static probe), and BAR-D1 that prints `PENDING ZG-18` and can never print `PASS` before the submit link exists — an honest, non-theatrical bar probe. A stub that copies `example.html` unmodified fails the `preview.css` negative.

Non-blocking: `ZG-14/designer-links` fetches `https://github.com/…` → `just verify` now needs internet; assert `href` equality for the external link and fetch only same-origin assets. Also assert `Content-Type` for `/themes/README.md`, and run the 200/404 checks in `probes.mjs` (not only by hand) so they gate `just verify`.

**BLESS ZG-14 — statuses, headers, and substrings are the ACs; the BAR-D1 probe is wired to print `PENDING` until the submit link exists, so it cannot pass early.**

## ZG-15 — Try a local CSS file in the real switcher without a build

The fixture is specified (`Name: Local Test`, `rz-target: both`, `.rz-name { color: rgb(1,2,3) }` on screen and `rgb(4,5,6)` in print) and every AC reads back something that cannot be faked without applying the sheet: `blob:` href, exact computed colours on screen and in print emulation, card text, S1 FOUC sampling reused, restore to Quarto and back, `<script>` and `.txt` rejections with distinct `[data-theme-error]` values, no `blob` in `location.search`.

Non-blocking: also assert the `theme` query param is unchanged after selecting the local card (a stub pushing `?theme=local` would pass `no-url-leak`); and after a reload the local card is gone with no console error (blob URLs do not survive).

**BLESS ZG-15 — computed-colour oracles on screen and in print emulation, explicit reject states, and FOUC sampling make every AC falsifiable and a stub that merely lists the file fails.**

## ZG-16 — Credit the Designer with name and link on every theme card

Exact card selector and text (`.theme-switcher__author`, `by ResumeZen`, `rel="noopener"`), a `parseTheme` unit test with the `javascript:` URL dropped, an explicit no-fake-byline negative, `_blank.css`/README greps, and a focus + no-select interaction check. The no-fake-byline probe implies a rebuild with a temporary theme in `themes/` (the catalog is build-time); that is implementation, but the probe must clean the temp file in `finally` so a failed run does not dirty the tree.

Non-blocking: pin `Author:` without `URL:` → `by Mika Tan` as plain text (no `<a>`); note that an `<a>` inside the `<button>` option is invalid HTML — the AC already permits a separate element.

**BLESS ZG-16 — card selector, byline text, link attributes, unit-tested header parsing with a `javascript:` negative, and an explicit no-byline case are all observable; a byline hard-coded for every card fails the no-fake-byline probe.**

## ZG-18 — Give Designers a visible submit path with a stated review turnaround

`test -f` plus exact strings for `CONTRIBUTING.md`, checkbox-per-item for the PR template (name the five strings the checkboxes must contain so two testers agree: `rz-`, `<script`, `paper`, `content:`, `License`), the sidebar link with exact `href` visible at 1280×800 without opening About, and BAR-D1 flipping from `PENDING` to `PASS` only now. Devon's walk-away is answered by things a grep and a probe can see.

Non-blocking: add `grep -n "PRs are open" ROADMAP.md` (scope item without AC); the link should also be reachable inside the ZG-9 sheet at 390px.

**BLESS ZG-18 — file existence, exact strings, a visible link with a pinned `href`, and the BAR-D1 PASS transition are all observable; nothing here can be marked done by a stub.**

## ZG-19 — Put the print-honesty rule, a full blank scaffold, and contract fixes where designers look

The derived oracle (extract §6 classes from `CLASS-CONTRACT.md` by regex, assert each is a selector in `_blank.css`) is the right idea. It breaks immediately on §6's templated tokens — `rz-contact--{type}`, `rz-link--{type}`, `rz-section--{id}` are listed as literal `{…}` and cannot appear as selectors. The AC must define expansion (enumerate the types from §5.2 and the ids from §4) or exclusion; otherwise the test is red or the tester writes the exclusion silently.

Further blockers:
- Test-order dependency: scope says `_blank.css` carries "the header fields from ZG-16/17", but ZG-19 depends on neither; ZG-16 also edits the `_blank.css` header, and ZG-20 (depends on ZG-19) warns on missing `Author:/URL:/License:`. Three PBIs edit one file's header with no order. Depend on ZG-16 (and ZG-17 once revised) or drop the line.
- Scope items with no AC: the §2 fonts sentence ("any https origin, self-hosted preferred; JavaScript loaders forbidden") and the `content:` rule "stated once in §2 and referenced (not restated) by `themes/README.md`" — add greps (`any https origin` in the contract; the README references `§2` and does not contain a second rule text).
- "leaves `Jordan Hale` readable (unstyled but visible)" → `.rz-name` `isVisible()`, non-empty text, zero console errors.
- `head -5 … Historical` and the `unless you mean to` negative grep are good.

**REJECT ZG-19 — the §6-derived selector test is undefined for templated tokens (`--{type}`, `--{id}`), `_blank.css` header fields depend on ZG-16/17 without a dependency, and the fonts sentence and `content:` single-statement rule have no AC.**

## ZG-20 — Ship `npm run lint-theme` so a Designer knows pass or fail before opening a PR

Unit cases are named with expected error codes, the bad fixture must exit 1 with line numbers, and the probe meta-test (`themes/zz-bad.css` present → `probes.mjs` exits 1) is a real anti-stub. Two rules are under-specified in ways that make AC 1 and AC 2 contradict each other:
- **Selector allowlist.** As written ("a selector outside `html`, `body`, `.rz-*`, `[data-rz-*]`, pseudo") flags `.rz-resume a`, `.rz-summary p`, `.rz-prose p`, `.rz-resume a:focus-visible` — all present in the first-party files that AC 1 says exit 0. Define the rule for complex selectors: every complex selector must contain at least one `html`/`body`/`.rz-*`/`[data-rz-*]` compound; type selectors and pseudo-classes/elements are allowed only in a selector that has one; any non-`rz-` class or any `#id` anywhere is an error. Pin with unit cases: `.rz-resume a{}` pass, `a{}` fail, `li{}` fail, `.rz-resume .btn{}` fail, `#root{}` fail.
- **`content:` letters rule.** Confirmed as an acceptable proxy for BAR-X2 (first-party values `""`, `" "`, `", "`, `": "`, `" · "`, `"– "` all pass; a résumé word cannot be fewer than three letters in practice) **provided** "letter" is Unicode `\p{L}` (`content: "名前"` must fail) and the print-footer case `content: "Page " counter(page)` is decided and unit-tested (error or warning — either is fine, but pick). Add both cases.
- `bad-theme.css`: name the three errors it combines and the expected line numbers, so "prints each error with a line number" is a fixed expectation.
- `print-ink`: cover `background-color:` as well as `background:`; state that `var(--x)`/unresolvable values produce a warning, not silence.
- Exit-code contract: errors → 1, warnings only → 0; state it (AC 1 says "0 errors", not the exit code for warnings).

**REJECT ZG-20 — the selector rule as written flags first-party `.rz-resume a`/`.rz-summary p` and contradicts "first-party exit 0"; define complex-selector semantics with pass/fail unit cases, pin `\p{L}` and the `"Page " counter(page)` decision for the `content:` rule, name the bad fixture's three errors, and state the warnings exit code.**

## ZG-21 — Publish a résumé to a stable public URL with an unguessable edit link (API)

The shape is right for a backend PBI: named cargo tests, `:memory:` store, status codes for 413/400/422/404/410, an id regex, a hash check by direct SQL read, 1,000-id distinctness, static serving, clippy pedantic and an `anyhow` grep. Missing negative and privacy cases the domain plainly has:
- The two headers that *are* Priya's privacy answer — `Cache-Control: no-store` and `X-Robots-Tag: noindex` on `GET /r/{id}` — are in scope and in no AC. Assert both on 200 and on 410.
- Authz denial is tested for `GET` JSON only. Add: `PUT` and `DELETE` with wrong/absent key → 404 and the row unchanged; `PUT` on a deleted id → 404.
- `PUT` validation: `{`, theme `banana`, missing name → same 400/422 as POST.
- Malformed ids: `/r/AAAAAAAAAA` (uppercase), `/r/abc`, `/r/aaaaaaaaaa/../x` → 404, never 500.
- Edit-key entropy: 1,000 POSTs yield 1,000 distinct `edit_key`s (ids are covered; keys are the secret).
- Contract §1.8: POST a résumé with `meta.x-custom` and an unknown top-level key; `GET` with key returns them verbatim.
- Public page purity: assert the `/r/{id}` HTML contains no `theme-switcher`, `garden`, or `<link` other than the theme link.
- Size boundary: exactly 1 MB → 201; 1 MB + 1 byte → 413.
- Local run: name the exact command and env for personas (`just serve` → backend binary, default DB path, `PORT`), and that `frontend/dist` missing produces a clear startup error, not a 404 storm.

**REJECT ZG-21 — `no-store`/`noindex` headers (the privacy promise) have no AC, wrong-key denial is tested on GET only (not PUT/DELETE), malformed ids and PUT validation are untested, edit-key distinctness is not asserted, and unknown-key round-trip (§1.8) is unverified.**

## ZG-22 — Publish, copy your link, delete — with plain answers to who can see it

Probes are concrete (publish → `/r/[a-z2-7]{10}$` fetched and checked, edit link in a fresh context, update flips the theme on the public page, delete → 410, sample disabled, download deep-equals, trust copy substrings, `unavailable` within 3 s with no uncaught error, wrong key → `edit-denied`, round-0 keyword scan flips to true). The gaps are in the failure and repeat paths, which is where a Publish button earns trust:
- **Evidence may not be `SKIPPED`.** The last AC allows probes to print `SKIPPED: backend not built`. ZG-21 is a dependency; for ZG-22's own DoD the publish probes must have printed `PASS`. State it; otherwise this PBI can be "done" with its core untested.
- **Publish twice.** Define it: second click on the same loaded Resume updates the same id (no new page) or the button becomes Update after publish. Priya will click it twice.
- **API errors that are not "unreachable".** 413 (too large), 422 (missing name), 5xx → `[data-publish-state="error"]` with a plain sentence, no spinner, no console error. Today only `unavailable` is specified.
- **Delete cancel.** Cancelling the confirmation leaves `published` state and the public page 200.
- **Key exposure.** The edit link puts the key in `?edit=id:key`. Add an AC on where the key may travel: only in the `Authorization` header (request-log assertion: no request URL contains the key), and `location` is rewritten (`history.replaceState`) so the key is not left in the address bar/history after load — or adopt the PO's fragment form, which the CTO will weigh.
- **Tampered stored key.** Edit `localStorage['resumezen.published']` to a wrong key, click Update → `edit-denied`, public page unchanged.
- Non-blocking: `Download my JSON` filename (`<name>.resume.json`) and MIME `application/json`; a Copy button for the one-time edit link (PO).

**REJECT ZG-22 — the DoD permits `SKIPPED` evidence for the core probes, and publish-twice, non-network API errors (413/422/5xx), delete-cancel, key-in-URL exposure, and tampered-key Update are unspecified — the failure paths a Publish control must survive.**

---

## Summary

| id | verdict | one-line reason |
| --- | --- | --- |
| ZG-1 | REJECT | AC 5 contradicts the DoD; fixed test count |
| ZG-2 | BLESS | exact I/O pairs incl. named panic regression |
| ZG-3 | REJECT | bad-URL/no-username outcome unspecified; publications, integer score |
| ZG-4 | REJECT | byte-lock against `example.html` is unsatisfiable (verified) |
| ZG-5 | REJECT | PDF fixture, drop zone, render-`Err` class, serde-token ban, corrupt storage |
| ZG-7 | REJECT | `one-print` contradicted by retained "Print preview" |
| ZG-8 | REJECT | clipboard failure, `/?theme=` no-notice, escaping |
| ZG-9 | BLESS | viewport geometry + ARIA transitions |
| ZG-11 | REJECT | PDF rasterisation tooling absent; U3 walk-bar contradiction; fixture never proven to trip E1 |
| ZG-12 | REJECT | Firefox/WebKit not installed; pixel threshold undefined; phantom BAR-L1 |
| ZG-13 | REJECT | `fonts.check`/font-family oracles cannot fail; `local()` flake; phantom BAR-L1 |
| ZG-14 | BLESS | statuses, headers, honest BAR-D1 PENDING |
| ZG-15 | BLESS | computed-colour oracles on screen and print |
| ZG-16 | BLESS | card selector, unit-tested header parse, no-fake-byline negative |
| ZG-18 | BLESS | files, strings, visible link, BAR-D1 PASS transition |
| ZG-19 | REJECT | templated §6 tokens; unstated ZG-16/17 dependency; scope without AC |
| ZG-20 | REJECT | selector rule contradicts first-party exit 0; `content:` rule cases unpinned |
| ZG-21 | REJECT | `no-store`/`noindex` untested; wrong-key on PUT/DELETE; malformed ids; key entropy |
| ZG-22 | REJECT | `SKIPPED` allowed; publish-twice, API errors, delete-cancel, key exposure |

6 BLESS, 13 REJECT.

## Set-level notes for the Generator

### Shared fixtures — define once, name the owner

`frontend/fixtures/` does not exist. Create it in the first PBI that needs it and reference the same files everywhere:

| File | Content (must be in the owning PBI) | Used by |
| --- | --- | --- |
| `frontend/fixtures/ada.json` | `{"basics":{"name":"Ada Lovelace"}}` | ZG-4, ZG-5, ZG-21, ZG-22 |
| `frontend/fixtures/trailing-comma.json` | `{"basics":{"name":"Elena",}}` (already specified in ZG-5) | ZG-5, ZG-21 (400 shape) |
| `frontend/fixtures/not-a-resume.pdf` | minimal `%PDF-1.4` … `%%EOF` bytes (specify) | ZG-5 |
| `frontend/fixtures/long-resume.json` + `.html` | fictional senior engineer per ZG-11; the `.html` must be regenerated and diffed by a cargo test or the `render` example | ZG-11, ZG-4 parity, ZG-21 size tests, ZG-12 name-fits |
| `frontend/fixtures/local-theme.css` | as specified in ZG-15 | ZG-15 |
| `frontend/fixtures/bad-theme.css` | three named errors with line numbers | ZG-20 |
| `renderer/tests/wild.rs` | ZG-2 creates, ZG-3 appends (say so in both) | ZG-2, ZG-3 |
| Crate reference output | a `renderer/examples/render.rs` (stdin JSON → stdout HTML) or a cargo test that writes to `renderer/target/`; **not** `skeleton/example.html`, which is hand-maintained and not byte-identical | ZG-4, ZG-11 |

### Probe naming and evidence conventions

- Lines are `PASS  ZG-n/<slug>` / `FAIL  ZG-n/<slug> <reason>`; BAR ids print `BAR-xx PASS|FAIL|PENDING ZG-n`.
- A PBI's own ACs are never `SKIPPED`. A missing prerequisite (browser, rasteriser, backend, fixture) prints `FAIL ZG-n/<slug> prerequisite missing: <what>`.
- Phantom probes: **there is no BAR-L1 probe**. ZG-12 and ZG-13 both claim it "still passes"; one of them must add it (pairwise `.rz-name` colour/font-family distinctness), the other references it.
- `U3_PRINT_PAGES` is the print walk bar and is asserted with `!==`. Any PBI that can change page counts (ZG-11 breaks, ZG-13 fonts) states the new exact constants.
- Text probes on the chrome: use `textContent` or case-insensitive matching — `innerText` applies `text-transform` and the round-0 "CHROME" heading is almost certainly uppercased by CSS.
- Keep `just verify` offline: assert external `href`s by string equality, never `fetch` GitHub.

### Tooling facts that gate several ACs

- Only Chromium is installed for Playwright. Any AC naming Firefox/WebKit must state the install step and fail (not skip) without it.
- Nothing in the repo can rasterise a PDF or decode a PNG. PDF pixel oracles need a named tool (system `pdftoppm` or a `pdf.js` dev dependency — both need human approval); screenshot pixel oracles can use an in-page `<canvas>` without a dependency but must state a threshold.
- `document.fonts.check()` and computed `font-family` are not load oracles; use `FontFace.status === 'loaded'` and direct `fetch` of `@font-face` URLs.

### Test-order dependencies to make explicit

- `_blank.css` header is edited by ZG-16, ZG-19 (and ZG-17 once revised) and linted by ZG-20 → ZG-19 must depend on ZG-16 (and ZG-17) or drop the "header fields from ZG-16/17" line.
- ZG-2 and ZG-3 share `renderer/tests/wild.rs`.
- ZG-22 evidence requires the ZG-21 backend running on `PROBE_PORT+1`; say so in the AC and forbid `SKIPPED`.
- ZG-11 and ZG-13 both move print page counts; whichever lands second re-baselines `U3_PRINT_PAGES` again.
