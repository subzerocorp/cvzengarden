# ResumeZen — agent rules

ResumeZen (`cvzengarden.com` / `resumezengarden.com`) is a CSS Zen Garden for résumés. Vocabulary lives in [`CONTEXT.md`](CONTEXT.md); do not invent synonyms. The product plan is [`ROADMAP.md`](ROADMAP.md). The quality bar is [`qa/MARKET-QUALITY-BAR.md`](qa/MARKET-QUALITY-BAR.md). How to build and run: [`README.md`](README.md).

## Plan mode

- Make every plan extremely concise. Sacrifice grammar for scannability.
- Break work into small, independently reviewable chunks.
- End each plan with a bulleted list of unresolved questions.

## Stack (locked by [`docs/decisions/2026-09-12-stack-unlock.md`](docs/decisions/2026-09-12-stack-unlock.md) — see README "Stack")

| Layer | Choice |
| --- | --- |
| Language | **OCaml, compiled by Melange. Zero hand-written JavaScript.** `just no-js` fails the build if a `.js`/`.mjs`/`.ts` file or an inline `<script>` is committed. JS interop is written as `external` bindings in OCaml; `[%mel.raw]` is forbidden. |
| Data | JSON Resume only. Bridge dialects import/export, never stored. |
| Shared | `shared/` — Resume decoder, Skeleton renderer (pure, byte-locked against `skeleton/`), dates, safe hrefs, theme linter, theme metadata. Used by chrome, API and tests. |
| Chrome | `frontend/` — Melange → SolidJS via hyperscript (`frontend/src/h.ml`), no JSX. Vanilla CSS with the Organic tokens. Never uses the `rz-` prefix. Skeleton sandboxed in an iframe. |
| API | `backend/` — Melange → Hono, run by Bun. Handlers decode → pure calculation → respond. |
| Store | SQLite through `@libsql/client`: `file:` locally and in tests (`:memory:`), Turso in production (`DATABASE_URL` + `DATABASE_AUTH_TOKEN`). |
| Themes | One pure `.css` file each in `themes/`, targeting `skeleton/CLASS-CONTRACT.md` only. |
| Runtime | Bun for the local server, the bundler (`bun build`), the tests and the probes. Production is a Cloudflare Worker (`backend/worker.ml`, `wrangler.toml`, `just deploy`). |

No Tailwind, no CSS-in-JS, no JS in themes, no second Skeleton, no new npm dependency without approval.

## Code shape

- Separate Data (types), Calculations (pure functions in `shared/` and the page view-models) and Actions (`Web`, `Bun`, `Libsql`, `Hono` bindings; signal setters).
- Encode invariants in types: `Theme_meta.target`, `View_mode.t`, `Route.page`, `Theme_lint.status`.
- Hyperscript thunks build their element once — a node value is used once; write icons and components as functions.
- A Solid signal holds data, never a closure (the setter would treat it as an updater).
- Reactive reads belong inside getters (`H.dyn`, `H.show`); the page switch reads only `Store.page`.
- Non-ASCII string literals use `{js|…|js}`.
- Chrome never restyles an `rz-*` node, not even in a preview overlay: Paper view is print-media emulation (`Print_media`), and chrome-owned ids and storage keys use the `resumezen` prefix.
- Browser probes use Playwright's locator API only; `page.evaluate` would smuggle JavaScript source into the repository.

## Verification matrix

```bash
just fmt-check   # ocamlformat (dune fmt)
just lint        # warnings-as-errors compile + zero-JavaScript check
just test        # Melange test suite under Bun (renderer parity, calculations, linter, HTTP API)
just build       # dune build + bun build → frontend/dist
just probe       # Playwright probes (OCaml bindings in probes/) against a server the runner starts
just verify      # all of the above
```

Port `4173` is often held by an unrelated local process. Never hard-code it; use `PORT` (default 4310).

## Board

All project tracking happens in the Linear project **ResumeZen** (team NAT): https://linear.app/scull7/project/resumezen-9ac99e308ed9. Open work is a Linear issue, not a TODO or a `progress.md` bullet; reference the issue key (`NAT-n`) in commits and PRs. `progress.md` stays a changelog.

## Git

- Small, reviewable commits with descriptive messages.
- Append to `progress.md` after meaningful changes; never rewrite history there.
