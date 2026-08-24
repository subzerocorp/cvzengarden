# AVRIL round 1 — Visionary CTO review (cycle 3b)

**Role:** `visionary-cto-agent` (third and final adversary) · **Date:** 2026-08-24 · **Cycle:** 3b
**Scope:** ZG-12 only — PO-blessed (cycle 6) and QA-blessed (`round-1-avril-qa-round6.md`) after two Generator revises. ZG-11 and ZG-20 are back with the Generator; ZG-19 and ZG-21 are concurrent. No verdict is emitted for anything but ZG-12.
**Inputs read in full:** `docs/plans/round-1-avril-cto-round1.md` (my target shape and execution rules), `docs/plans/round-1-avril-qa-round6.md` (ZG-12 section and set-level notes), `docs/plans/round-1-avril-generator-round5.md` (the ZG-12 delta), the current bodies of ZG-12 and ZG-11 via `pinto show ZG-12 ZG-11 --plain` (`updated` 2026-08-23T18:24:18-07:00, edge ZG-12 → ZG-11 unchanged).

Mandate: *BLESS only backlog items that advance a coherent two-year trajectory without irreversible entanglement; REJECT anything that buys short-term motion at the cost of future clarity.*

Product priority is settled (PO). Testability is settled (QA — the `.rz-section`-scoped `getAnimations()` oracle, the computed-`opacity` primary read, the named pre-change FAIL lines). I judge trajectory only: does the shape this item leaves behind still fit the two-year target, and does anything in it have to be undone later. I do not rewrite bodies and I do not touch the board.

---

## ZG-12 — Fit long names in Nightgarden, paint sections without scrolling, keep bullet line breaks

### 1. The rest-state decision is a design, not a hack

The strategic question in this item is whether "painted before entry" is bought with a temporary override that a later "make Nightgarden animate again" item would have to unwind. It is not. The body redefines what the rise *is*: a section's natural style is fully painted (`opacity: 1`, no transform); the fade-in is an effect that exists only where the platform can drive it from the scrollport (`@supports (animation-timeline: view())`, `animation-timeline: view()`, `animation-range: entry 0% entry 32%`), and it fills `forwards`, never `both`/`backwards`. The three consequences line up with the locks:

- **Locked decision 4 (motion on screens) is preserved, not weakened.** In a browser with scroll-driven animations the human still sees the same rise as today. `scope_out` explicitly refuses to remove the rise; `rise-css-structure` (b) fails a stub that deletes it. The item changes the rest state before entry, which is exactly the sentence the body uses.
- **BAR-T1 holds structurally.** Nightgarden keeps its `@keyframes` (rise, sheen, foxfire) and the line-390 `@media print, (prefers-reduced-motion: reduce)` guard; `reduced-motion` asserts the guard is effective on sections. Nothing here changes the bar's definition.
- **The unsupported-browser path is the correct default, not a degraded one.** Today a browser without `view()` plays a time-based entrance that fires on load whether or not a section is visible — a decorative behaviour with an ATS/crawler cost and no upside. After this PBI that browser simply gets a painted page. That is the honest reading of "progressive enhancement": the Skeleton's content is the base and the Theme's motion is the layer, which is also the order the Class Contract's ATS-honesty invariant (§1) already asserts. When Firefox/WebKit gain `view()` they get the rise for free, with no repo change — the exit is the platform's, and there is nothing to unwind.

The pattern this establishes for Designers is the one I want written into the future lint and the designer docs (not this PBI's job): *a Theme never leaves Skeleton content unpainted in its rest state; motion is additive and gated on a platform capability.* ZG-20's `motion` warning and the reduced-motion rule are already the first half of that; this PBI is the worked example.

### 2. Helper ownership keeps the suite from collapsing into one file

ZG-12 owns no shared helper. It consumes ZG-11's `openResumePage` (top-level `/sandbox.html`, fixed viewport, `waitThemeReady`), and the dependency edge exists for that reason plus the shared `nightgarden.css` edit order (print block first). The body's own additions are private to its probes: a brace-matching structure scan over one sheet, an `@supports`-stripping injector, a canvas pixel decode. None of them is claimed as a shared helper and none duplicates one that ZG-11 owns.

Both bodies say helpers live "in `probes.mjs`". My cycle-1 execution rule 6 stands and is not contradicted by the ACs: the ACs pin `PASS  ZG-12/<slug>` lines, the entry point and the helper *names and signatures*, not the file layout. AXEL's architect implements `openResumePage` / `printableWidthPx` / `paginate` under `frontend/scripts/probes/lib/` and the ZG-12 probes as their own module that imports them; `probes.mjs` stays a runner. The one-owner rule (QA's convention, my rule 6) is honoured: ZG-12 never edits `openResumePage`, and a future item that needs a different viewport passes an option rather than forking the helper. The `@supports`-stripping injector is the only ZG-12-private piece with reuse potential (any future "unsupported browser" probe); if a second consumer appears it moves to `lib/` then, not now.

