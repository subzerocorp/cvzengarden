# ResumeZen

A [CSS Zen Garden](https://www.csszengarden.com/) for resumes.

One **fixed semantic HTML skeleton**. Infinite **designer-submitted CSS themes**. Paste a [JSON Resume](https://jsonresume.org/schema), pick a theme, ship a résumé that still parses as a document — not a pile of absolutely-positioned `div`s.

- Product: **ResumeZen**
- Domains: [cvzengarden.com](https://cvzengarden.com) / [resumezengarden.com](https://resumezengarden.com)
- Repo: [subzerocorp/cvzengarden](https://github.com/subzerocorp/cvzengarden)

**JSON Resume is a product feature.** The paste/import target is the public [JSON Resume schema](https://jsonresume.org/schema) ([`jsonresume/resume-schema`](https://github.com/jsonresume/resume-schema)). A file from the wild is valid input. We do not invent a storage dialect.

Themes never see that JSON. They only target the **HTML class contract** (`rz-*`) in [`skeleton/`](skeleton/). The renderer, the gallery, and any future AI prompt all emit or style that same HTML. If you change a class name, you break every theme — treat it like a public API.

---

## How it works

```
JSON Resume  ──►  Rust renderer  ──►  fixed semantic HTML (rz-* classes)
     ▲                                      │
     │                                      └── theme.css ──► styled résumé
Bridge import (SchemaResume | UniversalResume)
```

1. An Author pastes or uploads a **JSON Resume** document (or Chrome imports a Bridge dialect into one).
2. A Rust crate turns that JSON into **one** HTML tree. Same tags, same classes, same heading order, every time.
3. A theme is a **pure `.css` file** that styles `rz-*` classes. No Tailwind. No CSS-in-JS. No JSON Resume theme templates. Designers only touch CSS.
4. The product chrome (gallery, theme switcher, JSON paste, forms) is a separate UI, styled after [GPUI Component](https://longbridge.github.io/gpui-component/). Chrome and themes never share class names.

**Bridge dialects** (import/export only, never stored): [SchemaResume](https://schema-resume.org/) (JSON-LD) and [UniversalResume](https://github.com/universal-resume). Detection and mappings live in [`converter/`](converter/). We do not use UniversalResume's HTML/PDF tools — our Renderer and Themes stay `rz-*`.

Vocabulary: [`CONTEXT.md`](CONTEXT.md) (AVRIL glossary).

Submitted resume themes are unconstrained art. They only have to target the documented classes. Product chrome is the opposite: it follows a locked design system. See [`frontend/DESIGN.md`](frontend/DESIGN.md).

---

## Stack (locked)

| Layer | Choice | Status |
| --- | --- | --- |
| Data | [JSON Resume](https://jsonresume.org/schema) | Fixture in [`skeleton/resume.json`](skeleton/resume.json) |
| Import/export | Bridge: SchemaResume + UniversalResume | Mapping + fixtures in [`converter/`](converter/) |
| Core renderer | Rust crate: JSON Resume → fixed HTML | Stub in [`renderer/`](renderer/) |
| Backend | Rust + Axum + SQLite | Later — [`backend/`](backend/) |
| Product UI | Elm + vanilla CSS | RZ-3 switcher — [`frontend/`](frontend/) |
| Themes | Pure `.css` against `rz-*` only | First-party: Nightgarden (web), Quarto (print), Switchyard (both) in [`themes/`](themes/) |
| AI themes | Grok prompts that emit CSS against the class contract | Later — [`ai/`](ai/) |

Do not introduce Tailwind, CSS-in-JS, JSON Resume theme templates, or a second HTML skeleton.

---

## Repository map

```
skeleton/    HTML class contract, example output, JSON Resume fixture
themes/      Designer-submitted .css files (one file = one theme)
renderer/    Rust crate that will emit the skeleton from JSON Resume
converter/   Bridge: JSON Resume ↔ SchemaResume / UniversalResume
frontend/    Elm product chrome (gallery, switcher, paste, forms)
backend/     Axum + SQLite API
ai/          System prompts that generate theme CSS
```

---

## MVP order

1. **This repo scaffold** — JSON Resume + `rz-*` contract, example HTML, chrome design note, converter map.
2. **Renderer** — Rust crate that consumes `skeleton/resume.json` and emits `skeleton/example.html` (byte-stable, test-locked).
3. **Product chrome** — Elm gallery + theme switcher + JSON Resume paste, following [`frontend/DESIGN.md`](frontend/DESIGN.md).
4. **Theme drop** — designers submit pure CSS against the contract.
5. **Bridge** — SchemaResume and UniversalResume import/export (lossless where possible).
6. **Backend** — Axum + SQLite for themes, submissions, and serving.
7. **AI themes** — Grok prompts that emit CSS targeting `rz-*` classes.
8. Later: PDF export, auth, payments, a finished artistic theme set.

Out of scope until the contract is boring and stable: a full renderer, the Elm app, the API, a converter implementation, AI prompts, PDF, auth, payments, or a launch set of finished themes.

---

## The class contract is the product

Themes, the renderer, ATS parsers, and AI generators all depend on:

- **JSON Resume** as the only stored/pasted data shape.
- Semantic, ATS-friendly markup (real headings, lists, links, `<time datetime>`).
- A documented, **namespaced** class list (`rz-*`) so theme CSS cannot collide with product chrome.

Read [`skeleton/CLASS-CONTRACT.md`](skeleton/CLASS-CONTRACT.md). Open [`skeleton/example.html`](skeleton/example.html) in a browser. Edit [`skeleton/resume.json`](skeleton/resume.json) once the renderer exists.

A designer should be able to write a theme against the HTML contract **today**, before any Rust or Elm ships. Theme rules (web / print / both, motion, `@font-face`, no JS) are in [`skeleton/CLASS-CONTRACT.md`](skeleton/CLASS-CONTRACT.md) §2. A JSON Resume from the wild should be droppable **today** as data.

---

## Design two worlds

| Surface | Constraint |
| --- | --- |
| **Product chrome** (gallery, nav, buttons, inputs, dialogs) | GPUI Component visual language. Semantic tokens, fixed sizes/variants/radius, light + dark. See [`frontend/DESIGN.md`](frontend/DESIGN.md). |
| **Resume themes** (`themes/*.css`) | Unconstrained. Target `rz-*` only. Pure CSS. |

Chrome classes will never use the `rz-` prefix. Theme CSS must never assume chrome markup exists. In the gallery, a résumé preview is sandboxed (iframe or equivalent) so theme CSS cannot leak into the product UI.
