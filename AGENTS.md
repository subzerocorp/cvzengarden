# ResumeZen — agent rules

ResumeZen (`cvzengarden.com` / `resumezengarden.com`) is a CSS Zen Garden for résumés. Vocabulary lives in [`CONTEXT.md`](CONTEXT.md); do not invent synonyms. The product plan is [`ROADMAP.md`](ROADMAP.md). The quality bar is [`qa/MARKET-QUALITY-BAR.md`](qa/MARKET-QUALITY-BAR.md).

## Plan Mode

- Make every plan extremely concise. Sacrifice grammar for scannability.
- At the end of each plan, give a bulleted list of unresolved questions.
- Always follow the Plan → Execute → Test → Commit loop defined in the crossr-skills `HARNESS-SPEC.md`.

## Skills (crossr-skills, `/Users/nathansculli/src/crossr-skills/.agents/skills/`)

- `code-writer` — always on.
- `avril` — planning GAN (Architect → PO → QA → CTO, explicit `BLESS`). Planning only.
- `axel` — execution loop (blessed PBI → PETC + code GAN). Conductor never writes code.
- Rust (`renderer/`, `backend/`): `rust-code-writer`, `rust-errors`, `rust-axum-backend`; adversaries `rust-code-reviewer` → `rust-code-tester` → `rust-architect`.
- Elm chrome (`frontend/`), theme CSS (`themes/`), probes: `code-writer` Generator; adversaries are the same three personas applied to Elm/CSS/JS (reviewer → tester → architect).

Personas: `/Users/nathansculli/src/crossr-skills/.agents/agents/`.

## Stack (locked — see README "Stack")

| Layer | Choice |
| --- | --- |
| Data | JSON Resume only. Bridge dialects import/export, never stored. |
| Renderer | Rust crate `renderer/` (`resumezen_renderer::render`). Pure. Also compiled to Wasm for the chrome when a PBI needs it. |
| Chrome | Elm + vanilla CSS in `frontend/`. Never uses the `rz-` prefix. Sandboxed Skeleton in an iframe. |
| Themes | One pure `.css` file each in `themes/`, targeting `skeleton/CLASS-CONTRACT.md` only. |
| Store / API | Rust + Axum in `backend/`; SQLite via libSQL, Turso in production. |

No Tailwind, no CSS-in-JS, no JS in themes, no second Skeleton.

## Board

Pinto is the only board: `.pinto/` (project `resumezen`, key `ZG`). All board I/O is the `pinto` CLI (`pinto list --json`, `pinto show ZG-n --json`, `pinto next --json`, `pinto add`, `pinto edit`); never hand-edit `.pinto/tasks/*.md`. Older `RZ-*` ids in `docs/planning/` and the GitHub PRs are historical planning; new PBIs are `ZG-*`.

## Verification matrix

```bash
just check    # cargo check (renderer, backend)
just fmt      # cargo fmt --check
just clippy   # cargo clippy pedantic, -D warnings
just test     # cargo test + frontend probes (PROBE_PORT, default 4310)
```

Port `4173` is often held by an unrelated local process. Never hard-code it; use `PROBE_PORT` / `PORT`.

## Persona loop (this branch)

After each blessed PBI lands, five simulated users walk the product (`docs/personas/`): Mika, Devon (designers); Priya, Marcus, Elena (job seekers). Their complaints are the next AVRIL intent. The loop ends when every persona reports zero complaints and no walk-away trigger fired. Reports live in `docs/persona-rounds/round-N/`.

## Git

- Work on `garden/persona-loop`. Small, reviewable commits referencing the PBI id (`ZG-n phase k: …`).
- Do not push or open PRs unless the human asks.
- Append to `progress.md` after every commit; never rewrite history there.
