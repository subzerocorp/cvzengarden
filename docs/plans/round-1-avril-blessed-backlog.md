# Blessed Backlog Summary — Round 1: make the Garden usable by five real people

**Date:** 2026-08-24
**Conductor:** AVRIL (Architect → PO → QA → CTO)
**Status:** All 23 active PBIs triple-blessed. AXEL intake satisfied (`avril-blessed` label). Pinto is source of truth.
**Intent:** `docs/plans/round-1-avril-intent.md` (persona round 0: `docs/persona-rounds/round-0/`)

## Intent

Five simulated users walked the Garden and none finished their goal. Round 1 = ROADMAP Phase 2 "Wear it" plus the un-gated parts of Phase 3 "Publish" and Phase 4 "Open the gate": an Author pastes their own résumé without knowing JSON Resume, starts from a sample, gets humane errors, prints, and publishes to a stable URL with an unguessable edit link; a Designer finds the contract, writes one CSS file, is credited and licensed, and submits through a visible path; the product answers privacy, retention, ownership, and price in plain language. Plus renderer, print, and harness debt the walks exposed.

## Board (source of truth)

```text
pinto list
pinto show ZG-<n>
```

Project `resumezen`, key `ZG`. DoD in `.pinto/dod.md`. Readiness = `todo` and every `depends_on` is `done` (no `pinto next` in 0.2.0).

## Blessed PBIs (ordered)

| ID | Title | Labels | Deps |
|---|---|---|---|
| ZG-1 | Make the renderer pass clippy pedantic so just verify is green | harness | — |
| ZG-23 | Make the S1 cold-load FOUC probe deterministic with a painted-frame oracle | harness | — |
| ZG-2 | Never panic on a wild date: tolerate timestamps, drop unparseable dates | renderer | ZG-1 |
| ZG-3 | Render wild JSON Resume files: numeric score, url-only entries, CRLF, bad URLs | renderer | ZG-1, ZG-2 |
| ZG-4 | Run the Renderer in the browser via Wasm and prove it matches the crate | renderer, chrome | ZG-1 |
| ZG-7 | Rewrite the chrome in plain language with an About panel and a free-during-preview line | chrome | — |
| ZG-8 | Copy a link to this exact view and say so when a theme in the URL does not exist | chrome | — |
| ZG-9 | On a phone show the résumé first and fold the controls into a Theme button | chrome | — |
| ZG-11 | Print a real résumé without blank pages, lost bullets, or pale ink | themes | — |
| ZG-12 | Fit long names in Nightgarden, paint sections without scrolling, keep bullet line breaks | themes | ZG-11 |
| ZG-13 | Self-host first-party theme fonts so a résumé page never calls jsDelivr | themes | — |
| ZG-16 | Credit the Designer with name and link on every theme card | designer | — |
| ZG-15 | Try a local CSS file in the real switcher without a build | designer | — |
| ZG-17 | Add the repo LICENSE and state the theme-contribution license terms | designer, docs | ZG-16 |
| ZG-10 | Show an honest page count in print preview and how to save a PDF | chrome | ZG-7 |
| ZG-14 | Serve and link the designer kit: sample HTML, contract, blank CSS, second sample | designer | ZG-7 |
| ZG-5 | Paste or open your own JSON Resume and see it in every Theme | chrome | ZG-2, ZG-3, ZG-4 |
| ZG-6 | Explain the résumé format in plain words and start from a sample | chrome | ZG-5 |
| ZG-18 | Give Designers a visible submit path with a stated review turnaround | designer, docs | ZG-14, ZG-17 |
| ZG-19 | Put the print-honesty rule, a full blank scaffold, and contract fixes where designers look | designer, docs | ZG-14, ZG-16, ZG-17 |
| ZG-20 | Ship npm run lint-theme so a Designer knows pass or fail before opening a PR | designer | ZG-19 |
| ZG-21 | Publish a résumé to a stable public URL with an unguessable edit link (API) | backend | ZG-2, ZG-3 |
| ZG-22 | Publish, copy your link, delete — with plain answers to who can see it | chrome | ZG-5, ZG-8, ZG-21 |

