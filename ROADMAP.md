# ResumeZen
## Product roadmap — approved
**22 August 2026** · cvzengarden.com · resumezengarden.com

Status: **approved 22 August 2026.** This is the plan we execute against. It is written so someone who has not been in the product chat can read it in one sitting.

## The product in one paragraph

ResumeZen is a CSS Zen Garden for résumés. Every résumé is the same semantic HTML. Designers restyle it with a single CSS file. Job seekers pick a design, publish a public page, and print a clean paper copy. JSON Resume is the data. The HTML class contract is the design API. Themes never see the JSON, and they never ship JavaScript.

## Who it is for

### Job seekers (first paying customers)

They pay for two things, together:

1. A **web presence** — a public page that looks designed, not like a template farm.
2. A **paper result** — the same résumé, printed clean, that they can hand over or send as a PDF from the browser.

They do not pay for a CSS file, and they should not need to know what JSON Resume is. Early builds may accept a JSON Resume paste so we can prove the loop. The paid product is the hosted page plus print.

### Designers (the original Zen Garden audience)

They submit one CSS file that restyles the fixed HTML. A designer may target:

- **Web** — motion, hover, type, layout for a screen.
- **Print** — `@page`, breaks, ink, paper. Quiet on screen is fine.
- **Both** — `@media screen` and `@media print` in the same file.

That split is deliberate. It gives print designers and web designers a real home, instead of forcing everyone to fake a paper look in the browser.

## The bet

JSON Resume already has hundreds of themes. Each theme owns its own HTML. You cannot switch skins live, and you cannot ask a print designer to work in Handlebars.

ResumeZen inverts that. One HTML tree. Infinite CSS. Switching a theme is changing a stylesheet. Printing a theme is the print stylesheet. A designer who already knows CSS can contribute without learning our stack.

If the HTML is rich enough, and we never fork it per theme, the garden compounds. If we let themes invent markup, we become another theme pack.

## Principles

1. **One skeleton.** Same tags, same order, same `rz-*` classes. Themes restyle. They do not rearrange the DOM.
2. **Two surfaces, one file.** Web and print are first-class. A theme declares web, print, or both.
3. **CSS is the art.** Animations, `@font-face`, grid, container queries, `@page`, scroll-driven effects — allowed. JavaScript is not. Words that matter (name, titles, dates) live in the HTML, never only in `content:`.
4. **Motion is for screens.** Animation must be harmless in print and must honor `prefers-reduced-motion`.
5. **ATS-honest HTML.** Real headings, lists, links, and dates. Pretty on the outside, parseable underneath.
6. **JSON Resume is the stored résumé.** Other formats may import and export. They are never the database.
7. **Chrome is not the résumé.** Product UI follows its own design language. Theme CSS cannot leak into it.

## Where we are (August 2026)

- Product name **ResumeZen**. Domains cvzengarden.com and resumezengarden.com.
- Public repo: https://github.com/subzerocorp/cvzengarden
- HTML class contract and sample résumé (Jordan Hale) are drafted.
- Preview of the unthemed skeleton: https://cvzengarden.netlify.app
- Stack is locked: Rust renderer and API, SQLite on Turso, Elm chrome, pure CSS themes.
- Renderer, live gallery, hosted pages, submissions, and payments are **not** built yet.

## Roadmap

Five phases. Each phase has a user-visible outcome. We do not start the next phase until the current one can be shown to a designer or a job seeker.

Foundation → Wear it → Publish → Open the gate → Business

### Phase 1 — Foundation
**Outcome:** The garden is real on a sample résumé.

- Finish the class contract, including web / print / both targets and motion rules.
- Ship a Rust renderer: any valid JSON Resume becomes that HTML, stably.
- Ship three first-party themes that are actually different — not three color tweaks. Across the set, web and print both have to be taken seriously.
- Ship a live theme switcher on the sample résumé, with a screen view and a print preview.

**Done when:** A designer can flip themes without a reload, see motion on a web theme, and print a print theme without the screen choreography.

**Not in this phase:** accounts, payments, foreign JSON dialects, AI.

### Phase 2 — Wear it
**Outcome:** A job seeker can see *themselves* in the garden.

