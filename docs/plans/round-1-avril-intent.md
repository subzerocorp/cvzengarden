# AVRIL Intent — Round 1: make the Garden usable by five real people

**Status:** Human-authorized intent (the user asked for an AVRIL → AXEL → persona-walk loop until all five personas have zero complaints). Not a backlog. Not AXEL authorization.
**Date:** 2026-08-23
**Workspace:** `/Users/nathansculli/src/subzero/cvzengarden`, branch `garden/persona-loop`
**Product:** ResumeZen (`cvzengarden.com` / `resumezengarden.com`). Vocabulary: `CONTEXT.md`. Plan: `ROADMAP.md`. Quality bar: `qa/MARKET-QUALITY-BAR.md`.

AVRIL reads this file and stops at a triple-blessed backlog. Do not implement. Pinto is the only board.

---

## Conductor activation

Using `code-writer` + `avril`.

> "Run AVRIL — Architect proposes PBIs, Product Owner then QA Architect then Visionary CTO each explicitly BLESS or REJECT, revise until unanimous — and stop at a blessed backlog without writing implementation yourself."

| Parameter | Value |
|---|---|
| Generator | `planning-architect-agent` |
| Adversaries (fixed order) | PO → QA → CTO |
| Personas | `/Users/nathansculli/src/crossr-skills/.agents/agents/` |
| Skills | `code-writer` + `/Users/nathansculli/src/crossr-skills/.agents/skills/avril/SKILL.md` |
| Domain language | `CONTEXT.md` — do not invent synonyms. "Author" = job seeker; "Designer" = theme contributor. |
| Board | **Pinto is source of truth.** `.pinto/` (project `resumezen`, key `ZG`). `pinto list --json`, `pinto show ZG-n --json`, `pinto add`, `pinto edit`, `pinto dep add`. There is no `pinto next` in this version; readiness = `status == "todo"` and every `depends_on` id is `done`. Labels: `avril` on every item, `avril-blessed` only when all three BLESS. Round label: `round-1`. |
| Blessed output | Pinto + `docs/plans/round-1-avril-blessed-backlog.md` (summary + blessing log only) |
| Size | Small vertical slices, one demoable outcome each, reviewable in one short pass (< 10 min deep review, well under ~1500 LOC diff). Split anything bigger. |
| Historical ids | `RZ-2`, `RZ-3`, `RZ-5`, `RZ-S1…S5` are **done** (see `docs/planning/`, PRs #4–#10). `RZ-4`, `RZ-6…RZ-9` and `RZ-S6…S8` are historical planning, not blessed for this round; reuse their thinking, not their ids. |

---

## Intent (one paragraph)

The Garden already works on the sample résumé: one Skeleton (`rz-*` contract 1.0), a Rust Renderer, three first-party Themes (Nightgarden web / Quarto print / Switchyard both), an Elm Switcher with print preview, `?theme=` permalinks, paper-honest print on both print paths. Five simulated users walked it (round 0, `docs/persona-rounds/round-0/`) and none could finish their goal. This round's intent is **ROADMAP Phase 2 "Wear it" and the un-gated parts of Phase 3 "Publish" and Phase 4 "Open the gate"**, driven by those five walks: an Author can put their own résumé on the Skeleton without knowing what JSON Resume is, start from the sample, get humane errors, print it, and get a stable shareable URL for it; a Designer can find the contract, write one CSS file, see attribution/licensing/linkback rules, and submit through a visible path with a stated review turnaround; and the product answers the trust questions (who can see this, can I take it down, how long does it live, who owns the data, what does it cost) in plain language. Every complaint in round 0 must map to a PBI, a `scope_out` line with a reason, or a human decision in the open-questions table.

---

## Locked decisions (do not reopen)

| # | Decision | Source |
|---|---|---|
| 1 | JSON Resume is the only stored Resume. Bridge dialects import/export only. | CONTEXT.md, ROADMAP principle 6 |
| 2 | One Skeleton, `rz-*` HTML contract 1.0. Additive classes need a contract bump; renames are breaking. | CLASS-CONTRACT.md §1, §8 |
| 3 | A Theme is one pure `.css` file; declares `/* rz-target: web\|print\|both */`; no JS, no Tailwind, no extra HTML; résumé words never only in `content:`. | CLASS-CONTRACT.md §1, ROADMAP principle 3, BAR-X2 |
| 4 | Motion is for screens; print must be paper-honest even for web Themes (BAR-U3). A dark web Theme prints light. | ROADMAP principle 4, RZ-S3 |
| 5 | Chrome is Elm + vanilla CSS, GPUI tokens, never `rz-*`, Skeleton sandboxed in an iframe. | frontend/DESIGN.md, RZ-3 |
| 6 | Renderer is a pure Rust crate; may run server-side or in the browser via Wasm. | ROADMAP stack table |
| 7 | Store is SQLite: libSQL locally, **Turso** in production (org `scull7`, group `cvzengarden`, db `cvzengarden`). No Postgres. No committed `.db` as production. | CONTEXT.md, RZ-6 |
| 8 | Job seekers pay for a **hosted page + print**, never for an HTML/CSS download (BAR-X1, BAR-J1). Download may exist as a side effect, never as the headline. | ROADMAP, qa bar |
| 9 | Designers target web, print, or both; submissions are reviewed by humans at first (a PR is enough); lint for `rz-*` selectors, forbid script. | ROADMAP Phase 4 |
| 10 | Accounts, payments, custom subdomains, PDF pipeline, AI-generated themes, LinkedIn import are Phase 5 or later — **not this round** unless a persona blocker cannot be met without them, in which case the PBI names the thinnest substitute (e.g. an unguessable edit link instead of an account). | ROADMAP Phases 3–5 |
| 11 | No second HTML skeleton, no JSON Resume Handlebars themes, no ATS vendor adapters, no job board. | ROADMAP "not doing" |
| 12 | Binding quality priority: Independent Product Experience Guardian — ease of use, look and feel, consistency, category-leading. | BAR-Q1 |

---

## Repo facts

- Tree: `skeleton/` (contract, `example.html`, `resume.json`), `renderer/` (Rust, 19 tests green; **fails `clippy::pedantic`** — 11 findings), `themes/` (3 + `_blank.css`), `frontend/` (Elm 0.19.1, `npm test` = 60 Playwright probes green on `PROBE_PORT`), `backend/` (README only), `converter/` (mapping docs + fixtures, no code), `ai/` (README only), `qa/MARKET-QUALITY-BAR.md`, `docs/`.
- Harness: `AGENTS.md`, `justfile` (`just verify` = fmt + clippy pedantic + cargo test + frontend probes), `features.json`, `progress.md`, `.pinto/` key `ZG` with DoD.
- No `LICENSE` file at the repo root. Theme headers say `License: MIT` for first-party themes; `_blank.css` suggests CC BY-NC-SA or MIT for contributors.
- Deploy: Netlify static site (manual deploys, no linked repo). No Rust host is authenticated (`cargo shuttle`, `fly`) and `turso` CLI is not logged in. **Therefore:** backend PBIs must run and be tested locally (libSQL file / in-memory), with production Turso wired by environment variables, and must not require a live deploy for AC evidence. Personas walk a local build.
- Third-party dependencies implied by the locked stack are pre-approved by the roadmap: `axum`, `tokio`, `tower-http`, `libsql` (or `rusqlite` for the local adapter only if libSQL cannot run locally — name it), `serde`/`serde_json`, `thiserror`, `wasm-bindgen`/`wasm-pack` if the Renderer goes to the browser. Anything else goes in the PBI `notes` for human approval; do not bless a crate as the product.
- Rust code must pass `clippy::pedantic` with `-D warnings`; `thiserror` only (no `anyhow`); Grokking-Simplicity stratification (calculations pure, actions isolated).

---

## Persona findings (round 0)

Filled from `docs/persona-rounds/round-0/*.md`. The Generator must read every report in full; the table below is the conductor's index, not a substitute.

| Persona | Walk-away | Goal | Report |
|---|---|---|---|
| Priya (job hunter) | **yes** — no way to enter her résumé; left at 8 min | no | `docs/persona-rounds/round-0/priya.md` |
| Elena (first-timer) | no (nowhere to type, so no cryptic error yet) | no | `docs/persona-rounds/round-0/elena.md` |
| Marcus (JSON native) | no | no | `docs/persona-rounds/round-0/marcus.md` |
| Mika (designer) | no | partially | `docs/persona-rounds/round-0/mika.md` |
| Devon (dev/designer) | **yes** — finished a theme, no submission or review path | partially | `docs/persona-rounds/round-0/devon.md` |

Consolidated complaint themes (severity = highest any persona gave it):

| # | Theme | Sev | Raised by | Notes |
|---|---|---|---|---|
| A1 | No way to put your own résumé in (no paste/upload/edit control); site only shows Jordan Hale | blocker | Priya, Elena, Marcus | README promises paste; ROADMAP Phase 2 |
| A2 | Input format never explained in plain language with a copyable example; "JSON Resume" never named on the site | blocker | Priya | JSON-literacy test |
| A3 | "Start from the sample" is impossible except View Source → hand-edit; a thin junior sample is missing | major | Elena | |
| A4 | Humane errors for trailing commas, wrong date formats, half-filled sections — currently untestable (no input) | blocker-in-waiting | Elena | walk-away trigger |
| B1 | No hosted/personal URL, no Publish / Copy link | blocker | Priya, Marcus, Elena | ROADMAP Phase 3; must be hosted-plus-print, not export-HTML (BAR-X1/J1) |
| B2 | No privacy answers: who can see it, take-down/delete, retention of anonymous pastes, JSON export/ownership, no footer/privacy link | major | Priya, Marcus | |
| B3 | No price or "free" statement anywhere | blocker | Elena | open question 4: honest "free during preview" only |
| C1 | No visible submit/contribute path, no CONTRIBUTING, no review turnaround stated | blocker | Mika, Devon | BAR-D1; ROADMAP Phase 4 |
| C2 | Designers are not credited in the switcher (Author: header discarded), no portfolio link field | blocker | Mika | generate.mjs parseTheme |
| C3 | No LICENSE at repo root; theme-contribution license/commercial-hosting terms undefined | major | Mika, Marcus | open question 3 |
| C4 | Designer assets unreachable from the served site: /skeleton/example.html, CLASS-CONTRACT, /themes/_blank.css 404; chrome has zero links | major | Mika, Devon | BAR-D1 |
| C5 | Cannot try a local CSS file in the real switcher without npm + Elm build | major | Mika | |
| C6 | "Print must be light ink on white, motion off" rule and its why are not in designer-facing docs; _blank.css has no @media print scaffold; _blank.css is one empty selector | major | Devon, Mika | BAR-U3 |
| C7 | No runnable lint for a contributed theme; content:/font rules contradict across CLASS-CONTRACT, BAR-X2/L1, old backlog | minor | Devon, Mika | |
| C8 | Contract nits: §5.10 snippet omits .rz-skill-groups wrapper; sample lacks rz-photo / rz-score; font allowlist unnamed | minor | Mika | |
| D1 | Renderer **panics** on non-ASCII startDate (slug.rs byte index) | major | Devon | |
| D2 | Numeric `education[].score` (3.7) rejects the whole document | major | Marcus | wild files must be valid |
| D3 | `releaseDate` with time component silently drops the date; unparseable dates emit invalid `<time datetime>` / keep rz-is-current; Feb 30 accepted | major/minor | Marcus, Devon | |
| D4 | Certificate with only `url` emits an empty `<li>` (violates omit-empties) | major | Devon | |
| D5 | Renderer minors: CRLF paragraphs, empty/`javascript:` profile URLs, emoji-only slugs, no `dir` for RTL, profile without url dropped, highlight `
` collapsed, work.description not rendered | minor | Devon, Marcus | |
| E1 | Section-level `break-inside: avoid` in Quarto/Switchyard leaves page 1 ~70% blank on real résumés; Switchyard forced break before Projects strands a page | major | Marcus, Priya, Mika | |
| E2 | Switchyard loses bullet markers in print | major | Priya, Elena | |
| E3 | Nightgarden: long names overflow the rail; pale secondary text in print; rz-rise hides sections until scrolled | major/minor | Marcus, Mika | |
| E4 | Print preview is not paginated and shows no page count; no "Save as PDF" hint | major/minor | Mika, Elena | |
| F1 | Sidebar copy is developer jargon ("One Skeleton…", "/* rz-target */", "@media print"), heading "CHROME", no Help/About | major | Priya, Elena | |
| F2 | Two controls both labelled "Print"; WEB/PRINT/BOTH badges scare people off printing web themes | minor | Priya, Mika, Elena | |
| F3 | Unknown `?theme=` silently falls back with no note | minor | Elena, Marcus, Devon | |
| F4 | No Copy-link/Share control; view (screen/print) not in URL | minor | Elena | |
| F5 | Mobile: controls first, résumé below the fold | major | Elena | |
| F6 | First-party themes hotlink jsDelivr fonts (privacy, offline print) | minor | Marcus, Mika | BAR-L1 |

What worked (keep): instant FOUC-free theme swap, `?theme=` permalinks + Back, print button prints only the résumé on both paths, Quarto looks professional, no account/paywall, renderer handles all 12 sections / escaping / long URLs / 4.8 MB input in 286 ms, contract is complete enough to write a full theme in one sitting, sandbox keeps theme CSS out of the chrome.


---

## Open questions (do not invent; put on PBI `notes` only if blocking)

1. **Backend host** for the Axum API (Shuttle? Fly? something else). Not locked; nobody is logged in. PBIs build and test locally; deployment is a human step and is out of AC.
2. **Turso credentials** — not available in this session. Production config is env-driven (`TURSO_DATABASE_URL`, `TURSO_AUTH_TOKEN`); local runs use a file/in-memory libSQL.
3. **Repo license** — the repo has none. A PBI may add the license the first-party themes already declare (MIT) for the code and state the theme-contribution license; if the human wants something else, that is a one-line change. Flag it in `notes`.
4. **Pricing** — Phase 5. Personas may only be told "free during preview" or an honest "pricing not announced"; no PBI invents a price.
5. **Custom domains / HTTPS** — GitHub issue #9, human-owned. Out of scope.

If a PBI cannot be accepted without answering one of these, **stop and ask the human** (via `notes` + conductor escalation). Do not pick a host, a price, or a license silently beyond item 3.

---

## AVRIL stop condition

When every active round-1 PBI has fresh PO → QA → CTO `BLESS`:

1. Write `docs/plans/round-1-avril-blessed-backlog.md`.
2. Label those items `avril-blessed` in Pinto.
3. Stop. Do not implement. Handoff is AXEL.

---

## Human decisions (recorded 2026-08-24)

| # | Question | Decision |
|---|---|---|
| 3 | Repo license / theme-contribution license / copyright holder | Code: **MIT**. Contributed and first-party themes: **CC BY 4.0** (license-enforced attribution; the Garden displays the Designer's name and link). `LICENSE`: `Copyright (c) 2026 Nathan Sculli`. README credits line: "sponsored with love by SubZero Corp". Cargo `MIT OR Apache-2.0` → align to MIT. |
