# ResumeZen

A [CSS Zen Garden](https://www.csszengarden.com/) for résumés.

One **fixed semantic HTML skeleton**. Infinite **designer-submitted CSS themes**. Paste a [JSON Resume](https://jsonresume.org/schema), pick a theme, ship a résumé that still parses as a document — not a pile of absolutely-positioned `div`s.

- Product: **ResumeZen**
- Domains: [cvzengarden.com](https://cvzengarden.com) / [resumezengarden.com](https://resumezengarden.com)
- Repo: [subzerocorp/cvzengarden](https://github.com/subzerocorp/cvzengarden)
- Product plan: [ROADMAP.md](ROADMAP.md) · vocabulary: [CONTEXT.md](CONTEXT.md) · agent rules: [AGENTS.md](AGENTS.md)

**JSON Resume is a product feature.** The paste/import target is the public [JSON Resume schema](https://jsonresume.org/schema). A file from the wild is valid input. We do not invent a storage dialect.

Themes never see that JSON. They only target the **HTML class contract** (`rz-*`) in [`skeleton/`](skeleton/). The renderer, the gallery, and any future AI prompt all emit or style that same HTML. If you change a class name, you break every theme — treat it like a public API.

---

## How it works

```
JSON Resume  ──►  Skeleton renderer (OCaml)  ──►  fixed semantic HTML (rz-* classes)
     ▲                                                     │
     │                                                     └── theme.css ──► styled résumé
Paste · upload · URL (Studio)
```

1. An Author pastes or uploads a **JSON Resume** document in the Studio.
2. The shared OCaml renderer turns that JSON into **one** HTML tree — in the browser for live preview, on the server for `/api/render`. Same tags, same classes, same heading order, every time. Byte-locked against [`skeleton/example.html`](skeleton/example.html) and [`skeleton/samples/`](skeleton/samples/).
3. A theme is a **pure `.css` file** that styles `rz-*` classes. No Tailwind. No CSS-in-JS. Designers only touch CSS. The Workbench lints a stylesheet against the contract before it is submitted.
4. The product chrome (Garden, Gallery, About, Studio, Workbench) is a separate SolidJS app styled with the **Organic** design system. Chrome and themes never share class names; the résumé is sandboxed in an iframe so theme CSS cannot leak.

---

## Stack (locked)

**Every line of code in this repository is OCaml, compiled with [Melange](https://melange.re). There is no hand-written JavaScript** — `just no-js` enforces it in CI.

| Layer | Choice | Where |
| --- | --- | --- |
| Data | [JSON Resume](https://jsonresume.org/schema) | Fixtures in [`skeleton/`](skeleton/) |
| Shared domain | Melange library: Resume decoder, Skeleton renderer, dates, safe hrefs, theme-contract linter, theme metadata | [`shared/`](shared/) |
| Chrome | Melange → [SolidJS](https://www.solidjs.com/) (hyperscript, no JSX) + vanilla CSS (Organic tokens) | [`frontend/`](frontend/) |
| API | Melange → [Hono](https://hono.dev/) on [Bun](https://bun.com/) | [`backend/`](backend/) |
| Store | SQLite via [libSQL](https://github.com/tursodatabase/libsql) (`@libsql/client`): a local file in development, [Turso](https://turso.tech/) in production | `DATABASE_URL` |
| Themes | Pure `.css` against `rz-*` only | First-party: Nightgarden (web), Quarto (print), Switchyard (both) in [`themes/`](themes/) |
| Tests | Melange test executables run by Bun (renderer parity, calculations, linter, HTTP API) | [`test/`](test/) |

Do not introduce Tailwind, CSS-in-JS, JSON Resume theme templates, a second HTML skeleton, or a `.js` file.

---

## Run it

Prerequisites: [opam](https://opam.ocaml.org/) (OCaml 5.3), [Bun](https://bun.com/), [just](https://github.com/casey/just).

```bash
just init        # opam switch (dune, melange, ocamlformat) + bun install
just serve       # build everything and serve on http://localhost:4310
```

| Recipe | What it does |
| --- | --- |
| `just compile` | `dune build` every Melange target into `_build/` |
| `just bundle` | `bun build` the chrome into `frontend/dist/` (with the static CSS) |
| `just serve` | Build, then run the Hono server with Bun (`PORT`, `DATABASE_URL`) |
| `just watch` | Recompile on change (pair with `just serve` in another terminal) |
| `just test` | Run the Melange test suite under Bun |
| `just fmt` / `just fmt-check` | ocamlformat via dune |
| `just lint` | Warnings-as-errors compile + the zero-JavaScript check |
| `just verify` | `fmt-check` + `lint` + `test` + `build` |

Environment (see [`.env.example`](.env.example)): `PORT` (default 4310; never hard-code 4173), `DATABASE_URL` (`file:data/cvzengarden.sqlite` or a `libsql://` Turso URL), `DATABASE_AUTH_TOKEN` (Turso), `RZ_SEED_DEMO` (seed three review-queue examples when the store has no submissions).

---

## Routes and API

| Route | Page |
| --- | --- |
| `/` | Garden — hero, theme picker, live sheet. Theme and view live in the URL (`?theme=quarto&view=paper`). |
| `/gallery` | Every theme on the same Skeleton, plus the review queue. |
| `/about` | Manifesto, staged theme, how to contribute. |
| `/studio` | Paste / upload / import a JSON Resume, live preview, Save as PDF. Résumé data stays in the browser. |
| `/workbench` | Drop a `theme.css`, live preview, contract diagnostics, submit to the review queue. |

| Endpoint | Purpose |
| --- | --- |
| `GET /api/themes`, `GET /api/themes/:id` | Theme metadata (official + approved + in review) |
| `GET /themes/:id.css` (alias `/api/themes/:id/css`) | The stylesheet — first-party from `themes/`, submissions from the store |
| `POST /api/render[?theme=id]` | JSON Resume → Skeleton document (`400` with a JSON path on bad input) |
| `POST /api/lint` | Contract diagnostics for a stylesheet |
| `GET/POST /api/submissions` | The review queue; a submission is linted and rejected with `422` if a check fails |
| `GET /api/samples/:name` | `junior` (Sam Okoro) and `jordan` (the long fixture) |

---

## Repository map

```
shared/      OCaml domain library shared by chrome, API and tests
frontend/    Melange → SolidJS chrome; static/ holds index.html and the CSS
backend/     Melange → Hono API and server entry (main.ml); lib/ has bindings, store, routes
test/        Melange tests (run with `just test`)
skeleton/    HTML class contract, golden output, JSON Resume fixtures
themes/      Designer-submitted .css files (one file = one theme) and the Font Library seed
converter/   Bridge dialect notes and fixtures (SchemaResume, UniversalResume)
docs/        Personas and roadmap material
qa/          Market quality bar
```

---

## The class contract is the product

Themes, the renderer, ATS parsers, and AI generators all depend on:

- **JSON Resume** as the only stored/pasted data shape.
- Semantic, ATS-friendly markup (real headings, lists, links, `<time datetime>`).
- A documented, **namespaced** class list (`rz-*`) so theme CSS cannot collide with product chrome.

Read [`skeleton/CLASS-CONTRACT.md`](skeleton/CLASS-CONTRACT.md). Open [`skeleton/example.html`](skeleton/example.html) in a browser. A designer can write a theme against the HTML contract from that file alone; the Workbench tells them whether it passes.

## Design two worlds

| Surface | Constraint |
| --- | --- |
| **Product chrome** (Garden, Gallery, Studio, Workbench, drawer) | Organic design system: tokens in `frontend/static/assets/organic.css`, site classes in `chrome.css`. Never hard-code a value a token carries. |
| **Resume themes** (`themes/*.css`) | Unconstrained. Target `rz-*` only. Pure CSS. |

Chrome classes never use the `rz-` prefix. Theme CSS must never assume chrome markup exists. Every résumé preview is an iframe (`srcdoc`, same-origin, no scripts) so theme CSS cannot leak into the product UI.