- Paste or import a JSON Resume.
- The renderer replaces only the résumé, not the page.
- Theme switch and print preview run on their data.
- Browser print uses the active theme’s print CSS.

**Done when:** Someone other than us drops in a real résumé, switches skins, and prints a page they would actually hand to a hiring manager.

**Not in this phase:** a public URL, a form editor, LinkedIn import. Those wait until the wear-loop is true.

### Phase 3 — Publish
**Outcome:** The paid job-seeker product exists.

- An account.
- A stable public URL for their résumé.
- Chosen theme persists.
- The public page is the web presence; print from that page is the paper result.

**Done when:** A job seeker can put a ResumeZen URL on LinkedIn and print the same document from that page.

This is the first phase we can charge for. Charging itself is Phase 5. Phase 3 proves the thing they pay for.

### Phase 4 — Open the gate
**Outcome:** The garden is no longer only our themes.

- A designer submits one CSS file and declares web, print, or both.
- We accept (manually at first — a pull request is enough).
- Accepted themes appear in the switcher and on published résumés.

**Done when:** A stranger’s theme is live on the sample and available to a published job-seeker page.

No JavaScript in submissions. Lint for `rz-*` selectors, forbid script, and do not flatten expression.

### Phase 5 — Business
**Outcome:** It is a company, not a demo.

- Payments for the hosted page (and later, extras).
- A real ingest path for people who do not have a JSON Resume (guided form first; other imports after).
- Optional: Grok generates a starting theme against the class contract. The output is just another CSS file, still reviewed.
- Optional: SchemaResume and UniversalResume import/export for people who already have those files.
- Optional: a dedicated PDF pipeline if browser print is not enough.
- Optional: custom subdomains.

**Done when:** A job seeker can pay, publish, and print without talking to us — and a designer can land a theme without us writing it.

## What we are not doing (on purpose)

- A second HTML skeleton “for sidebar themes.” CSS grid on the one tree is the answer.
- JSON Resume Handlebars / npm theme packages as the theme format.
- JavaScript inside themes.
- Storing SchemaResume or UniversalResume as the résumé of record.
- A job board, ATS vendor integrations, or “AI writes your bullets.”
- Rebuilding a desktop design system in the website chrome.

PDF-as-a-service, custom domains, and foreign-format bridges are later options, not the spine.

## Stack (for technical readers)

| Piece | Choice | Why |
| --- | --- | --- |
| Résumé data | JSON Resume | Wild files are valid. Existing ecosystem. |
| Design API | Fixed `rz-*` HTML | Themes are CSS. Live switch and print both work. |
| Renderer | Rust crate | Deterministic HTML. Can run on the server or in the browser via Wasm. |
| Themes | One `.css` file | Designers do not need our repo, Tailwind, or a build. |
| Product chrome | Elm + vanilla CSS | Gallery, switcher, paste, account. Never uses `rz-*`. |
| Store | SQLite on Turso | Theme metadata, accounts, published résumés. CSS files stay files. |
| Preview today | Netlify | Static skeleton until the API exists. |

## How to read the internal tickets

For the engineering thread only. Skip if you are an outside reader.

| Phase | Internal work |
| --- | --- |
| 1 Foundation | Class contract (print/web/motion update), RZ-2 renderer, RZ-5 themes, RZ-3 switcher |
| 2 Wear it | RZ-4 paste + print preview (HTML download is a side effect, not the product) |
| 3 Publish | Hosted author résumés, auth |
| 4 Open the gate | Designer submit + accept |
| 5 Business | Payments, ingest, RZ-8 generate, RZ-7 / RZ-9 bridges |

RZ-6 (Turso featured-theme name) is infrastructure, not a phase. The store comes in when Phase 3 or 4 needs to persist something real.

## Approved

Approved 22 August 2026. That approval locked these meanings:

1. Two audiences, both real. We do not pick one.
2. Job seekers pay for a hosted page and a print-clean result.
3. Designers target web, print, or both, with full CSS including motion.
4. We execute Phase 1 next (renderer + three themes + switcher).
5. Phases 3 and 4 are on the product spine, not a parking lot.
