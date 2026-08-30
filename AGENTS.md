# ResumeZen — agent rules

ResumeZen (`cvzengarden.com` / `resumezengarden.com`) is a CSS Zen Garden for résumés. Vocabulary lives in [`CONTEXT.md`](CONTEXT.md); do not invent synonyms. The product plan is [`ROADMAP.md`](ROADMAP.md). The quality bar is [`qa/MARKET-QUALITY-BAR.md`](qa/MARKET-QUALITY-BAR.md).

## Plan Mode

- Make every plan extremely concise. Sacrifice grammar for scannability.
- At the end of each plan, give a bulleted list of unresolved questions.
- Always follow the Plan → Execute → Test → Commit loop defined in [`crossr-harness`](https://github.com/sycamore-hq/crossr-harness)'s `HARNESS-SPEC.md`.

## Upstream harness

Three repositories under [`sycamore-hq`](https://github.com/sycamore-hq) supply the harness. Clone them beside this repo; nothing here vendors them.

| Repository | Supplies | Path inside it |
| --- | --- | --- |
| [`crossr-harness`](https://github.com/sycamore-hq/crossr-harness) | `HARNESS-SPEC.md` — the PETC loop and §3.5 session ritual | repo root |
| [`crossr-skills`](https://github.com/sycamore-hq/crossr-skills) | craft skills: `code-writer`, `rust-*` | `.agents/skills/` |
| [`crossr-loops`](https://github.com/sycamore-hq/crossr-loops) | the `avril` / `axel` loops **and every adversary persona** | `.agents/skills/`, `.agents/agents/` |

## Skills

- `code-writer` — always on. (`crossr-skills`)
- `avril` — planning GAN (Architect → PO → QA → CTO, explicit `BLESS`). Planning only. (`crossr-loops`)
- `axel` — execution loop (blessed PBI → PETC + code GAN). Conductor never writes code. (`crossr-loops`)
- Rust (`renderer/`, `backend/`): `rust-code-writer`, `rust-errors`, `rust-axum-backend`; adversaries `rust-code-reviewer` → `rust-code-tester` → `rust-architect`. (`crossr-skills`)
- Elm chrome (`frontend/`), theme CSS (`themes/`), probes: `code-writer` Generator; adversaries are the same three personas applied to Elm/CSS/JS (reviewer → tester → architect).

Personas live in `crossr-loops/.agents/agents/` — `rust-reviewer-agent`, `rust-tester-agent`, `rust-architect-agent`, `qa-architect-agent`, `planning-architect-agent`, `product-owner-agent`, `visionary-cto-agent`, `axel-conductor-agent`. `crossr-skills/.agents/agents/` holds only the skill-authoring personas.

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
