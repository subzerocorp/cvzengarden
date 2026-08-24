# AVRIL round 1 — Generator revise pass (cycle 1b)

**Generator:** `planning-architect-agent` · **Date:** 2026-08-23 · **Board:** Pinto `ZG` (labels `avril`, `round-1`)
**Inputs read in full:** `docs/plans/round-1-avril-po-round1.md`, `docs/plans/round-1-avril-intent.md`, `docs/plans/round-1-avril-generator-round1.md`, `pinto show ZG-6 ZG-10 ZG-17 ZG-14 ZG-16 ZG-19 ZG-21 --plain`, `docs/persona-rounds/round-0/mika.md` (attribution rows), `renderer/src/emit.rs` and `skeleton/CLASS-CONTRACT.md` (to confirm `rz-photo` / `rz-score` already render).

Only the three PO blockers were applied. Non-blocking PO notes (ZG-5 copy, ZG-7 footer line, ZG-9 sheet contents, ZG-18 deploy cadence, ZG-21 hosted-page credit, ZG-22 edit-link Copy / fragment key, ZG-10 dep loosening, ZG-6 "name the format in ZG-5") were **not** applied; they carry to QA / CTO. Nothing is BLESSed by this document.

---

## ZG-6 — Explain the résumé format in plain words and start from a sample

**Blocker (PO):** bundles Mika's contract-coverage sample into Elena's thin starting sample; drop the photo/portrait from `junior.json`, move `rz-photo` / `rz-score` proofing to the designer kit or cut it with a reason.

**What changed**

- `junior.json` is now explicitly Elena's file: `basics` has **no `image`**, there is no `portrait.svg`, and the scope-in line says "nothing in the file a first-timer must delete by hand". The numeric `score: 3.7` stays (PO: a GPA is natural for a bootcamp grad).
- `junior.html` stays test-locked, but the stated reason is "the served sample cannot drift from the Renderer", not designer proofing.
- New scope-out line: a photo or any bundled image asset in the junior sample, with the reason and a pointer to where proofing went (ZG-19, `skeleton/samples/contract.json`).
- AC `ZG-6/start-junior` no longer asserts `img.rz-photo-img`; it asserts **no** `.rz-photo`. New AC: `grep -c '"image"' skeleton/samples/junior.json` prints `0` and ZG-6 adds no image file under `skeleton/samples/`.
- `## Why` and `## Covers` drop Mika and C8. Dependencies unchanged (ZG-5).

**Where the proofing went, and why ZG-19 rather than ZG-14.** The PO offered ZG-14 or ZG-19. The renderer already emits `rz-photo` / `rz-photo-img` (`emit.rs:114`) and `rz-score` (`emit.rs:669`); the only gap is that the byte-locked `example.html` never exercises them. That is a fixture-and-docs gap, which is what ZG-19 is: it already scaffolds every §6 selector into `_blank.css` with a node test that extracts the §6 inventory, so a superset sample that exercises the classes the locked sample omits is the same discipline on the HTML side. ZG-14 is a serve-and-link item and already copies `skeleton/samples/*.{html,json,svg}` when present, so it needs no change and keeps its blessing.

**Coverage matrix rows**

| # | Theme | PBI(s) / cut |
| --- | --- | --- |
| A2 | Input format never explained; "JSON Resume" never named | ZG-6 |
| A3 | "Start from the sample" impossible; thin junior sample missing | ZG-6 (junior sample: no photo, GPA kept) |
| C8 | §5.10 snippet wrapper; sample lacks `rz-photo`/`rz-score`; font allowlist unnamed | ZG-19 (snippet, allowlist sentence, **`skeleton/samples/contract.json` → `contract.html` proofing fixture**), ZG-14 (serves `skeleton/samples/*` unchanged), ZG-13 (allowlist = any https, self-host preferred) — ZG-6 no longer listed |

## ZG-10 — Show an honest page count in print preview and how to save a PDF

**Blocker (PO):** cut the page-boundary guide lines (unverifiable, misleading to Mika); ship the "About N pages" readout and the Save-as-PDF hint alone.

**What changed**

