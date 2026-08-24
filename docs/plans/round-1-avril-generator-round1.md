# AVRIL round 1 — Generator proposal (cycle 0)

**Generator:** `planning-architect-agent` · **Date:** 2026-08-23 · **Board:** Pinto `ZG` (labels `avril`, `round-1`)
**Intent:** `docs/plans/round-1-avril-intent.md` · **Inputs read in full:** the five round-0 reports, CONTEXT, ROADMAP, MARKET-QUALITY-BAR, AGENTS, CLASS-CONTRACT, themes/frontend/backend/converter READMEs, `Main.elm`, `ports.js`, `generate.mjs`, renderer sources, historical RZ backlog.

This is a proposal. Nothing here is BLESSed. PO → QA → CTO attack it item by item.

## Proposed order

Ready at start (no deps): ZG-1, ZG-7, ZG-8, ZG-9, ZG-11, ZG-12, ZG-13, ZG-15, ZG-16, ZG-17, ZG-19. Suggested first picks for AXEL: **ZG-1** (unblocks the matrix), **ZG-7**, **ZG-11**, **ZG-17**.

| id | Title | Covers | Deps |
| --- | --- | --- | --- |
| ZG-1 | Make the renderer pass clippy pedantic so `just verify` is green | harness | — |
| ZG-2 | Never panic on a wild date: tolerate timestamps, drop unparseable dates | D1, D3 | ZG-1 |
| ZG-3 | Render wild JSON Resume files: numeric score, url-only entries, CRLF, bad URLs | D2, D4, D5 | ZG-1 |
| ZG-4 | Run the Renderer in the browser via Wasm and prove it matches the crate | (enables A1) | ZG-1 |
| ZG-5 | Paste or open your own JSON Resume and see it in every Theme | A1, A4 | ZG-2, ZG-3, ZG-4 |
| ZG-6 | Explain the résumé format in plain words and start from a sample | A2, A3, C8 (sample) | ZG-5 |
| ZG-7 | Rewrite the chrome in plain language with an About panel and a free-during-preview line | F1, F2, B3 | — |
| ZG-8 | Copy a link to this exact view and say so when a theme in the URL does not exist | F3, F4 | — |
| ZG-9 | On a phone show the résumé first and fold the controls into a Theme button | F5 | — |
| ZG-10 | Show an honest page count in print preview and how to save a PDF | E4 | ZG-7 |
| ZG-11 | Print a real résumé without blank pages, lost bullets, or pale ink | E1, E2, E3 (print ink) | — |
| ZG-12 | Fit long names in Nightgarden, paint sections without scrolling, keep bullet line breaks | E3 (name, rz-rise), D5 (highlight `\n`) | — |
| ZG-13 | Self-host first-party theme fonts so a résumé page never calls jsDelivr | F6, C8 (font allowlist) | — |
| ZG-14 | Serve and link the designer kit: sample HTML, contract, blank CSS, second sample | C4, C8 (serve sample) | ZG-7 |
| ZG-15 | Try a local CSS file in the real switcher without a build | C5 | — |
| ZG-16 | Credit the Designer with name and link on every theme card | C2 | — |
| ZG-17 | Add the repo LICENSE and state the theme-contribution license terms | C3 | — |
| ZG-18 | Give Designers a visible submit path with a stated review turnaround | C1 | ZG-14, ZG-17 |
| ZG-19 | Put the print-honesty rule, a full blank scaffold, and contract fixes where designers look | C6, C8 (snippet), C7 (doc contradictions) | — |
| ZG-20 | Ship `npm run lint-theme` so a Designer knows pass or fail before opening a PR | C7 (lint) | ZG-19 |
| ZG-21 | Publish a résumé to a stable public URL with an unguessable edit link (API) | B1 (API) | ZG-2, ZG-3 |
| ZG-22 | Publish, copy your link, delete — with plain answers to who can see it | B1 (chrome), B2 | ZG-5, ZG-8, ZG-21 |