**23 PBIs.** Points omitted. AXEL ordering from PO/CTO set-level notes: harness first (ZG-1, ZG-23); ZG-11 → ZG-12 before walking Marcus; ZG-13 before any hosted page is walked; ZG-5 and ZG-6 back to back (never walk Priya/Elena between them); designer lane ZG-16 → ZG-17 → ZG-14 → {ZG-18, ZG-19} → ZG-20; ZG-3's `dir="auto"` regenerates every crate-output lock.

## Explicit cuts

Accounts, payments, custom subdomains/HTTPS (issue #9), PDF pipeline, AI-generated themes, LinkedIn import, form editor, Bridge dialects (SchemaResume/UniversalResume), gallery-as-catalog, second skeleton, JS in themes, retry/skip in probes, pixel rasterisation oracles, Postgres, a hosted-page Designer credit (switcher credit only this round), removing Nightgarden's rise animation.

## Coverage

Every round-0 complaint theme A1–F6 maps to a PBI `## Covers` or a reasoned `## Scope out` (matrix: `docs/plans/round-1-avril-generator-round1.md`, updated in rounds 2–8).

## Human decisions

| Topic | Status |
|---|---|
| License (ZG-17) | **Decided 2026-08-24:** code MIT; themes CC BY 4.0; `Copyright (c) 2026 Nathan Sculli`; README credit "sponsored with love by SubZero Corp". |
| Fonts (ZG-13) | **Decided 2026-08-24:** Font Library (anyone may submit original fonts, inbound CC BY 4.0; OFL seeds keep OFL). First-party Themes self-host from origin. Submitted Themes may also `@font-face` any public HTTPS CDN font — **no host allowlist**; CSS only, no JS loader. Record: `docs/plans/fonts-decision.md`. ZG-13 execution stays first-party vendoring + README policy; Font Library *submit product* is a later AVRIL PBI. |
| Schema validator crate (ZG-6), `sha2`/`rand` (ZG-21), retention wording (ZG-22), review turnaround (ZG-18), backend host / deploy path after ZG-4 | Pending grill; AXEL proceeds under the assumption stated in each PBI's `## Notes` and flags it. |

## Blessing log

- Gen 1: ZG-1…ZG-22. PO 1: REJECT ZG-6, ZG-10, ZG-17. Gen 2 (ZG-6/10/17/19). PO 2: BLESS ×4.
- QA 1 (19 items): REJECT 13. Gen 3 (13 + fixture owners). PO 3: BLESS ×13. QA 2 (ZG-6/10/17): REJECT ×3. Gen 3b. PO 4: BLESS ×3.
- QA 3 (13): REJECT ZG-11/12/13/19/20/21. QA 4 (ZG-6/10/17): REJECT ZG-17. Gen 4 / 4b. PO 5: BLESS ×7. QA 5: REJECT ZG-11/12/20.
- CTO 1 (15 items): BLESS ×15. Gen 5 (ZG-11/12/20). CTO 2 (ZG-13/17/19/21): REJECT ZG-19, ZG-21. Gen 6. PO 6 / 6b: BLESS ×5. QA 6: REJECT ZG-11/20; QA 6b: BLESS ZG-19/21. CTO 3 / 3b: BLESS ZG-19/21/12.
- Gen 7: ZG-23 proposed. PO/QA 7: BLESS; CTO 7: REJECT. Gen 8 (ZG-11/20); Gen 9 (ZG-23). PO/QA/CTO 8: BLESS ZG-11/20. PO/QA/CTO 9: BLESS ZG-23.

`<id>: PO BLESS | QA BLESS | CTO BLESS` for every active round-1 PBI.

AVRIL stop for round 1. Handoff is AXEL (already running: ZG-1 in `review`, ZG-23 `in-progress`).
