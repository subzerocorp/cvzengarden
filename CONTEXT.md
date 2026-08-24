# ResumeZen

A CSS Zen Garden for résumés. One Skeleton. Infinite Themes. The audience is the Designer who restyles a Resume, and the Author who pastes JSON Resume. Domains: cvzengarden.com, resumezengarden.com.

## Roadmap

AVRIL turns this into PBIs. Do not invent a second product.

1. **Contract** — lock Skeleton HTML (`rz-*`) and this glossary. JSON Resume is the only stored Resume.
2. **Renderer** — Rust crate: Resume → Skeleton. Byte-stable against fixtures.
3. **Chrome** — Elm gallery: paste a Resume, live Theme switcher, download HTML/CSS. GPUI Component design guides.
4. **Themes** — three to four dramatically different Themes so the Garden is real.
5. **Store** — Axum + Turso: Theme metadata, submissions, featured flags.
6. **Bridge** — SchemaResume and UniversalResume import and export (lossless where possible).
7. **Generate** — Grok emits a Theme against the Class Contract.
8. **Later** — PDF, Auth, Payments, custom subdomains. Not this product yet.

## Language

### Product

**ResumeZen**:
The product. The Garden. The site that hosts Themes and the Chrome that tries them on a Resume.
_Avoid_: CV Zen Garden as the product name, ResumeZen Garden, treating the domain as the product name

**Garden**:
The public collection of Themes applied to one Skeleton. CSS Zen Garden, for résumés.
_Avoid_: Marketplace, theme store, portfolio of templates (those imply page templates, not one HTML tree)

### Document

**Resume**:
A JSON Resume document. Canonical input and stored form. Spec: jsonresume.org / jsonresume/resume-schema. Top-level keys are `$schema`, `basics`, `work`, `volunteer`, `education`, `awards`, `certificates`, `publications`, `skills`, `languages`, `interests`, `references`, `projects`, `meta`.
_Avoid_: resumezen.v1, CV object, custom storage schema, “the JSON we invented”

**SchemaResume**:
tradik/schema-resume (schema-resume.org). A JSON Resume–inspired dialect with extra fields, JSON-LD / Schema.org context, and XML. Import into a Resume. Export a Resume out to SchemaResume. Never the stored form.
_Avoid_: Treating SchemaResume as canonical, requiring `@context` on every Resume

**UniversalResume**:
[universal-resume](https://github.com/universal-resume) (`universal-resume/json-schema`). A stricter resume JSON: `basics.headline`, `basics.contact`, `employments[]` (not `work`), `education.organization`, `initiatives[]` (volunteer / personal / open-source / …), nested Organization/Location objects, `additionalProperties: false`. Import into a Resume. Export a Resume out to UniversalResume. Never the stored form. Their html-renderer and pdf-generator are not our Renderer or Themes.
_Avoid_: Treating UniversalResume as canonical, adopting their HTML/PDF tools as the Skeleton, using `employments` in stored JSON

**Author**:
The person the Resume describes. Pastes or imports JSON (a Resume, SchemaResume, or UniversalResume). Not a Designer unless they also submit a Theme.
_Avoid_: User (when you mean this person), candidate, job seeker as the entity

### Render

**Skeleton**:
The one semantic HTML tree the Renderer emits. Same tags, same order, every time. Themes restyle it. They do not rearrange it.
_Avoid_: Template, layout, page, theme HTML

**Class Contract**:
The public `rz-*` class and `data-rz-*` attribute list on the Skeleton. Versioned. Themes, the Renderer, and Generate all speak it. Changing a class name is a breaking release.
_Avoid_: CSS framework, utility classes, Tailwind, chrome class names on the Skeleton

**Renderer**:
The Rust crate that turns a Resume into a Skeleton. Drop empty nodes. ATS-honest markup: real headings, lists, `mailto:` / `tel:` / `https:`, `<time datetime>`.
_Avoid_: Client-side HTML assembly as the source of truth, markdown-in-JSON in v1

**Theme**:
One pure `.css` file that targets the Class Contract. Unconstrained art. No Tailwind. No CSS-in-JS. No extra HTML, JS, or webfont loader. Ship one file. Faces come from the Font Library or from a public HTTPS CDN `@font-face` / CSS `@import`.
_Avoid_: Template, skin that edits HTML, JSON Resume theme (those are HTML/Handlebars packages, not this)

**Font Library**:
Garden-hosted fonts Designers may submit. Inbound license is CC BY 4.0. First-party Themes, and Themes that use a Library face, load from our origin only. Seed families that arrived under SIL OFL keep SIL OFL and ship `OFL.txt`; we do not relicense them.
_Avoid_: Calling a CDN the Library, relicensing OFL faces as CC BY 4.0, a JS webfont loader

**Preview CSS**:
A local readability aid in `skeleton/preview.css`. Not a Theme. Themes must not depend on it.
_Avoid_: Calling preview.css a Theme, shipping it as a Garden entry

### Chrome

**Chrome**:
The product UI around the Garden: gallery, Theme switcher, Resume paste, forms, nav. Elm + vanilla CSS. Follows GPUI Component design guides (tokens, sizes, variants, radius, state precedence, reduced motion). Never uses `rz-*`.
_Avoid_: Styling Chrome with a Theme, leaking Theme CSS into Chrome (sandbox the Skeleton)

**Gallery**:
Chrome that lists Themes and shows each on the same Skeleton.
_Avoid_: Portfolio, theme picker as a separate product

**Switcher**:
Chrome control that swaps the Theme stylesheet on a live Skeleton without changing the Resume.
_Avoid_: Reload-to-restyle, per-Theme HTML

### People and store

**Designer**:
Submits a Theme. Writes only CSS against the Class Contract.
_Avoid_: Developer (when you mean this person), theme author as a second noun

**Submission**:
A Theme offered to the Garden. Has metadata, a featured flag, later a review state.
_Avoid_: Pull request as the only submission path (that may exist; it is not the noun)

**Turso**:
Hosted SQLite (libSQL) for Theme metadata, Submissions, and later Author Resumes. Org `scull7`, group `cvzengarden`, database `cvzengarden`.
_Avoid_: Postgres, a second database, local SQLite as the production store

**Generate**:
An external Grok call that emits a Theme targeting the Class Contract. Result is just another Theme file.
_Avoid_: LLM rewriting the Skeleton, generating HTML, a second class vocabulary

### Out of this product

Not nouns here. Do not plan them as v1 entities.

_Avoid as entities_: Account, Auth, Payment, Invoice, Subscription, custom subdomain as a kernel, PDF as the source of truth, Job board, ATS vendor adapter, JSON Resume Handlebars theme, UniversalResume html-renderer, UniversalResume pdf-generator, Tailwind, Organization (as OS root)
