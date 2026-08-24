# AVRIL round 1 — Visionary CTO review (cycle 1)

**Role:** `visionary-cto-agent` (third and final adversary) · **Date:** 2026-08-23 · **Cycle:** 1
**Scope:** the 15 ids that carry a fresh PO BLESS and a fresh QA BLESS — ZG-1, ZG-2, ZG-3, ZG-4, ZG-5, ZG-6, ZG-7, ZG-8, ZG-9, ZG-10, ZG-14, ZG-15, ZG-16, ZG-18, ZG-22. The other seven (ZG-11, ZG-12, ZG-13, ZG-17, ZG-19, ZG-20, ZG-21) are with QA in cycle 5; I read their bodies for the whole-set view and the dependency graph and will review them in cycle 2. No verdict is emitted for them here.
**Inputs read in full:** `docs/plans/round-1-avril-intent.md` (locked decisions 1–12, repo facts, open questions), `ROADMAP.md`, `CONTEXT.md`, `qa/MARKET-QUALITY-BAR.md`, `AGENTS.md`, `round-1-avril-generator-round1.md` (design decisions 1–8), `round-1-avril-po-round3.md` and `round5.md`, `round-1-avril-qa-round1.md`, all 22 bodies (`pinto list --json`, `pinto show ZG-n --plain`), and the code shape I am protecting: `renderer/src/{lib,emit,resume,date,slug,html}.rs`, `frontend/src/Main.elm`, `frontend/static/ports.js`, `frontend/scripts/{generate,probes,serve}.mjs`, `backend/README.md`, `skeleton/CLASS-CONTRACT.md` §1, §3, §5, §8, §9, `justfile`, `renderer/Cargo.toml`.

Mandate: *BLESS only backlog items that advance a coherent two-year trajectory without irreversible entanglement; REJECT anything that buys short-term motion at the cost of future clarity.*

I ask only strategic questions. Product priority is PO's and is settled; AC detail is QA's and is settled. I do not rewrite bodies and I do not touch the board. Where I have guidance for the execution GAN that does not block an item, it is in the item's section as "Guidance for AXEL" and consolidated in the set-level notes; it is not an AC.

---

## Target shape (what every verdict is measured against)

