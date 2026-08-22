# ResumeZen

A [CSS Zen Garden](https://www.csszengarden.com/) for resumes.

One **fixed semantic HTML skeleton**. Infinite **designer-submitted CSS themes**. Paste a `resume.json`, pick a theme, ship a résumé that still parses as a document — not a pile of absolutely-positioned `div`s.

- Product: **ResumeZen**
- Domains: [cvzengarden.com](https://cvzengarden.com) / [resumezengarden.com](https://resumezengarden.com)
- Repo: [subzerocorp/cvzengarden](https://github.com/subzerocorp/cvzengarden)

The stable interface is the **HTML class contract** in [`skeleton/`](skeleton/). Themes target those classes. The renderer, the gallery, and any future AI prompt all speak that same contract. If you change a class name, you break every theme — treat it like a public API.

---

## How it works

```
resume.json  ──►  Rust renderer  ──►  fixed semantic HTML (rz-* classes)
                                              │
theme.css    ─────────────────────────────────┴──►  styled résumé
```

1. A candidate (or a form) produces `resume.json`.
2. A Rust crate turns that JSON into **one** HTML tree. Same tags, same classes, same heading order, every time.
3. A theme is a **pure `.css` file** that styles those classes. No Tailwind. No CSS-in-JS. Designers only touch CSS.
4. The product chrome (gallery, theme switcher, JSON paste, forms) is a separate UI, styled after [GPUI Component](https://longbridge.github.io/gpui-component/). Chrome and themes never share class names.

Submitted resume themes are unconstrained art. They only have to target the documented classes. Product chrome is the opposite: it follows a locked design system. See [`frontend/DESIGN.md`](frontend/DESIGN.md).

---

## Stack (locked)

| Layer | Choice | Status |
| --- | --- | --- |
| Core renderer | Rust crate: `resume.json` → fixed HTML | Stub in [`renderer/`](renderer/) |
| Backend | Rust + Axum + SQLite | Later — [`backend/`](backend/) |
| Product UI | Elm + vanilla CSS | Later — [`frontend/`](frontend/) |
| Themes | Pure `.css` only | Drop files in [`themes/`](themes/) |
| AI themes | Grok prompts that emit CSS against the class contract | Later — [`ai/`](ai/) |

Do not introduce Tailwind, CSS-in-JS, or a second HTML skeleton.

---

## Repository map

```
skeleton/    HTML class contract, example output, sample resume.json
themes/      Designer-submitted .css files (one file = one theme)
renderer/    Rust crate that will emit the skeleton from JSON
frontend/    Elm product chrome (gallery, switcher, paste, forms)
backend/     Axum + SQLite API
ai/          System prompts that generate theme CSS
```

---

## MVP order

1. **This repo scaffold** — class contract, example HTML/JSON, chrome design note.
2. **Renderer** — Rust crate that consumes `skeleton/resume.json` and emits `skeleton/example.html` (byte-stable, test-locked).
3. **Product chrome** — Elm gallery + theme switcher + JSON paste, following [`frontend/DESIGN.md`](frontend/DESIGN.md).
4. **Theme drop** — designers submit pure CSS against the contract.
5. **Backend** — Axum + SQLite for themes, submissions, and serving.
6. **AI themes** — Grok prompts that emit CSS targeting `rz-*` classes.
7. Later: PDF export, auth, payments, a finished artistic theme set.

Out of scope until the contract is boring and stable: a full renderer, the Elm app, the API, AI prompts, PDF, auth, payments, or a launch set of finished themes.

---

## The class contract is the product

Themes, the renderer, ATS parsers, and AI generators all depend on:

- Semantic, ATS-friendly markup (real headings, lists, links, `<time datetime>`).
- A documented, **namespaced** class list (`rz-*`) so theme CSS cannot collide with product chrome.
- A JSON shape the renderer will consume.

Read [`skeleton/CLASS-CONTRACT.md`](skeleton/CLASS-CONTRACT.md). Open [`skeleton/example.html`](skeleton/example.html) in a browser. Edit [`skeleton/resume.json`](skeleton/resume.json) once the renderer exists.

A designer should be able to write a theme against the contract **today**, before any Rust or Elm ships.

---

## Design two worlds

| Surface | Constraint |
| --- | --- |
| **Product chrome** (gallery, nav, buttons, inputs, dialogs) | GPUI Component visual language. Semantic tokens, fixed sizes/variants/radius, light + dark. See [`frontend/DESIGN.md`](frontend/DESIGN.md). |
| **Resume themes** (`themes/*.css`) | Unconstrained. Target `rz-*` only. Pure CSS. |

Chrome classes will never use the `rz-` prefix. Theme CSS must never assume chrome markup exists. In the gallery, a résumé preview is sandboxed (iframe or equivalent) so theme CSS cannot leak into the product UI.