- Scope-in line 3 (guide-line overlay in `.garden-stage--print`) removed.
- New first scope-out line: "Page-boundary guide lines (an overlay at multiples of page height) — the preview is one unpaginated column, so an overlay cannot reflect where `break-inside: avoid` actually pushes content; a line that says 'the page breaks here' when it does not misleads exactly the print Designer (Mika, E1) this item serves. The readout can honestly say 'About'; a guide line cannot."
- AC `ZG-10/no-skeleton-injection` (which existed only to police the overlay) replaced by `ZG-10/no-guide-lines`: `.garden-stage--print` contains no overlay element and the iframe document contains nothing beyond the rendered Skeleton and the theme `<link>`. This makes the cut falsifiable rather than silent.
- `## Why`, `## Covers`, readout AC, paper-size AC, updates AC, hint AC unchanged. Dependency on ZG-7 unchanged (the PO's "need not gate" remark is non-blocking and not applied).

**Coverage matrix row**

| # | Theme | PBI(s) / cut |
| --- | --- | --- |
| E4 | Print preview not paginated, no page count, no Save-as-PDF hint | ZG-10 ("About N pages (Letter\|A4)" readout + Save-as-PDF hint); **cut inside it:** true paginated sheets (paged-media polyfill = third-party runtime) **and** page-boundary guide lines (an overlay cannot reflect `break-inside: avoid` pushes; a wrong break line misleads print designers) |

## ZG-17 — Add the repo LICENSE and state the theme-contribution license terms

**Blocker (PO):** promises attribution on published pages that no PBI delivers, and a switcher byline it does not depend on; back both with ZG-16 (dep) and ZG-21 (credit comment) **or** drop the published-page clause.

**Option chosen: drop the published-page clause, and depend on ZG-16.** Reasons:

1. Mika's exact ask (round-0 row 3) is "that attribution is displayed", and her proposed fix (row 2) is a name and link under each theme in the switcher. The switcher byline is ZG-16; the license section now promises precisely that and nothing more.
2. The "published pages' `<link>` comment" clause was the Generator's invention in cycle 0, not a persona line. Delivering it would add a theme-header parser and a new AC to ZG-21, the largest item in the set, and invalidate its blessing for a feature no persona asked for.
3. Dropping keeps the graph and every other blessing intact. The PO's non-blocking ZG-21 note (a hosted-page byline as the smallest honest credit) is carried forward; the new ZG-17 scope-out line says explicitly that it is a separate PBI against ZG-21 if the human wants it, so the terms cannot be read as promising it.

**What changed**

- `## Why` adds: the terms may only promise the credit the product actually shows (the switcher byline from ZG-16).
- Scope-in `themes/README.md` License line now reads: attribution (name + link, from the `Author:` / `URL:` header lines) is displayed on the theme's card in the switcher (ZG-16). The published-pages clause is gone.
- New scope-out line: attribution on hosted/published pages — no round-1 PBI renders a Designer credit on `/r/{id}`; the terms must not promise one.
- New AC: `grep -n -i "switcher" themes/README.md` hits inside the License section, and `grep -n -i -E "published page|hosted page|<link> comment" themes/README.md` prints nothing.
- `## Dependencies`: **ZG-16** (board: `pinto dep add ZG-17 ZG-16`). ZG-18 still depends on ZG-17, so the designer chain is now ZG-16 → ZG-17 → ZG-18 (ZG-16 is a leaf with no deps; ZG-17 was already gated by nothing, so this adds one small item ahead of it).
- Notes keep the Cargo `MIT OR Apache-2.0` open question and record the option chosen.

**Coverage matrix rows**

| # | Theme | PBI(s) / cut |
| --- | --- | --- |
| C2 | Designers not credited; no portfolio link field | ZG-16 (now also the sole delivery of the attribution ZG-17's terms promise) |
| C3 | No LICENSE; contribution license undefined | ZG-17, depends on ZG-16 (human confirms; open question 3); **cut inside it:** hosted-page credit (no round-1 PBI ships it; separate PBI against ZG-21 if wanted) |

## ZG-19 — Put the print-honesty rule, a full blank scaffold, and contract fixes where designers look

Not rejected; changed **only** because the ZG-6 cut moved coverage here (the task rules allow a minimal `## Covers` update on the receiving PBI; the fixture itself has to live somewhere, and a `## Covers` line without scope and AC behind it would be a false claim).

**What changed**

- `## Why` adds the clause "and the byte-locked sample never shows `rz-photo` / `rz-score`, so a Designer cannot proof them (Mika)".
- `## Covers` C8 now lists the proofing fixture.
- One scope-in line: `skeleton/samples/contract.json` = Jordan Hale's `resume.json` plus the two fields the byte-locked sample omits (`basics.image` → relative `samples/portrait.svg`, a neutral vector; `education[0].score: "3.9"` as a string so no ZG-3 dependency is introduced), rendered by the crate to `skeleton/samples/contract.html` and test-locked; `themes/README.md` names it as the proofing file. Served by ZG-14's existing `skeleton/samples/*` copy — ZG-14 unchanged.
- One scope-out line: changing `skeleton/resume.json` / `example.html` (RZ-2 byte-lock) — the fixture is a superset copy, not an edit.
- Three AC: acceptance-test byte lock of `contract.json` → `contract.html` with `rz-photo`, `rz-photo-img`, `alt="Portrait of Jordan Hale"`, `GPA 3.9` present; the existing node test also asserts every `rz-*` class in `example.html` appears in `contract.html` (superset, never a fork) and `git diff --stat skeleton/resume.json skeleton/example.html` is empty; `grep -n "samples/contract.html" themes/README.md` hits.
- Dependencies unchanged (none). Still one outcome: designer docs and fixtures stop contradicting the product. Estimated size stays well under the review bar (one JSON fixture, one locked HTML, one SVG, one acceptance-test case, one node assertion, one README line).

## Updated dependency graph (delta only)

- Added: `ZG-16 → ZG-17` (so `ZG-16 → ZG-17 → ZG-18`).
- Everything else unchanged. Graph remains acyclic. Ready-at-start set loses nothing: ZG-16 was already ready; ZG-17 now waits on it.

## Changed ids

Every PBI whose body or deps changed in this pass (prior blessings invalidated; full PO → QA → CTO chain required):

- **ZG-6** — body (photo/portrait removed, C8 dropped from Covers, AC and scope-out updated)
- **ZG-10** — body (guide-line overlay cut to scope-out with reason; probe replaced)
- **ZG-17** — body (published-page clause dropped, switcher-only promise, new AC) and deps (+ZG-16)
- **ZG-19** — body (receives the `rz-photo` / `rz-score` proofing fixture: Why, Covers, one scope-in, one scope-out, three AC)

Unchanged and still carrying their cycle-1 PO BLESS: ZG-1, ZG-2, ZG-3, ZG-4, ZG-5, ZG-7, ZG-8, ZG-9, ZG-11, ZG-12, ZG-13, ZG-14, ZG-15, ZG-16, ZG-18, ZG-20, ZG-21, ZG-22. ZG-16 gains a dependent (ZG-17) but its own body and deps are untouched; ZG-18's deps are untouched (still ZG-14, ZG-17). ZG-21 is untouched because the drop option was chosen for ZG-17.