In two years ResumeZen is: **one Skeleton** under a versioned Class Contract (`rz-*` 1.x, additive bumps only, no renames); **one Renderer** — a pure Rust crate with no I/O, compiled twice from the same source (a thin `renderer-wasm` for the Chrome's paste path, linked directly by the Axum API for hosted pages) and never re-implemented anywhere else; a **Chrome** in Elm holding all state and all calculations (`ThemeId`, error classes, view model), with a JavaScript port layer that is nothing but isolated actions (DOM in the sandbox, history, clipboard, storage, fetch, Wasm bridge) split by concern rather than one file; **Themes as files** — one self-describing `.css` per Theme whose header (`Name`, `Author`, `URL`, `License`, `rz-target`) is canonical metadata, with a build-time catalog today and a Store-backed catalog for accepted Submissions later that decodes to the same Elm `Theme` record; **one Store adapter** — libSQL locally, Turso in production, selected by environment, holding Theme metadata, Submissions and Author Resumes as verbatim JSON Resume (render on read, never stored HTML); a **Designer gate** that starts as a PR with a runnable lint and a human reviewer and later becomes a Submission with a review state in the Store, without changing what a Designer writes; and **Author identity** that starts as an unguessable edit key (a capability) and later gains Accounts and Payments layered *on top* of the capability model (an account claims a page by presenting its key), never by replacing the URL space or the table. `data-rz-schema` on the article is the only version a Theme ever sees. Everything a persona touches this round must be a step toward that shape or an explicitly bounded spike with a decision artifact.

---

## ZG-1 — Make the renderer pass clippy pedantic so `just verify` is green

The only horizontal chore in the set, and the one I accept: it is the verification matrix itself, every other item's DoD is red until it lands, and it is bounded (11 named findings, no `#[allow]`, no gate lowering, no behaviour change, `skeleton/` byte-unchanged). It leaves the crate clearer — `must_use`, `missing_errors_doc`, `Option<&T>` params, pass-by-value are exactly the pedantic lints that keep a pure crate's API honest for the Wasm and Axum callers that ZG-4 and ZG-21 add. Nothing here entangles anything.

**BLESS ZG-1 — the gate is the trajectory; a pedantic-clean pure crate is the precondition for linking it twice (Wasm, Axum) without a second opinion on what its API means.**

## ZG-2 — Never panic on a wild date: tolerate timestamps, drop unparseable dates

Pure calculation work in `date.rs` / `slug.rs`, exactly where it belongs; the emitter stays a mechanical consumer. The contract question the Generator raised: emitting `<span class="rz-date …">` without `datetime` for an unparseable value is an element-type choice inside an existing class, and contract 1.0 already has that exact precedent (`.rz-date--present` is a `<span>`, not a `<time>`, §5.3). No class, no `data-rz-*` attribute is added. Ruling: non-breaking, no `data-rz-schema` bump; §5.3 documents it as the AC requires. Two-year view: dates are the first place i18n will arrive; keeping the parse as a pure function that returns a typed outcome (parsed with `datetime` + visible text, or raw text) gives that future one seam instead of a scatter of `if let` in the emitter.

Guidance for AXEL: model the date result as a small enum returned by one function in `date.rs`; `emit.rs` matches on it once per date slot. Never parse dates in `emit.rs`.

**BLESS ZG-2 — pure-calculation fix with a contract precedent already in §5.3; it hardens the one crate both render surfaces share and leaves a single seam for locale work.**

## ZG-3 — Render wild JSON Resume files: numeric score, url-only entries, CRLF, bad URLs

Three trajectory questions and all three come out clean.

1. *`dir="auto"` on `.rz-resume` — 1.1 or not?* It is an attribute outside the Theme selector surface (`.rz-*`, `[data-rz-*]`); a Theme cannot break because the browser resolves direction, and §3 records it as the AC requires. Ruling: **no bump.** The same ruling covers `<span class="rz-link-value">` — `.rz-link-value` is already a contract class (§5.2 lists it on `<a>`), so a `<span>` carrying it for a url-less profile is the `.rz-date--present` pattern again. What §9 lacks is the sentence that makes this ruling mechanical instead of a CTO opinion; that is a doc change no round-1 item owns and I put it in the human/Generator batch below (ZG-19 already edits the contract and is the natural carrier in cycle 2).
2. *Type tolerance in `resume.rs`.* `string_or_number` for `score` is a boundary coercion at deserialisation; the verbatim JSON stays the stored form (ZG-21 stores bytes, not the struct), so tolerance never leaks into the Store and CONTEXT's "JSON Resume is the only stored Resume" holds. Scope out correctly refuses to coerce anything else without evidence — the struct must not become a lenient schema of its own.
3. *URL hygiene as a pure rule.* The `http(s)`/`mailto:`/`tel:` allow-list and omit-empties are stated once in the contract and enforced in one place; that is the ATS-honesty invariant (§1.3, §1.5) made executable, and it is what the hosted page in ZG-21 inherits for free.

The `dir="auto"` change regenerates every crate-output lock (`example.html`, ZG-6 `junior.html`, ZG-11 `long-resume.html`, ZG-19 `contract.html`) — an ordering fact PO already flagged; see execution guidance.

**BLESS ZG-3 — "wild input is valid input" enforced once in the pure crate, with no contract bump needed (existing classes, non-selector attribute) and no tolerance leaking into the stored form.**

## ZG-4 — Run the Renderer in the browser via Wasm and prove it matches the crate

This is the item that decides whether "Wasm + Axum both rendering" is one renderer or two. As written it is one: `renderer-wasm/` is a thin crate that *depends on* `resumezen-renderer` (no copy, no feature flag in the pure crate, the pure crate stays wasm-free), so the only way the browser and the server can disagree is a version skew between two deploy artifacts — and the parity probe compares the Wasm output byte-for-byte against `cargo run --example render` from the same checkout on three inputs, so a stale bundle fails `just verify`. That is parity enforced, not assumed. The `examples/render.rs` oracle is a permanent asset (ZG-11's fixture lock and any future golden-file tooling reuse it) and is deliberately not a product CLI. No `/api/render` endpoint is the right call: one render path per surface, and "nothing leaves your browser" stays literally true on the static build.

What gets harder in two years, named honestly: (a) Netlify's image cannot build Rust, so the moment this lands the static deploy needs a CI artifact or the ZG-21 single-process deploy — a human decision, already in `notes`, not lock-in (the output is a static file); (b) the sandbox is no longer read-only (`article.rz-resume` is swapped), which retires the comment in `ports.js` that says it never is — the Skeleton is still crate output, the Theme `<link>` is untouched, the iframe `src` is unchanged, so the contract with Themes is intact; (c) `window.resumezen.render` is a global — acceptable as the probe seam, provided it stays a thin async wrapper and never grows logic.

Guidance for AXEL: expose `CONTRACT_VERSION` (and crate `version()`) through the Wasm module now, at zero cost; the day the API and the static site are deployed separately, a probe can assert the two artifacts agree without a new PBI.

**BLESS ZG-4 — a bounded foundation slice with a decision artifact (crate parity oracle, thin wasm crate, pure crate untouched) that makes lock 6 true and structurally prevents a second renderer.**

## ZG-5 — Paste or open your own JSON Resume and see it in every Theme

The Author's first step, built on the right strata: rendering is the Wasm bridge (ZG-4), the Skeleton is crate output, Theme switch and print preview work unchanged because only the article changes. Two strategic checks.

*localStorage as the session.* `resumezen.resume` is a single verbatim JSON Resume blob restored on reload, discarded silently when it does not parse or render. When Accounts arrive the migration is one action — read, upload, clear — and the "Forget my résumé" control is the exit already present. No server-side session, no cookie, no conflict with the edit-key model in ZG-22, which uses a separate key (`resumezen.published`). Clean.

*Error classes in two languages.* `not-a-resume` (a known section key with the wrong shape, naming the key) is specified here for the Chrome and again in ZG-21 as a pure `domain` calculation in Rust. That is the one duplication in the set with real drift potential — the Chrome says yes, the API says 422. It is tolerable this round because the rule is a dozen lines, the test vectors are identical (`work: "nope"`, `basics: "E"`), ZG-22 renders the server's `message` humanely when they do disagree, and the crate (via Wasm) remains the final oracle on both sides (`render-failed`). The exit, when it is needed: export a `validate_json` from the crate through the same Wasm module so the Chrome calls the server's exact function. Not this round; the Elm check must simply not grow.

Guidance for AXEL: keep the Elm shape check to exactly the AC's rule and no more — never a schema validator in Elm; storage, file reading and drop handling are actions in the port layer, classification is a pure Elm function over the text, and the two get separate modules.

**BLESS ZG-5 — the wear-loop on the right strata (crate renders, Elm classifies, ports act), with a browser-local session that has a trivial migration to Accounts and a named exit for the one duplicated rule.**

## ZG-6 — Explain the résumé format in plain words and start from a sample

Three decisions to weigh. *Samples embedded at build time as Elm string constants* (`generate.mjs` → `Generated/Samples.elm`): the right stratum — build-time data, not runtime fetch, no server needed, and it does not pre-empt a later Store-backed catalog because samples are product fixtures, not Themes. *A vendored, sha256-pinned `resume-schema.json`* used only by probes: schema validation stays at test time, never a second validator in the product, and re-pinning is a one-line change with an upstream note — that is buying knowledge without buying a platform. *`ajv` dev-only* (or the Rust `jsonschema` fallback) is correctly a human approval and correctly confined to the test harness.

The cost I note without blocking: this adds the third byte-locked crate-output fixture (`example.html`, `junior.html`, then ZG-11's `long-resume.html` and ZG-19's `contract.html`) across two test files with one `RZ_UPDATE_FIXTURES` env var. Four golden files is fine; four bespoke lock tests is not. See execution guidance.

**BLESS ZG-6 — build-time data for samples, test-time-only schema, no second validator in the product; the Author's on-ramp without a runtime dependency or a second source of truth.**

## ZG-7 — Rewrite the chrome in plain language with an About panel and a free-during-preview line

Pure Chrome copy plus one panel with a declared slot for ZG-14. No architecture is touched; the retained "Print preview" toggle keeps the existing probe selectors stable, which is the cheap kind of stability. The one strategic content: "Free during the preview. Pricing is not announced." is the only honest sentence lock 10 and open question 4 permit, and the About panel is where later product statements (pricing, terms) will live, so the seam is right.

**BLESS ZG-7 — copy-only, zero coupling, and it creates the one place (About) where every later product statement belongs instead of scattering them.**

## ZG-8 — Copy a link to this exact view and say so when a theme in the URL does not exist

Stratification is explicit in the body and correct: `ThemeId.fromQuery` becomes a pure Elm function returning `Known | Unknown | Absent`; history stays in `ports.js`; the notice is Elm `text`, so the raw query is never markup. The URL space it defines — `?theme=`, `?view=` on `/` — does not collide with the URL space ZG-21/ZG-22 add (`/r/{id}` on the server, `#edit=` as a fragment). `.copy-link` with its `copied | failed` states is reused by ZG-22 rather than re-invented. Nothing here becomes harder later; a Store-backed catalog changes what `Known` means, not the type.

**BLESS ZG-8 — calculations in Elm, history in the port, a URL scheme that composes with the hosted-page and edit-link schemes without collision.**

## ZG-9 — On a phone show the résumé first and fold the controls into a Theme button

CSS below 720px plus one Elm boolean with ARIA state. Desktop unchanged and guarded by the existing geometry probes. The only forward-looking fact: every later sidebar control (ZG-5's "Use my résumé", ZG-22's Publish, ZG-18's submit link) lives inside the same sidebar and therefore inside the sheet automatically — no second mobile layout to maintain. That is the right shape.

**BLESS ZG-9 — a layout fold, not a second mobile UI; later controls inherit it for free.**

## ZG-10 — Show an honest page count in print preview and how to save a PDF

The most carefully stratified item in the set: `page-estimate.js` is a pure ES module with no DOM, unit-tested under `node --test`, and `ports.js` does only the actions (collect `@page` rules from the loaded sheet, measure the article at paper width in one synchronous task, send the number through one inbound port). No third-party runtime, no paged-media polyfill, no second render path — `scope_out` refuses guide lines and break modelling for the honest reason that a column layout cannot see them. Is "About N pages" a temporary shortcut with no exit? No: the readout is an estimate by name, the pure module is discardable, and when a real pagination source exists (browser paged-media APIs, or the Phase 5 PDF pipeline) it replaces the *input* to the same port. The inline-width measurement is a hack, but an isolated, synchronous, self-restoring one with a probe that checks the restore.

This item also sets the precedent I want the whole port layer to follow: pure module + thin action. See execution guidance.

**BLESS ZG-10 — pure estimate module, isolated measurement action, honest label, no runtime dependency; the readout's input can be swapped later without touching the Chrome.**

## ZG-14 — Serve and link the designer kit: sample HTML, contract, blank CSS, second sample

Publishing repo artifacts through `copy-dist.mjs` is a build-time transform (the one mutation — replacing the `preview.css` link in the served `example.html` with an inlined minimal style — is deterministic and exists to keep BAR-T2's 404 true). Serving raw Markdown with `text/markdown` is a deliberate stopgap with a clean exit: when a designer page exists, the About-panel links change targets and nothing else moves. It also front-loads the fact that ZG-21's backend, which serves `frontend/dist`, must serve the same paths — `dist/` is the one static root for both `serve.mjs` and Axum, so the kit is reachable identically on the static build and the API build. No lock-in, no second source for the contract.

**BLESS ZG-14 — one static root (`dist/`) fed by one build step, reachable identically from the static server and the API; the stopgap has a named exit.**

## ZG-15 — Try a local CSS file in the real switcher without a build

A `blob:` URL through the existing dual-link swap is the smallest honest proof loop for a Designer and it reuses the exact FOUC-safe path first-party Themes use — no second swap mechanism. It does not persist anything, does not push `?theme=`, and does not pre-empt Phase 4: when Submissions have a Store, "try your file" remains the local proofing step in front of "submit", not a competitor to it.

The strategic cost is one I want named: this is the *third* parser of the Theme header. `generate.mjs` parses `Name`/`rz-target` at build time (ZG-16 extends it with `Author`/`URL`), ZG-15 must parse `Name`/`rz-target` in the browser, and ZG-20 parses the header again in the lint. Themes-as-files only works if the header is one format with one parser; three regexes in three files will drift within a year. ZG-16 makes `themes/README.md` the spec for the five fields, which is right; the parser should be one pure module. That is an implementation choice within the AC, so it is guidance, not a reject.

Guidance for AXEL: one pure `theme-header.mjs` (ES module, no DOM) used by `generate.mjs`, by the browser port that backs ZG-15, and by ZG-20's `lint-theme.mjs`; `page-estimate.js` in ZG-10 is the precedent.

**BLESS ZG-15 — reuses the one Theme-swap path instead of adding a second, persists nothing, and leaves the Submission store free to arrive later; the header parser must be shared, which the AC permits.**

## ZG-16 — Credit the Designer with name and link on every theme card

This item quietly settles a two-year question the right way: **the Theme file header is the canonical metadata** (`Name`, `Author`, `URL`, `License`, `rz-target`, documented in `themes/README.md`), and the catalog — generated Elm today, Store-backed later — is a projection of it. That keeps a Theme self-describing and portable (the Zen Garden ethos) and means the future Submissions table caches headers rather than owning them. The Elm `Theme` record gaining `author` and `url : Maybe String` is the same record a JSON decoder will target when the catalog comes from the API, so the generated-literals approach is not a dead end. `javascript:` URLs dropped at parse time is the hygiene rule the renderer already applies, now on the Theme side.

**BLESS ZG-16 — makes the file header the canonical Theme metadata and the Elm `Theme` record the one catalog shape, which is exactly what a Store-backed catalog needs to slot into later.**

## ZG-18 — Give Designers a visible submit path with a stated review turnaround

Lock 9 says a PR is enough at first and this item makes the PR path visible, documented, and checklisted without inventing a Submission store, a review state machine, or CI. CONTEXT is explicit that "pull request" is a path and not the noun — the body's `scope_out` says the same. When the Store-backed Submission arrives, `CONTRIBUTING.md` gains a second path and the PR template stays as the reviewer's checklist; nothing here has to be undone. The 7-day turnaround and the ROADMAP tense change are human-owned product statements, correctly in `notes`. Depends on ZG-14 (links must resolve) and ZG-17 (license terms must exist before asking for a contribution) — both edges are honest ordering, and ZG-17 is in cycle 5 concurrently.

**BLESS ZG-18 — the designer gate as lock 9 defines it, with GitHub as a path rather than the noun, so the later Submission store adds a path instead of replacing one.**

## ZG-22 — Publish, copy your link, delete — with plain answers to who can see it

The Author's goal end to end, and the item where "edit-key auth vs later Accounts" is decided. The shape is a capability model: a 32-char key returned once, stored hashed (ZG-21), carried only in `Authorization`, delivered to the Author as a fragment (`/#edit=id:key`) that never reaches a server log and is cleared from the address bar on load, cached in `localStorage` (`resumezen.published`) on the publishing browser. That composes with Accounts instead of competing with them: an account later *claims* a page by presenting the key once, `resumes` gains an `account_id` column, and the public URL, the fragment scheme and the `PUT`-same-id rule all survive. "Update, never a second page" is the stable-URL promise made structural. `Download my JSON` from the loaded Resume is the ownership answer with zero server involvement. The `unavailable` state on the static build is the honest consequence of ZG-21's no-CORS, same-origin decision, which I endorse: it keeps the deploy topology a human decision instead of a code default.

Two costs, neither blocking: the probe harness now spawns the Rust backend on `PROBE_PORT + 1`, so `npm test` alone needs a Rust toolchain — acceptable because `just verify` is the gate and already needs both, but it must be said in `frontend/README.md`. And the trust copy promises "kept until you delete it" and "no analytics" against a public `POST` with a 1 MiB cap and no rate limit (ZG-21 `scope_out`, Phase 5); harmless locally, a cost exposure the day it is deployed. That is a deploy-gate decision for the human, batched below, not a planning defect.

**BLESS ZG-22 — a capability-based edit model that Accounts can claim rather than replace, a stable id under `PUT`, key never in a URL or log; the only account substitute lock 10 permits and the right one.**

---

## Summary

| id | verdict | strategic rationale (one line) |
| --- | --- | --- |
| ZG-1 | BLESS | the gate itself; pedantic-clean pure crate before it is linked twice |
| ZG-2 | BLESS | pure date calc; `<span class="rz-date">` follows the §5.3 `--present` precedent — no bump |
| ZG-3 | BLESS | `dir="auto"` outside the Theme selector surface, `.rz-link-value` exists — no bump; tolerance never reaches the Store |
| ZG-4 | BLESS | thin wasm crate over the pure crate + same-run parity oracle = one renderer, structurally |
| ZG-5 | BLESS | crate renders, Elm classifies, ports act; localStorage session has a one-action migration |
| ZG-6 | BLESS | build-time sample data, test-time-only schema, no second validator |
| ZG-7 | BLESS | copy-only; About is the single home for later product statements |
| ZG-8 | BLESS | pure `ThemeId` result type, history in the port, URL scheme composes with `/r/{id}` and `#edit=` |
| ZG-9 | BLESS | layout fold, not a second mobile UI |
| ZG-10 | BLESS | pure estimate module + isolated measurement; input swappable later |
| ZG-14 | BLESS | one static root for both servers; stopgap with a named exit |
| ZG-15 | BLESS | reuses the one swap path; header parser must be shared (allowed by AC) |
| ZG-16 | BLESS | file header is canonical Theme metadata; Elm `Theme` is the one catalog shape |
| ZG-18 | BLESS | PR as a path, not the noun; Submission store adds a path later |
| ZG-22 | BLESS | capability edit model that Accounts can claim; stable id; key never in URL/log |

15 BLESS, 0 REJECT. Every in-scope item now carries PO, QA and CTO BLESS and may be labelled `avril-blessed`.

---

## Set-level notes

### Dependency graph (all 22, including the seven out-of-scope items' edges)

```
ZG-1 ─┬─> ZG-2 ─┬─> ZG-3 ─┬─> ZG-5 ─┬─> ZG-6
      │         │         │         └─> ZG-22 <─ ZG-8
      │         │         └─> ZG-21 ──────^
      │         └────────────> ZG-21
      └─> ZG-4 ────────────> ZG-5
ZG-7 ─┬─> ZG-10
      └─> ZG-14 ─┬─> ZG-18 <─ ZG-17 <─ ZG-16
                 └─> ZG-19 <─ ZG-16, ZG-17
                     ZG-19 ─> ZG-20
ZG-11 ─> ZG-12
ZG-13 (leaf)   ZG-9 (leaf)   ZG-15 (leaf)
```

Acyclic (checked edge by edge). Ready at start: **ZG-1, ZG-7, ZG-8, ZG-9, ZG-11, ZG-13, ZG-15, ZG-16** — eight items, six of them in this cycle's blessed set, so AXEL is not serialised on anything. Longest chains: Author lane `ZG-1 → ZG-2 → ZG-3 → ZG-5 → ZG-22` (with ZG-21 and ZG-8 joining at ZG-22), depth 5; Designer lane `ZG-16 → ZG-17 → ZG-19 → ZG-20` and `ZG-7 → ZG-14 → ZG-19 → ZG-20`, depth 4. Every edge is either file ownership (`wild.rs`, `_blank.css` header, `openResumePage`, `ada.json`) or a real prerequisite; none is a convenience. Teachable: each lane reads as a sentence (gate → crate hardening → browser render → paste → publish; credit → license → docs → lint).

Out-of-scope edges I checked for trajectory harm: ZG-21 → ZG-2, ZG-3 (the API must never 500 on wild input — right); ZG-12 → ZG-11 (same sheet, print block first — right); ZG-19 → ZG-14, ZG-16, ZG-17 (three items edit one header; ordering, not scope — right). ZG-13 has no dependants but PO's instruction stands and I make it firmer: **no hosted page is walked by a persona until ZG-13 has landed**, or the trust copy in ZG-22 is false on the day it ships.

### Stratification at the backlog level

One horizontal chore (ZG-1), justified as the gate. One foundation slice (ZG-4), explicitly the lock-6 enabler with a decision artifact (parity oracle, thin wasm crate, pure crate untouched). Everything else is a vertical slice with a named persona and a demo. No item asks the execution team to invent a second product, a second Skeleton, a second renderer, a second database, or a second theme format. Phase 5 nouns (Account, Payment, PDF pipeline, subdomain, AI, import) appear only in `scope_out`.

### Contract 1.0 ruling (for the Generator and cycle 2)

`dir="auto"` on `.rz-resume`, `<span class="rz-date">` for unparseable dates, and `<span class="rz-link-value">` for url-less profiles are **non-breaking under 1.0**: no class or `data-rz-*` attribute is added (both classes already exist), `dir` is not in the Theme selector surface, and §5.3 already has the `<span>`-not-`<time>` precedent. No `1.1` bump. What is missing is the rule that makes this mechanical: §9 should say that (a) new attributes outside `data-rz-*` and element-type changes inside an existing class are documented, no bump; (b) a new class or `data-rz-*` attribute is a minor bump; (c) a rename or removal is major. ZG-19 (cycle 2) already edits the contract and is the natural carrier; if its body is not reopened, this is a one-paragraph item for round 2. Also carried forward from ZG-3's `scope_out`: `work[].description` rendering is a field-map change and belongs to the first deliberate 1.1, not a bug fix.

### Execution guidance for AXEL (the code GAN's architect should hold these as rules)

1. **Order.** Start with ZG-1 (unblocks the matrix) and, in parallel, ZG-11, ZG-7, ZG-16. Then ZG-2 → ZG-3 and ZG-4 alongside; ZG-13 before any hosted-page walk; ZG-5 and ZG-6 back to back (PO's rule — do not walk Priya or Elena between them); ZG-11 before ZG-10 so the first readout matches a PDF; ZG-16, ZG-17 before ZG-14 so ZG-18 and ZG-19 unblock together.
2. **`dir="auto"` regenerates every crate-output lock.** `example.html` (ZG-3), `junior.html` (ZG-6), `long-resume.html` (ZG-11), `contract.html` (ZG-19). Whichever fixture lands before ZG-3 is regenerated as part of ZG-3 (`RZ_UPDATE_FIXTURES=1`), in the same commit, with the diff shown in evidence.
3. **One table-driven golden-file test, not four.** `acceptance.rs` and `fixtures.rs` are converging on the same shape (JSON in, HTML byte-locked, env var to regenerate). Implement the lock once as a helper over a list of `(json, html)` pairs; each PBI adds a row. Two files, one helper, one env var.
4. **The port layer is wiring, not a module.** `ports.js` (325 lines today) is asked by this round to add the Wasm bridge and sandbox swap (ZG-4), file reading and storage (ZG-5), clipboard and `view=` history (ZG-8), page-rule collection and a `ResizeObserver` (ZG-10), blob URLs (ZG-15), and `fetch`/fragment/download (ZG-22). Left as one file that is a god-module by the end of the round. Rule for the code GAN: every concern is its own ES module under `frontend/static/` (ZG-10's `page-estimate.js` is the precedent — pure module, unit-tested under `node --test`), and `ports.js` only subscribes ports to them. The ACs pin port names and observable behaviour, not file layout; the architect must reject any phase that grows `ports.js` with logic.
5. **One Theme-header parser.** `generate.mjs` (build), the ZG-15 browser path, and ZG-20's `lint-theme.mjs` all read the header that ZG-16 makes canonical. One pure `theme-header.mjs`, three importers. Three regexes is a reject at code review.
6. **`probes.mjs` becomes a runner.** It is 1,126 lines before this round adds roughly a hundred named probes and a dozen shared helpers (`openResumePage`, `paginate`, `printableWidthPx`, `contrastRatio`, `printToPdf`, the backend spawner). The ACs pin the `PASS  ZG-n/<slug>` lines and the entry point, not the layout. Layout: `frontend/scripts/probes/lib/*.mjs` for helpers, one module per PBI or per surface, `probes.mjs` imports and runs them in the order the bodies require (ZG-20's lint first in `staticProbes()`). Fixture ownership stays exactly as the bodies state.
7. **Validation has one oracle.** The Chrome's `not-a-resume` (ZG-5) and the API's `domain` shape check (ZG-21) implement the same twelve-line rule with the same test vectors. Keep the Elm side to the AC and no more; if it ever needs a third case, the fix is exporting the crate's check through the Wasm module, not a bigger Elm decoder.
8. **Wasm and API must be able to prove they agree in production.** Expose `CONTRACT_VERSION` and `version()` from the Wasm module (ZG-4, zero cost) and from the API (ZG-21, a header or `/api/version` — cycle 2 may add it); the parity probe already proves same-checkout parity, this is the deploy-time check.
9. **`npm test` now needs Rust** once ZG-22 lands (it spawns the backend). Say so in `frontend/README.md`; `just verify` is the gate and already needs both.

### Human decisions to surface once, before AXEL starts

These are all already in `notes` on the cards; they should be put to the human together, not one at a time when a probe goes red.

| # | Decision | Items on its critical path |
| --- | --- | --- |
| 1 | `ajv` (^8, dev-only) as a `frontend/` devDependency, or the Rust `jsonschema` dev-dependency fallback | ZG-6 (Elena's on-ramp) |
| 2 | Repo license: confirm MIT for code, MIT / CC BY 4.0 for contributed Themes, name the copyright holder, and MIT-only vs keeping Cargo's `MIT OR Apache-2.0` | ZG-17 → ZG-18, ZG-19, ZG-20 (every Designer item) |
| 3 | Vendoring ~10 OFL-licensed woff2 files into `themes/fonts/` | ZG-13 (must land before any hosted-page walk) |
| 4 | `sha2` (or `ring`) and `rand`/`getrandom` in `backend/` | ZG-21 → ZG-22 (Priya's path) |
| 5 | Retention wording ("kept until you delete it; this is a free preview") and the "no analytics" promise | ZG-22, ZG-7 |
| 6 | Review turnaround "within 7 days" | ZG-18 |
| 7 | Deploy path after ZG-4: Netlify's image cannot build Rust — CI artifact for the static site, or the ZG-21 single-process deploy on a Rust host (open question 1) | ZG-4 onward; production only |
| 8 | Deploy gate for ZG-21: a public `POST` with a 1 MiB cap and no rate limit must not be exposed on Turso without a rate limit or a per-day cap (Phase 5 in `scope_out`; a `tower` layer is additive) | production only, not this round's AC |
| 9 | Contract §9 additive-compatibility sentence (ruling above) — fold into ZG-19 in cycle 2 or open a one-paragraph item | ZG-19 |

None of 1–6 changes a body materially if answered as proposed (each is a one-line edit). 7 and 8 are outside every AC by the intent's repo facts and must not be picked silently by AXEL.

### What I will look for in cycle 2 (the seven concurrent items)

ZG-21: that the `domain` / `store` / `http` layering is real (no libSQL type in a handler signature, one error-to-status mapping), that the store trait has exactly one production implementation selected by environment, and that render-on-read stays the rule. ZG-19: the §9 sentence above, and that the proofing fixture is a superset copy, never a fork. ZG-20: that `checkTheme` is pure and shares the header parser. ZG-11/ZG-12/ZG-13: that probe helpers land in `probes/lib/` rather than inline, and that `U3_PRINT_PAGES` / `LONG_PRINT_PAGES` are re-baselined exactly once. ZG-17: nothing strategic beyond the human license answer.