The re-baseline discipline is also intact: ZG-12 touches neither `U3_PRINT_PAGES` nor `LONG_PRINT_PAGES`; `scope_out` sends all print rules to ZG-11, and the BAR-U3/S3 line in the AC only asserts the existing probes stay green. `U3_PRINT_PAGES` is re-baselined exactly once, by ZG-11, as my cycle-1 rule requires.

### 3. Long-name fitting and `pre-line` are theme rules, not contract changes

- **Name fitting** is confined to `themes/nightgarden.css` `.rz-name` / `.rz-identity` (`overflow-wrap: anywhere; hyphens: auto;` and a container-query or `clamp` step). No class is added, the Renderer emits nothing new, and Quarto/Switchyard are explicitly untouched because they have no complaint. This is the Theme doing its job under a fixed Skeleton — the Zen Garden premise — and the probe is a geometry inequality on existing classes. A Store-backed catalog, a hosted page, or the Wasm path all inherit it untouched because the sheet is the same file.
- **`white-space: pre-line` on `.rz-bullet, .rz-prose p`** across the three first-party sheets, plus a §5.3 *note* that highlights may contain `\n` and Themes should respect it. That note documents what the Renderer already does (it emits the string verbatim; the JSON Resume stays the only stored form and no markdown-in-JSON is admitted — `scope_out` is explicit). It adds no class, no `data-rz-*` attribute, changes no element type; under the §9 ruling I gave in cycle 1 it is "documented, no bump". It is guidance to Designers, not a contract obligation, and ZG-20's lint does not enforce it — correctly, since a Theme that collapses newlines is ugly, not non-conforming. `data-rz-schema` stays `1.0`.

Neither rule creates a second place where the Renderer's text semantics are decided; the crate remains the one oracle for what is in the document, and the Theme decides only how it is laid out.

### 4. Entanglement check

- Dependency: ZG-12 → ZG-11 only. Real (helper ownership, same sheet, print-block-first ordering). Acyclic with the rest of the graph as drawn in cycle 1.
- Chromium-only probes with a stated substitute for the unsupported path — a bounded toolchain fact, with the Firefox/WebKit install correctly sent to a human in `scope_out`, not assumed.
- Nothing here touches the Chrome, the port layer, the Store, the API, the Wasm bridge, or the Theme header format. No Phase 5 noun appears outside `scope_out`.
- Nothing has to be undone when: the catalog moves to the Store (same sheet), the hosted page ships (same sheet on a server-rendered Skeleton), other engines gain `view()` (rise appears, no change), or a future contract 1.1 arrives (no attribute or class was spent here).

Guidance for AXEL (not an AC): implement the ZG-12 probes as `frontend/scripts/probes/zg-12.mjs` importing `openResumePage` from `probes/lib/`; keep the `@supports`-stripping injector private until a second consumer exists; when the pre-change FAIL lines are recorded, record all three (`rise-css-structure` (a), `painted-without-support`, `painted-with-support` `opacity` `0`) from the same `git show <base>` sheet so evidence names one base commit.

**BLESS ZG-12 — the rest-state change is a durable redefinition (painted base, motion gated on `@supports` and filled `forwards`) that keeps locked decision 4 and BAR-T1 intact and needs no future unwinding; helper ownership stays with ZG-11 and the ACs pin names and lines, not layout, so `probes.mjs` can remain a runner over `probes/lib/`; the name fit and `pre-line` are Theme rules with a §5.3 note only, no class, no attribute, no `data-rz-schema` bump.**

---

## Summary

| id | PO | QA | CTO verdict | strategic rationale (one line) |
| --- | --- | --- | --- | --- |
| ZG-12 | BLESS (c6) | BLESS (c6) | **BLESS** | painted-base / gated-motion is the right permanent shape; no helper ownership drift; theme rules only, contract note without bump |

1 BLESS, 0 REJECT. ZG-12 now carries PO, QA and CTO BLESS and may be labelled `avril-blessed`. It remains blocked on ZG-11 landing first (helper owner, print block first) — an execution ordering, not a planning defect.