Graph is acyclic: `ZG-1 → {ZG-2, ZG-3, ZG-4} → ZG-5 → ZG-6`; `ZG-2, ZG-3 → ZG-21`; `ZG-5, ZG-8, ZG-21 → ZG-22`; `ZG-7 → {ZG-10, ZG-14}`; `ZG-14, ZG-17 → ZG-18`; `ZG-19 → ZG-20`. Everything else is a leaf.

## Coverage matrix (round-0 themes A1–F6)

| # | Theme | PBI(s) / cut |
| --- | --- | --- |
| A1 | No way to put your own résumé in | ZG-5 (ZG-4 is the render-side enabler) |
| A2 | Input format never explained; "JSON Resume" never named | ZG-6 |
| A3 | "Start from the sample" impossible; thin junior sample missing | ZG-6 |
| A4 | Humane errors (trailing comma, bad dates, half-filled sections) | ZG-5 (errors), ZG-2 (dates tolerated), renderer already omits empties |
| B1 | No hosted URL / Publish / Copy link | ZG-21 (API + public page), ZG-22 (chrome) |
| B2 | No privacy answers: who sees it, delete, retention, JSON ownership, footer link | ZG-22 (trust copy, Privacy panel, delete, download JSON); ownership sentence also in ZG-17 README |
| B3 | No price or "free" statement | ZG-7 ("Free during the preview. Pricing is not announced.") — no price invented (open question 4) |
| C1 | No submit path / CONTRIBUTING / turnaround | ZG-18 |
| C2 | Designers not credited; no portfolio link field | ZG-16 |
| C3 | No LICENSE; contribution license undefined | ZG-17 (human confirms; open question 3) |
| C4 | Designer assets 404 from the served site; chrome has zero links | ZG-14 |
| C5 | Cannot try a local CSS in the real switcher | ZG-15 |
| C6 | Print-honesty rule not in designer docs; `_blank.css` empty, no print scaffold | ZG-19 |
| C7 | No runnable lint; `content:`/font rules contradict across docs | ZG-20 (lint), ZG-19 (reconcile docs, mark old backlog historical) |
| C8 | §5.10 snippet wrapper; sample lacks `rz-photo`/`rz-score`; font allowlist unnamed | ZG-19 (snippet, allowlist sentence), ZG-6 (junior sample has photo + score), ZG-14 (serves it), ZG-13 (allowlist = any https, self-host preferred) |
| D1 | Renderer panics on non-ASCII startDate | ZG-2 |
| D2 | Numeric `score` rejects the document | ZG-3 |
| D3 | Timestamp dates dropped; invalid `<time datetime>`; Feb 30; `rz-is-current` on bad start | ZG-2 |
| D4 | Certificate with only `url` → empty `<li>` | ZG-3 |
| D5 | CRLF, empty/`javascript:` URLs, emoji slugs, no `dir`, profile without url, highlight `\n`, `work.description` | ZG-3 (all but two); ZG-12 (highlight `\n` via `white-space: pre-line`); **cut:** `work.description` — contract 1.0 §5.4 says not rendered; changing the field map is a contract bump, not a bug fix (reason recorded in ZG-3 scope out) |
| E1 | Section-level `break-inside: avoid` leaves page 1 blank; forced break before Projects | ZG-11 |
| E2 | Switchyard loses bullet markers in print | ZG-11 |
| E3 | Nightgarden: long names overflow; pale print ink; `rz-rise` hides sections | ZG-12 (name, rz-rise), ZG-11 (print ink) |
| E4 | Print preview not paginated, no page count, no Save-as-PDF hint | ZG-10 (estimate + guide lines + hint); **cut inside it:** true paginated sheets (needs a paged-media polyfill = third-party runtime) |
| F1 | Developer jargon in sidebar; "CHROME"; no Help/About | ZG-7 |
| F2 | Two "Print" controls; WEB/PRINT/BOTH badges scare | ZG-7 |
| F3 | Unknown `?theme=` silent fallback | ZG-8 |
| F4 | No Copy link; view not in URL | ZG-8 |
| F5 | Mobile: controls first | ZG-9 |
| F6 | First-party themes hotlink jsDelivr | ZG-13 |

