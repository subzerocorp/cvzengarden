# Blessed Backlog Summary — ResumeZen (rev 1)

**Status:** AVRIL triple-blessed · planning stop · 2026-08-22
**Human detail:** [HTML](./resumezen-avril-blessed-backlog.html)
**Space:** ResumeZen (`cvzengarden`) · labels `avril`, `avril-blessed`
**Blessing class:** real AVRIL cycle (Architect → PO → QA → CTO) via delegated personas; PO, QA, and CTO revise rounds; UniversalResume lock mid-loop. Not a draft.
**Glossary:** [`CONTEXT.md`](../../CONTEXT.md) at `834be518` — do not rewrite it.
**Pinto:** not in this repo. Portable Markdown is the artifact.

## Intent

**ResumeZen** is a CSS Zen Garden for résumés. One **Skeleton**. Infinite **Themes**. The audience is the **Designer** who restyles a **Resume**, and the **Author** who pastes JSON Resume (or imports **SchemaResume** / **UniversalResume**).

| Field | Value |
|-------|--------|
| Product | ResumeZen (the Garden + Chrome). Domains cvzengarden.com / resumezengarden.com |
| Repo | github.com/subzerocorp/cvzengarden (public) |
| Preview | https://cvzengarden.netlify.app (Isokio team, Skeleton example) |
| Stored Resume | JSON Resume only (`jsonresume/resume-schema`). No `resumezen.v1` |
| Class Contract | `rz-*` HTML `1.0` (`data-rz-schema` on `.rz-resume`) |
| Bridge dialects | SchemaResume and UniversalResume — import/export only, never stored |
| UniversalResume | [universal-resume](https://github.com/universal-resume) (`universal-resume/json-schema`): `employments`, `basics.headline` / `basics.contact`, `education.organization`, `initiatives` |
| Store | Turso already exists: org `scull7`, group `cvzengarden`, database `cvzengarden`, aws-us-west-2 |
| Stack (locked) | Rust Renderer · later Axum+Turso · Elm + vanilla CSS Chrome · Themes = one pure `.css` vs `rz-*` · no Tailwind / no CSS-in-JS on Themes |
| PR #1 | Contract scaffold (JSON Resume rewrite). CONTEXT.md already committed — do not drop it |

**This document does not write implementation and does not start AXEL.**

## Locked answers

| Decision | Answer |
|----------|--------|
| Stored form | JSON Resume. Wild files are valid input. |
| HTML Theme API | Class Contract `rz-*` only. Themes never see JSON. |
| SchemaResume | Import/export only. Never stored. Never require `@context` on every Resume. |
| UniversalResume | Import/export only. Never stored. Never persist `employments` / `headline` / `contact` / `initiatives` as the stored document. |
| UniversalResume tools | Their html-renderer and pdf-generator are **out** (same class as JSON Resume Handlebars themes). Not our Renderer or Themes. |
| Renderer | Rust crate: immutable Resume in → Skeleton string out. Byte-stable vs fixtures. No Theme load, no network, no PDF. |
| Chrome | Elm + vanilla CSS. GPUI Component design guides. Never `rz-*`. Sandbox the Skeleton. |
| Preview CSS | `skeleton/preview.css` is a local readability aid. Not a Theme. |
| Themes | One file, pure CSS, unconstrained art against `html` / `body` / `.rz-*` / `[data-rz-*]`. |
| Store | Turso (existing). No Postgres. No local SQLite as production. |
| Theme bytes in Turso | No. Metadata (`name`, `featured`) only. CSS stays files. |
| Theme list in Chrome | Data (paths / `GET /themes`), not two Elm literals. |
| Submission POST | Deferred — no submitter actor and no accept path in v1. |
| Generate | Prompt + recorded fixture + allowlist. No live-model AC. Result is just another Theme `.css`. Allowlist gates Generate only, not Designer Themes. |
| Bridge crate | One calc stratum; session Resume is always JSON Resume keys + `meta.x-*` parking. Opposite lossless policies (SchemaResume pass-through vs UniversalResume `additionalProperties: false`) must not infect storage differently. |
| CONTEXT.md | Glossary and roadmap. Not rewritten by AVRIL. |

## Blessed PBIs (ordered)

| ID | Title | Pts | Deps |
|----|--------|-----|------|
| RZ-2 | Emit a byte-stable Skeleton from the Jordan Hale Resume | — | — |
| RZ-5 | Ship three dramatically different Themes for the Garden | — | — |
| RZ-3 | Switch Garden Themes on a sandboxed Skeleton without reload | — | RZ-5 |
| RZ-4 | Let an Author paste a Resume and download HTML/CSS | — | RZ-2, RZ-3 |
| RZ-6 | Persist RZ-5 Theme metadata in Turso and show a featured name | — | RZ-3, RZ-5 |
| RZ-7 | Import and export SchemaResume without ever storing it | — | RZ-4, RZ-6 |
| RZ-9 | Import and export UniversalResume without ever storing it | — | RZ-4, RZ-6 |
| RZ-8 | Generate a Theme from Grok against the Class Contract | — | RZ-5 |

**Order:** `RZ-2 ∥ RZ-5 → RZ-3 → RZ-4 → RZ-6 → RZ-7 ∥ RZ-9` and `RZ-5 → RZ-8`
**Cancelled:** RZ-1 (leftover docs; no user-visible outcome)
**Labels:** `avril`, `avril-blessed`
**Points:** omitted (Architect did not score)

## Explicit cuts

- **RZ-1** leftover contract-doc PBI (Turso naming lives on RZ-6; Class Contract / CONTEXT.md / Preview CSS are invariants, not a slice).
- Rewriting CONTEXT.md or inventing a second glossary.
- `resumezen.v1` or any custom stored dialect.
- JSON Resume Handlebars themes; a second Skeleton; client-side HTML as source of truth.
- UniversalResume html-renderer and pdf-generator.
- Treating SchemaResume or UniversalResume as canonical / stored form.
- Storing `@context` or `employments` in Turso or in the session Resume.
- SchemaResume XML/XSD.
- Gallery-as-catalog (Theme list page) in v1.
- Chrome theming laundry (GPUI token inventory, light/dark dump, size/variant matrix, motion spec) as its own PBI.
- Submission POST / accept / review state (no submitter actor).
- Who-features UI; hosted Author Resumes.
- Postgres, a second database, local SQLite as the production Store.
- CSS blobs in Turso.
- Live Grok / live-model assertions in CI or AC.
- Auto-publishing a Submission from Generate.
- `_blank.css` or `skeleton/preview.css` as a Garden Theme.
- Tailwind / CSS-in-JS on Themes or Chrome.
- PDF, Auth, Payments, custom subdomains, job board, ATS vendor adapter, Organization as OS root.

## Open questions (deferred, non-blocking)

| Item | Status |
|------|--------|
| Submission POST + Designer actor + review state | Deferred-ok — cut until there is an accept path |
| Gallery-as-catalog page | Deferred-ok — Switcher + featured name is the v1 listing |
| Hosted Author Resumes in Turso | Deferred-ok — CONTEXT.md “later Author Resumes” |
| PDF / Auth / Payments / custom subdomains | Cut — Later, not this product |
| Shared Bridge crate packaging vs two modules | Execution detail — session shape is locked (JSON Resume + `meta.x-*`) |
| Where the Renderer crate is hosted (in-process / wasm) | Execution detail — no dedicated HTTP render resource before Store |

No remaining product question is required to execute **RZ-2** or **RZ-5**.

## Blessing log

### Cycle 0 — Architect proposal

RZ-1..8 proposed. No self-BLESS.

### Cycle 1 — PO

| ID | PO |
|----|----|
| RZ-1 | **REJECT** (no user-visible outcome; leftover doc bundle) |
| RZ-2 | BLESS |
| RZ-3 | **REJECT** (Switcher without Themes) |
| RZ-4 | BLESS |
| RZ-5 | BLESS |
| RZ-6 | **REJECT** (bundled list+feature+accept; no submitter) |
| RZ-7 | BLESS |
| RZ-8 | BLESS |

### Cycle 1b — Architect

Cancelled **RZ-1**. Rewrote **RZ-3** (depend on RZ-5; cut Gallery/token extras). Rewrote **RZ-6** (featured name only; no Submission). Folded contract invariants onto RZ-2 / RZ-5.

### Cycle 2 — PO (fresh on revised)

| ID | PO |
|----|----|
| RZ-2 | BLESS |
| RZ-3 | BLESS |
| RZ-4 | BLESS (stands) |
| RZ-5 | BLESS |
| RZ-6 | BLESS |
| RZ-7 | BLESS (stands) |
| RZ-8 | BLESS |

### Human lock — UniversalResume (CONTEXT.md `834be518`)

Bridge roadmap is now SchemaResume **and** UniversalResume. Import/export only. Their html-renderer / pdf-generator out of product.

### Cycle 2b — Architect

Split Bridge: **RZ-7** SchemaResume only; **RZ-9** UniversalResume. Prior RZ-7 BLESS invalidated.

### Cycle 3 — PO (fresh on Bridge)

| ID | PO |
|----|----|
| RZ-2..6, RZ-8 | BLESS (stands) |
| RZ-7 | BLESS |
| RZ-9 | BLESS |

### Cycle 3b — QA (first pass)

| ID | QA |
|----|----|
| RZ-2 | BLESS |
| RZ-3 | **REJECT** (vacuous `.chrome` leak probe; no document-identity) |
| RZ-4 | **REJECT** (reject oracle / empty paste unnamed) |
| RZ-5 | **REJECT** (one axis only; unfinished `content:` probe) |
| RZ-6 | **REJECT** (Store inspect unnamed; hardcoded-name hole) |
| RZ-7 | **REJECT** (partial-equal; vacuous Turso listing; no invalid error) |
| RZ-8 | **REJECT** (live-model flake; no named gate) |
| RZ-9 | **REJECT** (Hale unlocked; missing initiative/canary/location/error oracles) |

### Cycle 3c — Architect

AC revise RZ-3..9 only. RZ-2 stands.

### Cycle 4 — PO then QA then CTO (fresh on revised; RZ-2 stands)

| ID | PO | QA | CTO |
|----|----|----|-----|
| RZ-2 | BLESS | BLESS | BLESS |
| RZ-3 | BLESS | BLESS | BLESS |
| RZ-4 | BLESS | BLESS | BLESS |
| RZ-5 | BLESS | BLESS | BLESS |
| RZ-6 | BLESS | BLESS | BLESS |
| RZ-7 | BLESS | BLESS | BLESS |
| RZ-8 | BLESS | BLESS | BLESS |
| RZ-9 | BLESS | BLESS | BLESS |

## Planning stop

AVRIL is complete. Every **active** PBI has three fresh `BLESS` tokens from the last full adversary chain after its last material edit.

Do **not** implement Renderer / Elm / Axum / Themes / Bridge / Generate in this session.
Do **not** invoke AXEL.
Do **not** create GitHub issues (Markdown is the artifact).
Do **not** rewrite CONTEXT.md.

Handoff (when a human starts AXEL): start at **RZ-2** or **RZ-5** (parallel). Mid-flight scope changes return to AVRIL.

---

## Portable PBI bodies (agent handoff)

### RZ-1 — Lock leftover contract docs to Turso and the existing glossary — CANCELLED

- **Points:** omitted · **Deps:** none · **Labels:** `avril`
- **Cancelled:** no user-visible outcome; leftover doc bundle. Turso naming → RZ-6. Contract invariants → RZ-2 / RZ-5.

### RZ-2 — Emit a byte-stable Skeleton from the Jordan Hale Resume

- **Points:** omitted · **Deps:** none · **Labels:** `avril`, `avril-blessed`
- **Why:** An Author’s Resume becomes the one Skeleton every Theme and the Gallery can trust.
- **Scope in:**
  - Pure Rust calc: immutable Resume in, Skeleton HTML string out (`resumezen_renderer::render`)
  - Field map and omit-empties rules already locked in CLASS-CONTRACT.md HTML contract `1.0` (`data-rz-schema`); CONTEXT.md is not rewritten
  - Fixture lock: `skeleton/resume.json` → `skeleton/example.html` `.rz-resume` tree
  - ATS-honest markup: real headings, lists, `mailto:` / `tel:` / `https:`, `<time datetime>`
- **Scope out:**
  - Loading a Theme, talking to the network, emitting PDF
  - Client-side HTML assembly as source of truth
  - JSON Resume Handlebars themes or a second Skeleton
  - Rendering `meta`, `work[].description`, `basics.location.address`, `postalCode`, or SchemaResume / UniversalResume
  - Rewriting CONTEXT.md or inventing a second glossary
  - Shipping Preview CSS as a Theme
  - Chrome, Turso, Generate
- **AC:**
  - [ ] `resumezen_renderer::render` on `skeleton/resume.json` emits a document whose `<article class="rz-resume" …>…</article>` bytes match that node in `skeleton/example.html`
  - [ ] That output includes `data-rz-schema="1.0"`, `<h1 class="rz-name"` / `Jordan Hale`, `mailto:jordan@hale.example`, `tel:+15035550142`, `datetime="2022-03"`, `data-rz-entry="acme-studio-2022"`, and `class="rz-date rz-date--end rz-date--present"`
  - [ ] That output does not contain `preview.css`, `Product design studio`, `resumezen.v1`, or `rz-pronouns`
  - [ ] `<title>` is `Jordan Hale — Design Engineer` and `<html` has `lang="en"`
  - [ ] Rendering `{ "basics": { "name": "Ada" } }` contains `Ada` in `.rz-name` and does not contain `Jordan Hale`, `id="rz-experience"`, `class="rz-contacts"`, or `class="rz-photo"`
  - [ ] Rendering a Resume that adds `meta.x-schema-resume` and `work[0].description` still omits those strings from the HTML
  - [ ] A stub that returns a constant empty string or ignores the input Resume fails the fixture or Ada probe
- **Notes:** (none)

### RZ-3 — Switch Garden Themes on a sandboxed Skeleton without reload

- **Points:** omitted · **Deps:** RZ-5 · **Labels:** `avril`, `avril-blessed`
- **Why:** A Designer can see the Garden apply different Themes to one Skeleton without a reload.
- **Scope in:**
  - Elm + vanilla CSS Switcher around a sandboxed Skeleton (iframe or equivalent)
  - Switch among at least two RZ-5 visual Themes; only the Theme stylesheet href changes
  - Chrome owns a visible Switcher control with class `theme-switcher` (never `rz-*`)
  - Theme CSS cannot leak into Chrome
- **Scope out:**
  - Gallery-as-catalog (a Theme list page)
  - Chrome theming laundry: GPUI token inventory, light/dark dump, size/variant matrix, motion spec
  - Author paste, download, SchemaResume, UniversalResume, Turso, Generate
  - Treating `_blank.css` or `skeleton/preview.css` as a Theme
  - Tailwind or CSS-in-JS on Chrome
  - Auth, PDF, Payments
- **AC:**
  - [ ] Switcher sandbox document contains `.rz-resume` and `data-rz-schema="1.0"`
  - [ ] Chrome renders a visible control with class `theme-switcher`
  - [ ] Switcher changes that document’s Theme `<link rel="stylesheet" href="…">` from one RZ-5 `themes/*.css` file to another (neither `_blank.css` nor `skeleton/preview.css`) without changing `.rz-resume` inner HTML
  - [ ] After the swap, `Jordan Hale` is still in `.rz-name`, the new `href` greps a different Theme filename than before, Chrome `location.pathname` is unchanged, and the sandbox iframe `src` is unchanged
  - [ ] Chrome markup/CSS under `frontend/` has no class or id prefixed `rz-`
  - [ ] Applying a Theme whose CSS contains `.theme-switcher{display:none}` inside the sandbox leaves the Chrome `theme-switcher` control with computed `display` not `none`
  - [ ] Chrome does not `@import` or `<link>` `skeleton/preview.css`
  - [ ] A stub page with no href swap between two RZ-5 Themes, or that navigates Chrome or replaces iframe `src` to swap Themes, fails those probes
- **Notes:** (none)

### RZ-4 — Let an Author paste a Resume and download HTML/CSS

- **Points:** omitted · **Deps:** RZ-2, RZ-3 · **Labels:** `avril`, `avril-blessed`
- **Why:** An Author can try their own JSON Resume on the live Skeleton and take HTML/CSS with them.
- **Scope in:**
  - Chrome paste target is a Resume (JSON Resume)
  - Paste runs the Renderer calc and replaces only the sandboxed Skeleton
  - Download the current Skeleton HTML and the current Theme `.css`
  - Invalid paste is rejected using the named oracle below
- **Scope out:**
  - Storing the pasted Resume in Turso
  - Accepting SchemaResume or UniversalResume as the stored/paste canonical form (Bridge is RZ-7 / RZ-9)
  - PDF, Auth, Payments, custom subdomains
  - Editing Theme CSS in Chrome, or downloading Preview CSS as a Theme
- **AC:**
  - [ ] Pasting `skeleton/resume.json` yields a sandboxed `.rz-name` of `Jordan Hale` and `data-rz-schema="1.0"`
  - [ ] Pasting a Resume whose `basics.name` is `Ada Lovelace` updates `.rz-name` to `Ada Lovelace` without a full page reload and without leaving `Jordan Hale` in the sandbox
  - [ ] Pasting `""` or whitespace-only shows `[data-paste-error="empty"]` and does not introduce `.rz-name`
  - [ ] Pasting `frontend/fixtures/invalid-json.txt` (body `not-json`) shows `[data-paste-error="invalid-json"]` and does not change `.rz-name`
  - [ ] Pasting `frontend/fixtures/invalid-resume.json` (JSON that fails resume-schema, e.g. `"work": "nope"`) shows `[data-paste-error="invalid-resume"]` and does not change `.rz-name`
  - [ ] Pasting `frontend/fixtures/missing-name.json` (`{ "basics": { "label": "Design Engineer" } }`) shows `[data-paste-error="missing-name"]` and does not introduce `.rz-name`
  - [ ] Download HTML contains `<article class="rz-resume"` and `data-rz-schema="1.0"` and does not contain Chrome GPUI tokens as required rules
  - [ ] Download CSS is a Theme `.css` (a file from `themes/`, not `skeleton/preview.css`) and contains no `<script` and no `@tailwind`
  - [ ] After Switcher selects Theme B, the downloaded CSS matches Theme B, and the Skeleton HTML is unchanged except for the Theme `<link>`
  - [ ] A stub download of empty files or Preview CSS fails the Theme/HTML probes
- **Notes:** (none)

### RZ-5 — Ship three dramatically different Themes for the Garden

- **Points:** omitted · **Deps:** none · **Labels:** `avril`, `avril-blessed`
- **Why:** The Garden is real only when Designers can see one Skeleton wear several unrelated skins.
- **Scope in:**
  - Three (optionally four) pure `.css` Themes in `themes/` targeting CLASS-CONTRACT.md HTML contract `1.0` only
  - Unconstrained art against `html`, `body`, `.rz-*`, and `[data-rz-*]`
  - Theme-internal tokens prefer `--rz-*`
  - Preview CSS is not a Theme
- **Scope out:**
  - `_blank.css` counted as a visual Theme
  - Any Theme depending on `skeleton/preview.css`
  - Tailwind, CSS-in-JS, extra HTML, JS, or a webfont loader
  - JSON Resume Handlebars themes or a second Skeleton
  - Rewriting CONTEXT.md or inventing a second glossary
  - Auth, PDF, Payments
- **AC:**
  - [ ] At least three files matching `themes/*.css` exclude `_blank.css` and each has a non-empty declaration block (at least one property-value pair) for `.rz-resume`, `.rz-name`, `.rz-header`, `.rz-section`, and `.rz-entry`
  - [ ] Those three files are not byte-identical to each other
  - [ ] Each of those files sets a `background` (or `--rz-*` canvas used as `background`) on `html`, `body`, or `.rz-resume` whose declared value differs from the other two
  - [ ] Each of those files sets `.rz-name { color: … }` whose declared color differs from the other two
  - [ ] None of those files contain `@tailwind`, `preview.css`, `<script`, `@import`, `@font-face`, or a class that is not `rz-*` / `html` / `body` / `[data-rz-*]`
  - [ ] None of those files contain a `content:` property (including `.rz-name::before` / `.rz-name::after`)
  - [ ] Opening `skeleton/example.html` (`data-rz-schema="1.0"`) with each Theme linked and `preview.css` unlinked shows the HTML text node `Jordan Hale` in `.rz-name`; that string is not produced by CSS `content:`
  - [ ] Shipping only `_blank.css`, empty selector blocks, or a single file fails the three-file / declaration probes
- **Notes:** (none)

### RZ-6 — Persist RZ-5 Theme metadata in Turso and show a featured name

- **Points:** omitted · **Deps:** RZ-3, RZ-5 · **Labels:** `avril`, `avril-blessed`
- **Why:** Chrome can show a featured Theme from Turso so the Garden listing is real data, not a second database.
- **Scope in:**
  - Axum + Turso as the production Store (org `scull7`, group `cvzengarden`, database `cvzengarden`)
  - Persist Theme metadata for the RZ-5 Themes
  - Seed exactly one featured flag on one of those rows (no who-features UI)
  - Chrome Switcher chrome displays that featured Theme name from Turso in `[data-featured-theme]`
- **Scope out:**
  - Submission POST, accept path, or review state (no submitter actor)
  - Who-features control, Gallery-as-catalog, hosted Author Resumes
  - Postgres, a second database, or local SQLite as the production Store
  - Storing SchemaResume or UniversalResume; re-implementing the Renderer
  - Auth, PDF, Payments, custom subdomains
- **AC:**
  - [ ] Production Store configuration names Turso database `cvzengarden` and does not use a `postgres://` URL or a committed local `.db` as the production Store
  - [ ] `GET /themes` returns a JSON array of objects with fields `name` and `featured`
  - [ ] After persist, `GET /themes` includes one object per RZ-5 visual Theme (`name` equals the `themes/*.css` basename excluding `_blank.css`) and exactly one object has `"featured": true`
  - [ ] Chrome `[data-featured-theme]` text equals that featured object’s `name`, and that name is not `_blank` and is not `preview`
  - [ ] Empty-Store fixture: `GET /themes` returns `[]` → `[data-featured-theme]` is absent or empty (a Chrome hardcoded RZ-5 basename still visible here fails)
  - [ ] Swapping featured from Theme A’s `name` to Theme B’s `name` in Turso updates `GET /themes` and `[data-featured-theme]` to Theme B’s `name`
  - [ ] `README.md` and `backend/README.md` name Turso as the Store and do not present Postgres or local SQLite as the production Store
- **Notes:** (none)

### RZ-7 — Import and export SchemaResume without ever storing it

- **Points:** omitted · **Deps:** RZ-4, RZ-6 · **Labels:** `avril`, `avril-blessed`
- **Why:** An Author can arrive with SchemaResume and leave with SchemaResume while the Store stays a Resume.
- **Scope in:**
  - SchemaResume dialect of the Bridge (UniversalResume is RZ-9)
  - Pure Bridge calc per `converter/MAPPING.md` and `converter/fixtures/schema-resume.json` / `converter/fixtures/jsonresume.json`
  - Import SchemaResume → Resume; export Resume → SchemaResume
  - Chrome or Axum may call the calc; Elm and the Renderer do not re-implement it
  - Park type conflicts on `meta.x-schema-resume`
- **Scope out:**
  - UniversalResume import/export (RZ-9)
  - Storing SchemaResume or requiring `@context` on every Resume
  - SchemaResume XML/XSD
  - Mapping inside Elm or the HTML Renderer
  - UniversalResume html-renderer and pdf-generator
  - PDF, Auth, Payments
- **AC:**
  - [ ] Import of `converter/fixtures/schema-resume.json` deep-equals `converter/fixtures/jsonresume.json` (full document, including no top-level `@context`, JSON Resume `$schema`, `work[0].location` string `Remote`, and `meta.x-schema-resume.work.0.location` with `Portland` / `OR` / `US`)
  - [ ] After that import, the session stored Resume (the document Chrome would pass to the Renderer) deep-equals `converter/fixtures/jsonresume.json` and does not contain `@context`
  - [ ] Export of `converter/fixtures/jsonresume.json` includes `"@context": "https://schema-resume.org/context.jsonld"` and `"$schema": "https://schema-resume.org/schema.json"`
  - [ ] That export restores `work[0].location` as the object `{ "city": "Portland", "region": "OR", "countryCode": "US" }` (not the string `Remote`)
  - [ ] `resumezen_renderer::render` on the session Resume emits `.rz-name` `Jordan Hale` and does not emit `@context`
  - [ ] Chrome can import `converter/fixtures/schema-resume.json` and then show `.rz-name` `Jordan Hale` in the sandbox
  - [ ] Chrome can export the session Resume as SchemaResume JSON that greps `@context` and `schema-resume.org/schema.json` and the restored Portland location object
  - [ ] Import of `frontend/fixtures/invalid-schema-resume.json` (JSON that is not SchemaResume) shows `[data-bridge-error="invalid-schema-resume"]` and does not replace the session Resume
  - [ ] A stub that returns the inbound SchemaResume unchanged fails the deep-equal-to-`jsonresume.json` probe
- **Notes:** (none)

### RZ-8 — Generate a Theme from Grok against the Class Contract

- **Points:** omitted · **Deps:** RZ-5 · **Labels:** `avril`, `avril-blessed`
- **Why:** A Designer can start from a Grok-emitted Theme that is just another CSS file for the Garden.
- **Scope in:**
  - Generate entry point `ai/GENERATE.md` whose only product is a Theme `.css` targeting CLASS-CONTRACT.md
  - Recorded oracle `ai/fixtures/generated-theme.css` plus a deterministic allowlist gate (no live-model assertion)
  - Kept CSS, if any, lives in `themes/`
  - Fixture the CSS is written against: `skeleton/example.html`
- **Scope out:**
  - LLM rewriting the Skeleton or emitting HTML/JS
  - A second class vocabulary, Tailwind, CSS-in-JS, or Preview CSS
  - Auto-publishing a Submission without a Designer
  - CI or AC that calls a live Grok model
  - Auth, PDF, Payments
- **AC:**
  - [ ] `ai/GENERATE.md` names the Class Contract / `rz-*` and `skeleton/example.html` and forbids HTML, JS, Tailwind, Chrome selectors, and `content:`
  - [ ] `ai/fixtures/generated-theme.css` contains `.rz-resume` and `.rz-name` and does not contain `<article`, `<html`, `@tailwind`, `preview.css`, `rz-pronouns`, `.theme-switcher`, or `content:`
  - [ ] The allowlist gate accepts `ai/fixtures/generated-theme.css` only if every selector is `html`, `body`, a `.rz-*` class, a `[data-rz-*]` attribute, or a `--rz-*` custom property
  - [ ] The same gate rejects a stub file that contains `.theme-switcher`, `<article`, `<html`, or `.rz-name::after{content:"Jordan Hale"}`
  - [ ] Applying `ai/fixtures/generated-theme.css` to `skeleton/example.html` (Preview CSS unlinked) leaves `.rz-name` computed `content` as `none` or `normal` and the HTML text node `Jordan Hale`
  - [ ] A stub that returns empty CSS fails the recorded-fixture / allowlist probes
- **Notes:** (none)

### RZ-9 — Import and export UniversalResume without ever storing it

- **Points:** omitted · **Deps:** RZ-4, RZ-6 · **Labels:** `avril`, `avril-blessed`
- **Why:** An Author can arrive with UniversalResume and leave with UniversalResume while the Store stays a Resume.
- **Scope in:**
  - UniversalResume dialect of the Bridge (`universal-resume/json-schema`)
  - Add a converter mapping plus fixture pair (`converter/fixtures/universal-resume.json` and `converter/fixtures/jsonresume-universal.json`) for the same Author as the SchemaResume pair
  - Import UniversalResume → Resume; export Resume → UniversalResume
  - Map `basics.headline` → `basics.label`, `basics.contact.email` → `basics.email`, `employments[]` → `work[]` (`employments[].organization.name` → `work[].name`), `education[].organization.name` → `education[].institution`, `initiatives[]` with `type` `volunteering` → `volunteer[]`, `type` `personal` or `open-source` → `projects[]`
  - Flatten nested location objects to JSON Resume strings; park unmapped UniversalResume extras on `meta.x-universal-resume` (same lossless pattern as `meta.x-schema-resume`, not a second stored schema)
  - Chrome or Axum may call the calc; Elm and the Renderer do not re-implement it
- **Scope out:**
  - Storing UniversalResume or persisting `employments`, `basics.headline`, `basics.contact`, or `initiatives` as the stored document
  - Treating UniversalResume as canonical or requiring its keys on every Resume
  - UniversalResume html-renderer and pdf-generator (not our Renderer or Themes)
  - Organization as an OS root noun
  - Mapping inside Elm or the HTML Renderer
  - SchemaResume (RZ-7); PDF, Auth, Payments
- **AC:**
  - [ ] `converter/fixtures/universal-resume.json` has `basics.name` `Jordan Hale` and contains `employments`, `basics.headline`, `basics.contact`, `education` with `organization`, `initiatives` items with `"type": "volunteering"`, `"type": "personal"`, and `"type": "open-source"`, `basics.availability` `ur-canary-1`, and `employments[0].location` as `{ "city": "Portland", "region": "OR" }`, and does not use `work` as the employment array key
  - [ ] Import of that fixture deep-equals `converter/fixtures/jsonresume-universal.json` on locked probes: stored keys are `work`, `basics.label`, `basics.email`; `education[0].institution` is present; `basics.name` is `Jordan Hale`; there is no top-level `employments` or `initiatives`; `basics` has no `headline` or `contact` object; `meta.x-universal-resume.canary` is `ur-canary-1`
  - [ ] Imported `work[0].name` equals inbound `employments[0].organization.name`; imported `basics.label` equals inbound `basics.headline`; imported `basics.email` equals inbound `basics.contact.email`; imported `work[0].location` is the string `Portland, OR`
  - [ ] Inbound `initiatives` with `"type": "volunteering"` lands on stored `volunteer`; `"type": "personal"` and `"type": "open-source"` land on stored `projects` (both types present in the fixture and both present after import)
  - [ ] After import, the session stored Resume has no `employments` and has `meta.x-universal-resume.canary` equal to `ur-canary-1`
  - [ ] Export of the stored fixture contains `employments`, `basics.headline`, `basics.contact`, `education` `organization`, and `initiatives` with those three `type` values, and does not use `work` as the employment array key
  - [ ] `resumezen_renderer::render` on the session Resume emits `.rz-name` `Jordan Hale` and the HTML does not contain `employments`
  - [ ] Chrome can import `converter/fixtures/universal-resume.json` and show `.rz-name` `Jordan Hale` in the sandbox
  - [ ] Chrome can export the session Resume as UniversalResume JSON that greps `employments` and `headline` and does not grep a top-level `"work":` employment array
  - [ ] Import of `frontend/fixtures/invalid-universal-resume.json` (JSON that is not UniversalResume) shows `[data-bridge-error="invalid-universal-resume"]` and does not replace the session Resume
  - [ ] A stub that returns the inbound UniversalResume unchanged fails the “no `employments` on session Resume” probe
- **Notes:** (none)
