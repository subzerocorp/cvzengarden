# AVRIL round 1 — Generator revise pass (cycle 3, after QA Architect)

**Generator:** `planning-architect-agent` · **Date:** 2026-08-23 · **Board:** Pinto `ZG` (labels `avril`, `round-1`)
**Inputs read in full:** `docs/plans/round-1-avril-qa-round1.md` (every REJECT section and the set-level notes), `docs/plans/round-1-avril-intent.md`, `docs/plans/round-1-avril-generator-round2.md`, `pinto show ZG-1 ZG-3 ZG-4 ZG-5 ZG-7 ZG-8 ZG-11 ZG-12 ZG-13 ZG-19 ZG-20 ZG-21 ZG-22 --plain` (rejected), `pinto show ZG-2 ZG-9 ZG-14 ZG-15 ZG-16 ZG-18 --plain` (QA-blessed, kept consistent), plus `frontend/scripts/probes.mjs`, `skeleton/CLASS-CONTRACT.md` §2/§4/§5.2/§6, `themes/*.css` `@page` and break rules, `themes/_blank.css` header, `frontend/scripts/serve.mjs`, `justfile`, `renderer/src/lib.rs`, `renderer/tests/acceptance.rs`.

Only the QA blockers were applied, plus the set-level fixture / probe conventions where a rejected item references a shared fixture. QA-blessed bodies (ZG-2, ZG-9, ZG-14, ZG-15, ZG-16, ZG-18) are untouched. ZG-6, ZG-10, ZG-17 (with QA concurrently) are untouched; ZG-17 gains a dependent (ZG-19) but its own body and deps are unchanged. Nothing is BLESSed by this document.

## Facts verified before writing AC