Nothing is left uncovered. Human open questions from the intent that PBIs touch: license (ZG-17), retention/free wording (ZG-22, ZG-7), turnaround number (ZG-18), non-allowlisted crates/assets (ZG-6 `ajv` dev-only, ZG-13 font binaries, ZG-21 `sha2` + `rand`).

## Design decisions the adversaries should attack

1. **Render side.** Paste renders **in the browser via Wasm** (ZG-4): zero network, works on the static Netlify build, keeps "nothing leaves your browser" literally true. Hosted pages render **on the server** (ZG-21) from the stored JSON with the *same* crate — crawlers and link previews get real HTML, no JS. There is deliberately no `/api/render` endpoint (one render path per surface, no duplicate). Cost: `wasm-pack` in the frontend build; Netlify's image lacks Rust, so production deploy needs a Rust build step or a CI artifact — deployment is a human step and out of AC.
2. **Hosted-URL shape.** `POST /api/resumes` → `/r/{id}` with a 10-char base32 random id (no vanity slugs: without accounts a `/priya` slug cannot be reclaimed or disputed). A 32-char edit key, returned once and stored hashed, is the account substitute (lock 10): `PUT`/`DELETE`/`GET`-JSON require it; wrong key → 404 (no existence leak). Public page is the bare Skeleton + theme `<link>`, `noindex`, `no-store` — "only people with the link". Deleted → 410 "taken down". No expiry automation this round; the trust copy says "kept until you delete it; this is a preview" and the human owns the final wording. Backend serves `frontend/dist` so personas run one process locally; libSQL file locally, Turso by env.
3. **License stance.** Root `LICENSE` MIT (what the themes already declare); collapse `renderer/Cargo.toml` from `MIT OR Apache-2.0` to `MIT`. Contributed themes: **MIT or CC BY 4.0**, commercial hosting explicitly allowed, attribution guaranteed in the switcher; **CC BY-NC-* rejected** because job seekers will pay for hosted pages. Human sign-off required (intent open question 3).
4. **Contract stability.** ZG-2/ZG-3 add `dir="auto"`, `<span class="rz-date">` for unparseable dates and `<span class="rz-link-value">` for url-less profiles inside *existing* classes and call that non-breaking under §9 (no rename, no new class). CTO may demand `data-rz-schema` 1.1 instead. `work.description` stays unrendered for the same reason.
5. **Lint rule for `content:`.** ZG-20 operationalises "decorative only" as: a `content:` string with a run of 3+ letters fails; glyphs, punctuation, `counter()`, `attr()` pass. This is stricter than BAR-X2's separator list in one direction (counters allowed) and looser in another (any glyph). QA to confirm.
6. **Print preview stays a preview.** ZG-10 gives an estimate ("About N pages (Letter)") and guide lines outside the sandbox rather than true pagination; a paged-media polyfill would be a third-party runtime and a second render path.
7. **Retention / pricing copy.** No price, no expiry policy invented. ZG-7 says "Free during the preview. Pricing is not announced."; ZG-22 says "Kept until you delete it… This is a free preview." Both flagged for the human.
8. **Splitting.** B1 is two PBIs (API with curl-demoable outcome; chrome) to stay under the review bar. A1 is two (Wasm enabler; paste UI). Themes are two (print discipline; screen fixes). Designer path is seven small items because Devon and Mika each need a different first fix.

## Third-party additions needing human approval (outside the pre-approved list)

| PBI | Addition | Why | Std-lib alternative |
| --- | --- | --- | --- |
| ZG-6 | `ajv` (dev only) | validate the junior sample against resume-schema | hand-written shape checks (weaker) |
| ZG-13 | ~10 OFL woff2 files | self-host fonts | keep CDN (fails BAR-L1 spirit / F6) |
| ZG-21 | `sha2`, `rand` (or `getrandom`) | hash edit keys, random ids | `std::hash` is not cryptographic — rejected |