| Fact | How | Used by |
| --- | --- | --- |
| `cd renderer && cargo test`: 10 unit + 9 acceptance tests green; `acceptance.rs` compares normalised trees (`assert_resume_trees_eq`), not bytes — so `skeleton/example.html` is not a byte oracle for crate output (QA's byte-311 finding stands). | ran it | ZG-1 (count ≥ 19), ZG-4 (no `example.html` parity) |
| `~/Library/Caches/ms-playwright` holds Chromium + headless shell + ffmpeg only; no Firefox/WebKit. | `ls` | ZG-12 |
| `pdftoppm` 25.06 (poppler) is at `/opt/homebrew/bin/pdftoppm`; `mutool`, `magick`, `convert` absent. `rsvg-convert` present (irrelevant). | `which`, `pdftoppm -v` | ZG-11: **not** required — geometry oracle chosen; named in `scope_out` as an available-but-not-prerequisite tool |
| `probes.mjs` prints `PASS  <msg>` / `FAIL  <msg>` (two spaces) via `pass()`/`fail()`; `countPdfPages` regexes `/Type /Page`; `U3_PRINT_PAGES = {nightgarden: 2, quarto: 3, switchyard: 3}`; the View toggle is `getByRole('button', {name: 'Print preview'})`; there is no BAR-L1 probe. | read | ZG-7, ZG-11, ZG-12, ZG-13, naming convention |
| `@page` margins: Quarto Letter `0.55in 0.7in 0.6in`, `:first` top `0.48in`; Switchyard A4 `14mm 16mm 16mm`; Nightgarden Letter `0.36in 0.5in 0.28in`. | grep | ZG-11 printable heights (952 / 1009 / 995 px) |
| `serve.mjs` already maps `.woff2` → `font/woff2`. | grep | ZG-13 |
| Contract §6 templated tokens are exactly `rz-contact--{type}` and `rz-link--{type}`; section modifiers are literal. §5.2 lists 5 contact types and 11 profile modifiers. | read | ZG-19 expansion table |
| `_blank.css` header today: `Name`, `Author`, `License`, `rz-target` (no `URL`). | read | ZG-19 header AC (5 fields, after ZG-16) |
| `renderer/examples/` and `frontend/fixtures/` do not exist. | `ls` | every fixture owner below |
| `ports.js` preserves `url.hash` when pushing `?theme=` (line 205). | grep | ZG-22 fragment edit link |
| `render_json(json) -> Result<String, serde_json::Error>` is the public entry; `Display` of the error contains `line N column M`. | read `lib.rs` | ZG-4 example stderr AC |

---

## Shared-fixture ownership (defined once; consumers reference and depend on the owner)

| Fixture path | Content (in the owner's body) | Owner | Consumers (and how they depend) |
| --- | --- | --- | --- |
| `frontend/fixtures/ada.json` | `{"basics":{"name":"Ada Lovelace"}}` | **ZG-4** | ZG-5 (depends on ZG-4), ZG-22 (depends on ZG-5 → ZG-4). ZG-21 keeps its inline `{"basics":{"name":"Ada"}}` in Rust tests — no dep added |
| `renderer/examples/render.rs` (crate reference oracle: stdin JSON → stdout HTML, exit 1 + stderr on `Err`) | spec in body; cargo test `example_render_matches_render_json` | **ZG-4** | ZG-4 only. ZG-11 does not consume it (its fixture lock is a cargo test, below), so no ZG-11 → ZG-4 dependency and the Author chain (ZG-1 → ZG-4 → ZG-5) stays free of print work |
| `frontend/fixtures/trailing-comma.json` | `{"basics":{"name":"Elena",}}` | **ZG-5** | ZG-5 only (ZG-21's 400 case uses inline `{`) |
| `frontend/fixtures/not-a-resume.pdf` | exact bytes `%PDF-1.4 … %%EOF` (5 lines, in body) | **ZG-5** | ZG-5 |
| `frontend/fixtures/long-resume.json` + `.html` | senior-engineer résumé spec (4 work × 4–6 highlights, 2 volunteer, 2 education, 2 awards, 6 skill groups, 3 projects); `.html` = exact `render_json` output, locked by `renderer/tests/fixtures.rs::long_resume_html_is_crate_output`, regenerated with `RZ_UPDATE_FIXTURES=1` | **ZG-11** | ZG-11 only. ZG-12 name-fits sets `.rz-name.textContent` in the probe; ZG-4 large-input builds a ≥ 4.8 MB document in the probe; ZG-21 size boundary pads `basics.summary` in the test — none needs the file, so no cross-deps |
| `frontend/fixtures/local-theme.css` | as specified in ZG-15 (unchanged) | **ZG-15** | ZG-15 |
| `frontend/fixtures/bad-theme.css` | exactly five lines (in body): `rz-target` header, `Name`, `.theme-switcher{}`, `.rz-name::after{content:"Jordan Hale"}`, `@media print{body{background:#000}}` → errors `selector`@3, `content`@4, `print-ink`@5 | **ZG-20** | ZG-20 |
| `renderer/tests/wild.rs` | created by ZG-2 (its AC already names `cargo test --test wild`) | **ZG-2** (body untouched) | ZG-3 appends — **ZG-3 now depends on ZG-2** |
| `BAR-L1` probe (pairwise `.rz-name` colour / font-family distinctness) | in body | **ZG-13** | ZG-12 drops its "BAR-L1 unchanged" claim (scope_out says why) |
| `U3_PRINT_PAGES` (+ new `LONG_PRINT_PAGES`) | re-baselined to `{nightgarden: 2, quarto: 2, switchyard: 2}`; `LONG_PRINT_PAGES` exact, every value ≤ 3 | **ZG-11** | ZG-13 asserts its diff does not touch the constants |

## Probe naming and evidence conventions adopted (in every revised body)

- Lines are `PASS  ZG-n/<slug>` / `FAIL  ZG-n/<slug> <reason>` (matching the existing `pass()`/`fail()` helpers); BAR ids print `BAR-xx PASS|FAIL|PENDING ZG-n`.
- A PBI's own probes are never `SKIPPED`. A missing prerequisite prints `FAIL  ZG-n/<slug> prerequisite missing: <what>` (ZG-4 cargo example, ZG-22 backend).
- Chrome text probes use `textContent` or case-insensitive matching, never `innerText` (ZG-5, ZG-7, ZG-8, ZG-22).
- `just verify` stays offline: external `href`s are asserted by string equality (ZG-7); no GitHub fetch.
- Clipboard probes state `context.grantPermissions(['clipboard-read','clipboard-write'])` (ZG-8, ZG-22).
- Tooling: no AC requires Firefox/WebKit, PDF rasterisation, or a PNG decoder. Screenshot pixel checks use an in-page `<canvas>` with a stated threshold (ZG-12).

---

## Per-item: QA blocker → exact AC change

### ZG-1
| QA blocker | Change |
| --- | --- |
| AC 5 ("diff touches only `renderer/`") contradicts DoD (`progress.md`/`features.json` must change) | AC 5 → `git diff --name-only -- . ':!progress.md' ':!features.json'` lists only `renderer/` paths; the tracking files are named as the sole exception |
| AC 4 "same 19 tests" breaks when ZG-2/3 add tests | AC 4 → `0 failed` in every binary, no test removed (`cargo test -- --list` names preserved), total ≥ 19 |
| (wording) scope said "byte-lock" | scope-in now says "tree-equality lock" (verified fact); no AC effect |

### ZG-3
| QA blocker | Change |
| --- | --- |
| Bad-URL/no-username profile unspecified; label-only `<li>` could pass | Scope: value would be empty → whole `.rz-link`/`.rz-contact` `<li>` omitted, and empty `.rz-links`/`.rz-contacts` wrapper omitted; new AC: `{"network":"Site","url":"https://"}` as the only profile emits no `<li class="rz-link` and no `<nav class="rz-links"`; `basics.url = "javascript:…"` emits no `rz-contact--url` |
| `.rz-link`/`.rz-contact` empty-node regex | New AC: `<li class="rz-(link\|contact)[^>]*>\s*(<span class="rz-(link\|contact)-label">[^<]*</span>\s*)?</li>` matches nothing over every fixture |
| `javascript:` + username shape unstated | AC pins `<span class="rz-link-value">marcus</span>` with no `href` in that `li` |
| Publications url-only has no AC | AC adds `{"publications":[{"url":"https://doi.example/10.1/x"}]}` → `<a class="rz-entry-primary-link" …>doi.example</a>` |
| Integer score | AC adds `"score":4` → `<p class="rz-score">GPA 4</p>` |
| Set-level: `wild.rs` shared with ZG-2 | Scope + AC say "appended to `renderer/tests/wild.rs` (created by ZG-2)"; **dep added ZG-3 → ZG-2** |
| Contract grep | §5.2 AC greps `omitted entirely` |

### ZG-4
| QA blocker | Change |
| --- | --- |
| Byte-lock against `skeleton/example.html` unsatisfiable | Probe renamed `ZG-4/wasm-parity`; reference is crate output produced in the same run via new `renderer/examples/render.rs` (spec in scope; cargo test `example_render_matches_render_json`); scope_out names `example.html` as a non-oracle with the byte-311 fact |
| Parity on more than Jordan | Parity inputs: `skeleton/resume.json`, `frontend/fixtures/ada.json`, inline timestamp-`releaseDate` document (a wild input that does not panic pre-ZG-2, so no new dep) |
| Module load failure | New `ZG-4/wasm-load-failure`: `**/*_bg.wasm` aborted → `render` rejects with a plain message containing `renderer`, no stack trace, no `pageerror`, sandbox still Jordan |
| Size bound | New `ZG-4/wasm-large`: ≥ 4.8 MB document built in the probe from Jordan's `work` entries → resolves in ≤ 5 s, last entry present, no `pageerror` |
| Set-level: `ada.json` owner | ZG-4 owns `frontend/fixtures/ada.json` (`Ada Lovelace`); swap probe uses it (`.rz-name` = `Ada Lovelace`) |
| Prerequisite convention | `FAIL  ZG-4/wasm-parity prerequisite missing: cargo example render` |

### ZG-5
| QA blocker | Change |
| --- | --- |
| PDF fixture unspecified | Scope defines `not-a-resume.pdf` bytes exactly (owner ZG-5); `trailing-comma.json` content restated as owner |
| Drop zone has no AC | `[data-drop-zone]` in scope; new `ZG-5/drop-json` and `ZG-5/drop-pdf` (DataTransfer drop) |
| Renderer `Err` after successful parse has no class | New class `render-failed` ("We could not draw this résumé"); new `ZG-5/render-failed` probe overrides `window.resumezen.render` to reject with a serde-looking message and asserts the class, `could not`, `.rz-name` unchanged, no `pageerror` |
| Serde-token ban only on one case | New `ZG-5/no-serde-tokens` applied after every error probe; ban list `expected`, `EOF`, `invalid type`, `serde`, `Err(`, `panicked` |
| File class boundary | Scope: content first, then extension; new `ZG-5/file-classes`: `.json` with trailing comma → `invalid-json` + `line 1`; `.txt` with valid JSON renders; `.txt` prose → `not-json-file` naming the file; `open-pdf` text must contain `not-a-resume.pdf` |
| Corrupt `localStorage` on reload | Scope: unparseable/unrenderable stored value discarded silently; new `ZG-5/corrupt-storage` (`{` and `{"basics":{"label":"x"}}`) → Jordan, no banner, no console error, key removed |
| Convention | `ZG-5/copy` uses `textContent`; Ada probes read `frontend/fixtures/ada.json`; dep line names ZG-4 as owner |

### ZG-7
| QA blocker | Change |
| --- | --- |
| `one-print` contradicted by retained "Print preview" toggle | Scope states the toggle keeps its name; scope_out says renaming is rejected (would break S4/U3 for no persona gain); `ZG-7/one-print` → exactly one button whose name starts with `Print /`, and `Print preview` still resolves to exactly one button |
| (non-blocking, applied as set convention) `innerText` vs `text-transform` | `ZG-7/no-jargon`, `badges`, `about`, `print-on-white` use `textContent`; heading check is "no heading whose `textContent` is `Chrome`/`CHROME`" |
| (non-blocking) print-honesty claim guard | `ZG-7/print-on-white` states S3/U3 probes are the guard and must be green in the same run |
| Offline convention | GitHub `href` asserted by string equality, never fetched |

### ZG-8
| QA blocker | Change |
| --- | --- |
| No clipboard-failure state | Scope: `[data-copy-state="failed"]` "Copy failed — select the address bar and copy it", never `Copied`; new `ZG-8/copy-failed` with `navigator.clipboard.writeText` overridden via `addInitScript` to reject (deterministic, headless-safe) |
| `/?theme=` no-notice in scope but not AC | `ZG-8/no-notice` covers `/?theme=Quarto`, `/`, and `/?theme=` |
| Echoed theme name escaping | New `ZG-8/notice-escaped`: `/?theme=%3Cb%3Ex%3C%2Fb%3E` → literal `<b>x</b>` in `textContent`, `querySelector('b')` null; scope says Elm `text` |
| Probe mechanics | `ZG-8/copy-link` states `context.grantPermissions([...])`; copied state is `[data-copy-state="copied"]` |

### ZG-11
| QA blocker | Change |
| --- | --- |
| Fill-ratio / pixel probes need PDF rasterisation the toolchain lacks | Oracle replaced by print-emulated geometry: helpers `printableHeightPx(theme)` (from `@page`: 952 / 1009 / 995 px) and `paginate(frame, h)` (greedy pagination over atomic blocks = outermost `break-inside: avoid` elements, else leaf blocks, honouring `break-before: page`). `pdftoppm` is installed locally but is named in scope_out as *not* a prerequisite; no AC uses pixels |
| AC 2 contradicts `U3_PRINT_PAGES` | Scope + `ZG-11/page-count`: `U3_PRINT_PAGES` re-baselined to exact `{nightgarden: 2, quarto: 2, switchyard: 2}`; new `LONG_PRINT_PAGES` exact constants for the fixture, every value ≤ 3, asserted with `!==`; S3/U3 green against them |
| Fixture never proven to trip E1 | New `ZG-11/fixture-trips-e1`: `#rz-experience` height > printable height under Quarto and Switchyard in print emulation |
| Fixture provenance | `long-resume.html` locked by cargo test `renderer/tests/fixtures.rs::long_resume_html_is_crate_output` (byte equality; `RZ_UPDATE_FIXTURES=1` regenerates); test also counts 4 experience / 3 project / 2 education entries and ≥ 16 bullets |
| Print-ink checks one of four selectors | `ZG-11/print-ink` asserts all four (`.rz-entry-secondary`, `.rz-location`, `.rz-dates`, `.rz-meta`) ≥ 4.5:1 |
| "Quarto and Nightgarden unchanged" not falsifiable | `ZG-11/bullets-print` runs the same marker assertion on all three themes: content/list-style present **and** inked (glyph colour ≥ 4.5:1, or bar with width/height > 0, background ≥ 4.5:1, `print-color-adjust: exact`) |
| `entry-intact` assumption unstated | Uses `paginate` output (same oracle as `page1-fill`), states it is an approximation, adds "no atomic block taller than the page" |
| Fixture loading mechanism | Scope states the probe swaps `article.rz-resume` in the sandbox `contentDocument` |

### ZG-12
| QA blocker | Change |
| --- | --- |
| `painted-before-scroll` needs Firefox/WebKit (not installed) | Split into `ZG-12/rise-css-structure` (static: hidden start state only inside `@supports (animation-timeline: view())`) and `ZG-12/painted-without-support` (Chromium: strip the `@supports` block from the fetched sheet, inject as `<style>`, assert `#rz-volunteer`/`#rz-projects` opacity `1`, `getAnimations()` empty). Scope_out: installing Firefox/WebKit is a human decision; no AC needs them |
| Pixel threshold undefined | `ZG-12/painted-with-support`: full-page screenshot decoded via `createImageBitmap` + `<canvas>`; ≥ 200 pixels in `#rz-projects` differ from body background by > 32 in any channel; plus `innerText` contains the Projects heading (Cmd-A oracle) |
| `pre-line` breaks on `line-height: normal` | `ZG-12/pre-line` compares against a single-line sibling bullet (≥ 2.5 × its `clientHeight`) |
| "BAR-L1 unchanged" is a phantom | Claim dropped; scope_out says ZG-13 owns the probe and nothing here touches `.rz-name` colour/font |
| Name injection | `ZG-12/name-fits` states the probe sets `.rz-name.textContent` (no fixture, no ZG-11 dep) |

### ZG-13
| QA blocker | Change |
| --- | --- |
| `document.fonts.check` cannot fail | `ZG-13/fonts-load`: `await document.fonts.ready` then a `FontFace` with the family and `status === 'loaded'` for EB Garamond / IBM Plex Sans / Syne under their themes; `fonts.check` explicitly not used |
| `local()` makes the request-count AC machine-dependent | Replaced by `ZG-13/font-files`: parse every `url()` in every `@font-face` block, fetch each → 200 + `font/woff2`, file exists under `dist/themes/fonts/`, list non-empty |
| "computed `font-family` still resolves" cannot fail | `ZG-13/fallback`: fonts aborted → no console error/`pageerror`, `.rz-name` height > 0, S2 date geometry green, no horizontal overflow |
| "BAR-L1 still passes" is a phantom | ZG-13 **owns** the `BAR-L1` probe (pairwise `.rz-name` colour or font-family differs; prints `BAR-L1 PASS`) |
| Font swap can reflow print | AC: this PBI's diff does not touch `U3_PRINT_PAGES`/`LONG_PRINT_PAGES` and the S3/U3 page-count probes are green; scope_out: a reflow sends the PBI back to planning rather than editing constants |

### ZG-19 (re-checked against the cycle-1b body)
| QA blocker | Change |
| --- | --- |
| §6-derived test undefined for `--{type}` / `--{id}` tokens | Scope defines the expansion table (contact: 5 types; link: 11 modifiers; section modifiers are already literal in §6); node test `frontend/scripts/blank-theme.test.mjs` applies it, drops `data-rz-*` from the class check, and fails on any `{` token not in the table |
| `_blank.css` header fields from ZG-16/17 without a dependency | **Deps added ZG-19 → ZG-16, ZG-19 → ZG-17**; scope says this PBI edits the header last; AC asserts the five header fields (`Name`, `Author`, `URL`, `License`, `rz-target`) each exactly once |
| Fonts sentence and `content:` single-statement rule have no AC | New greps: `any https origin` and `JavaScript loaders forbidden` in §2; `never only in` exactly once in the contract; README contains neither `never only in` nor `résumé words` and does reference `§2` |
| "readable (unstyled but visible)" | `ZG-19/blank-readable`: `.rz-name` `isVisible()`, `textContent` `Jordan Hale`, zero console errors/`pageerror`s |
| Still applies from 1b (kept) | `contract.json`/`contract.html` lock, superset assertion, `Historical` banner, `unless you mean to` negative grep |

### ZG-20
| QA blocker | Change |
| --- | --- |
| Selector rule flags first-party `.rz-resume a` etc. | Rule redefined: each comma-separated complex selector needs ≥ 1 compound on `html`/`body`/`.rz-*`/`[data-rz-*]`; type selectors and pseudos allowed in such a selector; any non-`rz-` class or `#id` anywhere is an error. Unit cases: `.rz-resume a{}`, `.rz-summary p{}`, `.rz-resume a:focus-visible{}`, `html{}`, `body{}` pass; `a{}`, `li{}`, `.rz-resume .btn{}`, `#root{}`, `.theme-switcher{}`, `.rz-name, .btn{}` fail |
| `content:` letter = `\p{L}`; `"Page " counter(page)` undecided | Letters are `\p{L}{3,}` (`"名前"` fails). Decision: a letter-run in the same value as `counter()`/`counters()` is a **warning** `content-counter` (human reviewer decides), not an error; `content:"Page"` alone is an error. Both unit-tested |
| `bad-theme.css` errors and line numbers unnamed | Fixture is exactly five lines (content in scope); errors `selector`@3, `content`@4, `print-ink`@5; CLI AC asserts the three `bad-theme.css:<n> error <code>` lines and `3 errors` |
| `print-ink` must cover `background-color`; `var()` must not be silent | Rule covers both properties; unresolvable values → warning `print-ink-unresolved`; unit cases for `background-color:rgb(10,10,10)`, `color-scheme: light` exemption, and `var(--ink)` |
| Exit-code contract for warnings | Scope + AC: errors → 1, warnings only → 0 (`0 errors, 1 warning` case); output format pinned |

### ZG-21
| QA blocker | Change |
| --- | --- |
| `no-store`/`noindex` in scope, no AC | New `public_page_headers_and_purity`: both headers on 200 and on 410; body has exactly one `<link`, no `theme-switcher`/`garden`/`<iframe` |
| Wrong-key denial tested on GET only | New `put_and_delete_require_key`: PUT/DELETE absent or wrong key → 404, row unchanged (public page still Jordan/quarto); PUT on deleted id → 404 |
| PUT validation | New `put_validates_like_post`: `{` → 400, `banana` → 422, missing name → 422, 1 MiB + 1 → 413, page unchanged after each |
| Malformed ids | New `malformed_ids_are_404`: uppercase, short, 11-char, traversal, `/api/resumes/abc` → 404 never 500, zero store calls |
| Edit-key entropy | `ids_and_keys_unguessable`: 1 000 distinct ids **and** 1 000 distinct keys |
| §1.8 round trip | New `unknown_keys_round_trip` (`meta.x-custom`, top-level `x-vendor`); scope says `resume_json` stored verbatim |
| Size boundary | `rejects_bad_input`: exactly 1 MiB → 201; 1 MiB + 1 byte → 413 (1 048 576 bytes stated) |
| Local run command, missing `dist` | Scope: `just serve` runs the backend with `PORT`/`RESUMEZEN_DB`; new `missing_dist_is_a_clear_error` (exit non-zero, stderr names `frontend/dist` and `npm run build`); README AC lists the env vars and `curl /` returns the Garden |
| Key hygiene (ZG-22 dependency) | Scope: key accepted only in `Authorization`; new `key_only_in_header` (query-string keys → 404) |

### ZG-22
| QA blocker | Change |
| --- | --- |
| DoD permits `SKIPPED` | Scope: `probes.mjs` starts the ZG-21 backend on `PROBE_PORT + 1` with `RESUMEZEN_DB=:memory:`; failure prints `FAIL  ZG-22/<slug> prerequisite missing: backend`; final AC requires every `ZG-22/*` line to be `PASS` and states there is no `SKIPPED` |
| Publish twice | Scope: button becomes `Update`, re-uses the id via PUT; new `ZG-22/publish-twice` (one PUT, no second POST, URL unchanged) |
| Non-network API errors | Scope: `[data-publish-state="error"]` with cause sentence; new `ZG-22/api-errors` (route-fulfilled 413/422/500 → `too large` / `name` / `try again`, no spinner, no `pageerror`); `unavailable` also asserts no `pending` remains |
| Delete cancel | Scope: in-chrome confirmation with a cancel control; new `ZG-22/delete-cancel` (state stays `published`, public URL 200) |
| Key exposure in `?edit=` | Adopted the fragment form `/#edit={id}:{key}` (never sent to the server; `ports.js` already preserves `hash`), `history.replaceState` clears it after load, key only in `Authorization`; `edit-link` asserts the link shape and `location.hash === ""`; new `ZG-22/key-never-in-url` (request log); scope_out rejects the query form with the reason. `wrong-key` probe now opens `/#edit={id}:wrongkey` |
| Tampered stored key | New `ZG-22/tampered-key` → `edit-denied`, public page unchanged |
| Convention | Ada paste uses `frontend/fixtures/ada.json`; `trust-copy` uses `textContent`; clipboard permissions stated |

---

## Updated dependency graph (delta only)

- Added: `ZG-3 → ZG-2` (owner of `renderer/tests/wild.rs`).
- Added: `ZG-19 → ZG-16`, `ZG-19 → ZG-17` (`_blank.css` header order). Designer chain is now `ZG-16 → ZG-17 → {ZG-18, ZG-19} → ZG-20`.
- No other edge changed. Graph verified acyclic (below). Ready-at-start set: ZG-1, ZG-7, ZG-8, ZG-9, ZG-11, ZG-12, ZG-13, ZG-15, ZG-16 (ZG-3 and ZG-19 leave it; nothing else moves).

## Changed ids

Every PBI whose body or deps changed in this pass (prior blessings invalidated; full PO → QA → CTO chain required):

- **ZG-1** — body (AC 4, AC 5)
- **ZG-3** — body (URL-hygiene omit rule, empty-node regex, `javascript:`+username shape, publications url-only, integer score, `wild.rs` append) and deps (+ZG-2)
- **ZG-4** — body (render example + `ada.json` owner, parity oracle, load-failure, large-input, swap uses `ada.json`)
- **ZG-5** — body (fixtures owned, drop zone, `render-failed`, serde-token ban, file classes, corrupt storage)
- **ZG-7** — body (`one-print` pinned to `Print /`, `textContent`, toggle name retained, offline href)
- **ZG-8** — body (copy-failed state, `/?theme=` no-notice, escaping, permissions)
- **ZG-11** — body (geometry oracle, fixture owner + cargo lock, E1 proof, exact page constants, four ink selectors, marker assertion on all themes)
- **ZG-12** — body (Chromium-only rise oracles, pixel threshold, sibling pre-line, BAR-L1 claim dropped, name injection)
- **ZG-13** — body (FontFace status, `@font-face` url fetch, fallback oracle, BAR-L1 owner, constants untouched)
- **ZG-19** — body (expansion table, header-field AC, fonts/`content:` greps, readable oracle) and deps (+ZG-16, +ZG-17)
- **ZG-20** — body (complex-selector rule, `\p{L}`, `content-counter` warning, five-line bad fixture, `background-color`/`var()`, exit codes)
- **ZG-21** — body (headers/purity, PUT/DELETE authz, PUT validation, malformed ids, key entropy, §1.8, size boundary, local run, header-only key)
- **ZG-22** — body (no `SKIPPED`, backend on `PROBE_PORT + 1`, publish-twice, API errors, delete-cancel, fragment edit link, tampered key)

Untouched: ZG-2, ZG-9, ZG-14, ZG-15, ZG-16, ZG-18 (carry their QA BLESS; ZG-2 and ZG-16/17 gain dependents only), ZG-6, ZG-10, ZG-17 (with QA).
