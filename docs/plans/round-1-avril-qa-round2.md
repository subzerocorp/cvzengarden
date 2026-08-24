# AVRIL round 1 — QA Architect review (cycle 2)

**Role:** `qa-architect-agent` (second adversary) · **Date:** 2026-08-23 · **Cycle:** 2 (fresh review of revised items)
**Scope:** ZG-6, ZG-10, ZG-17 only — the three items the Product Owner blessed in cycle 2 that have never had a QA verdict. Nothing else is judged here; the Generator is concurrently revising other ids and those keep their cycle-1 verdicts until they come back through the chain.
**Inputs read in full:** `docs/plans/round-1-avril-qa-round1.md` (my cycle-1 conventions and verified facts, all still applied), `docs/plans/round-1-avril-intent.md`, `docs/plans/round-1-avril-po-round2.md`, `docs/plans/round-1-avril-generator-round2.md`, `docs/persona-rounds/round-0/{elena,priya,mika,devon}.md`, `pinto show ZG-6 ZG-10 ZG-17 --plain`, `pinto show ZG-5 ZG-7 ZG-14 ZG-16 ZG-18 ZG-19 --json` (dependency context), `frontend/scripts/probes.mjs`, `frontend/static/ports.js` (`emulatePrint`), `frontend/scripts/copy-dist.mjs`, `frontend/generated/sandbox.html`, `frontend/src/Main.elm` (print controls), `frontend/css/chrome.css` (`.garden-stage--print`), `themes/*.css` (`@page` rules), `themes/_blank.css`, `themes/README.md`, `renderer/Cargo.toml`, `renderer/src/emit.rs` (`format_score`), `skeleton/CLASS-CONTRACT.md` §5–§6, `justfile`.

Mandate: *BLESS only PBIs whose acceptance criteria are complete, falsifiable, and hostile to happy-path theater; otherwise REJECT with the missing cases.*

I judge testability only. I do not author bodies, touch the board, or reopen product scope. Cycle-1 conventions apply unchanged: shared fixtures have one owner; probe lines are `PASS  ZG-n/<slug>`; a PBI's own AC is never `SKIPPED` (a missing prerequisite prints `FAIL … prerequisite missing`); chrome text probes use `textContent`, not `innerText`; only Chromium is installed; nothing in the toolchain rasterises a PDF (pages are counted by regex over the bytes); `U3_PRINT_PAGES = {nightgarden: 2, quarto: 3, switchyard: 3}` is asserted with `!==`; `just verify` stays offline.

## Facts I verified before judging (they change verdicts)

| Fact | How | Affects |
| --- | --- | --- |
| Chromium's CSSOM exposes `@page` as `CSSRule.PAGE_RULE`; `rule.style.getPropertyValue("size")` returns **lower-case** `letter` / `a4`; Nightgarden's and Switchyard's `@page` sit **inside** `@media print` (Quarto's is top-level); Quarto's `@page :first` returns `size: ""`. | temporary Playwright script `/tmp/persona-lab/qa/zg10-estimate.mjs` against the built `dist/` on port 4391 | ZG-10 `paper-size` |
| Print-emulated column height ÷ printable page height on Jordan: Nightgarden 1881 px / 995 px → 2 (PDF 2); Quarto 2022 px / 946 px → **2.14 → 3** (PDF 3); Switchyard 2003 px / 1009 px → **2, PDF 3** (its `break-before: page` on Projects). Measured at the paper content width; at the 942 px preview width Quarto is 1924 px → 2.03 → 3, a hair from 2. | same script; CDP `Page.printToPDF` with `preferCSSPageSize: true`, existing `countPdfPages` regex | ZG-10 `estimate-matches-pdf` ± 0 |
| The generated `sandbox.html` `<head>` holds two `<meta>`, a `<title>`, a comment, and the theme `<link>`; `<body>` holds exactly one `article.rz-resume`. | read `frontend/generated/sandbox.html` | ZG-10 `no-guide-lines` "nothing beyond the Skeleton" |
| The print button is currently labelled `Print`; ZG-7 (a ZG-10 dependency) relabels it **`Print / Save as PDF`**. | `Main.elm` line 367–370; ZG-7 scope | ZG-10 `hint` |
| `#paste-input` does not exist until ZG-5; ZG-10 depends on ZG-7 only. `frontend/fixtures/` still does not exist. | `pinto show`, `ls` | ZG-10 `updates` |
| `copy-dist.mjs` publishes nothing from `skeleton/`; `/skeleton/resume.json` is 404 today (Elena's curl). ZG-14 will publish `skeleton/samples/*` and `example.html` but not `resume.json`; ZG-6 does not depend on ZG-14. | read `copy-dist.mjs`, ZG-14 body | ZG-6 `start-sample` / `start-junior` serving |
| `education[].score` is a **string** in the contract's own §5 snippet (`"score": ""`) and in upstream `jsonresume/resume-schema` `schema.json`; the Renderer's `format_score` parses the string and prefixes `GPA ` when it is numeric (`emit.rs:844`), so `"score": "3.7"` renders `GPA 3.7` today without ZG-3. `ajv` is not installed; no schema file exists in the repo. | grep contract, `emit.rs`, `frontend/package.json`, `ls node_modules` | ZG-6 schema AC vs `GPA 3.7` AC |
| `themes/_blank.css` line 5 reads `License:     (e.g. CC BY-NC-SA 4.0, MIT)`; no `LICENSE` file exists; `README.md` contains neither `License` nor `stays yours`; `renderer/Cargo.toml` says `MIT OR Apache-2.0`. | `grep`, `ls` | ZG-17 negatives |
| The common Definition of Done requires `progress.md` and `features.json` to change on every PBI (same footer that broke ZG-1 AC 5 in cycle 1). | PBI footer | ZG-17 "no file outside …" |

---

## ZG-6 — Explain the résumé format in plain words and start from a sample

The PO's cut landed cleanly and the shape of the ACs is right: a named probe per behaviour, a fixture byte-lock, a `git diff` on the RZ-2 sample, and an anti-stub (change `score`, the hard-coded HTML fails). What is left is a set of oracles that either cannot both pass, cannot run offline, or let the two persona failures this item exists for (Priya: "if the answer is JSON Resume it is never said"; Elena: cryptic error on first paste) slip through.

Blockers:

- **Self-contradicting AC pair.** `start-junior` demands `.rz-score` = `GPA 3.7` from a *numeric* `score: 3.7`, and another AC demands `junior.json` validate against `jsonresume/resume-schema` `schema.json`, where `score` is a string. Both cannot be green. The PO already flagged it; it is a hard testability defect, not a nit. `"score": "3.7"` satisfies both today (verified: `format_score` prefixes `GPA ` for a numeric string) and removes the only reason this item needs ZG-3.
- **The schema runner is not an oracle yet.** "A Node or Rust test that runs the schema; name the runner in evidence" defers the oracle to execution, and `notes` says the runner (`ajv` or the `jsonschema` crate) awaits human approval. Under the no-`SKIPPED` rule this AC has no defined pass/fail until then, and any runner must be **offline**: the schema must be vendored into the repo (path + upstream commit/version pinned in the AC), never fetched during `just verify`. Also add the anti-stub for the runner itself: a deliberately invalid document (e.g. `{"basics":{"name":5}}`) must be rejected by the same test, otherwise a validator that always returns `true` passes.
- **The copyable example is never proven to render.** `example-copy` only checks the `<pre>` parses and has `basics.name`. Priya's next move is paste → "Show it". Add `ZG-6/example-renders`: pasting the `<pre>` text into `#paste-input` yields `.rz-name` = the example's name with no `[data-paste-error]`, and the same text validates in the schema test above. Without it a `<pre>` with a `work` entry of the wrong shape passes every AC and fires Elena's walk-away trigger on the very first paste.
- **Scope item with no AC.** The sidebar sentence under "Use my résumé" ("Your résumé is a small text file (JSON Resume). Paste it, open it, or start from a sample.") has no probe; `format-named` is satisfied by the panel alone. Add a `textContent` assertion for `small text file` in the sidebar with the panel **closed**.
- **`format-named` uses `body.innerText`.** Convention from cycle 1: `textContent` (or case-insensitive), because `innerText` applies `text-transform`. Also state that the probe opens the paste panel first (the `<a href="https://jsonresume.org/schema">` lives inside it).
- **`junior-all-themes` print route is unspecified and `page.pdf` is the wrong tool.** `page.pdf()` prints on Letter unless `preferCSSPageSize` is set, so Switchyard (A4) is miscounted. Name the route: after clicking "Start from a short sample" in the chrome, use the existing `printToPdf(page)` (CDP, `preferCSSPageSize: true`) — the U3 shell-print hoist paginates like the child document — and count with `countPdfPages`. This also avoids needing `/skeleton/samples/junior.html` served, which is ZG-14's job and not a ZG-6 dependency.
- **Serving and ownership of the sample bytes.** `start-sample` fills the textarea with the bytes of `skeleton/resume.json`, which is not served today and is not in ZG-14's publish list either; `start-junior` needs `junior.json` reachable too. The AC must say how the bytes reach the browser without ZG-14 (ZG-6 publishes them, or embeds them at build), and, since ZG-14 also copies `skeleton/samples/*` "when present", name ZG-6 as the owner of `skeleton/samples/junior.{json,html}` in `dist/` so two PBIs do not both claim the same copy step.
- **Clipboard failure state.** Same case I required in ZG-8: with `clipboard-write` denied (or the promise rejecting), the Copy control must show a visible failure state and never a `Copied` confirmation. Grant both `clipboard-read` and `clipboard-write` in the happy-path probe so it is runnable headless.
- **Stored résumé after a sample click.** ZG-5 keeps the last accepted Resume in `localStorage['resumezen.resume']` and restores it on reload. Nothing says what a sample click does to it. Pin it either way (sample replaces the stored file, or does not) and probe the reload; today a tester cannot tell a correct implementation from a bug when an Author's own file disappears after an accidental click.

Non-blocking (fold in without re-review): pin the junior fixture's `basics.name` in the AC so `start-junior` asserts a name rather than "not `Jordan Hale`"; phrase "adds no image file" as a command (`git diff --name-only <base>..HEAD -- skeleton/samples | grep -E '\.(svg|png|jpe?g|webp)$'` prints nothing) since ZG-19 will legitimately add `portrait.svg` to the same directory; state how `junior.html` is regenerated (the cargo test that compares must also be able to write the fixture, or the ZG-4 `render` example produces it) so the byte-lock is reproducible.

**REJECT ZG-6 — the numeric-`score`/schema-validation pair cannot both pass, the schema runner is undefined and not offline, the copyable example is never rendered, the sidebar format sentence has no AC, `innerText` and `page.pdf` are the wrong oracles, sample-byte serving has no owner, and clipboard-failure and stored-résumé-after-sample cases are missing.**

## ZG-10 — Show an honest page count in print preview and how to save a PDF

The PO removed the guide lines because an overlay on an unpaginated column cannot see where `break-inside: avoid` pushes content. The readout has exactly the same blind spot, and the ACs have not caught up with the cut: they demand ± 0 against the PDF on the two print themes while the scope-out explains why that is not computable from a column height. I measured it rather than argue it (table above): a height-based estimate gives Switchyard **2** where the PDF is **3**, because `break-before: page` on Projects is invisible to a height; Quarto lands on 3 only because 2.14 rounds up. `estimate-matches-pdf` fails by construction on Switchyard today and will flip on Quarto the moment ZG-11 or ZG-13 reflows the page.

**What an honest oracle looks like for an unpaginated column.** The readout says "About"; the ACs should hold it to exactly what "About" means:

1. **Exact against a stated formula, not against the PDF.** State the formula in the AC so the probe can recompute it independently: `N = max(1, ceil(H / P))` where `H` is the `.rz-resume` height under print emulation **measured at the paper's content width** (page width minus horizontal `@page` margins — the preview column is wider than paper and under-reads) and `P` is page height minus vertical `@page` margins. The probe computes `H` and `P` itself from the iframe document and asserts the readout equals `N` (± 0). This is falsifiable, implementation-agnostic, and true.
2. **Loose reality check against the same-run PDF.** `|N − countPdfPages(printToPdf)| ≤ 1` for all three first-party themes on Jordan (measured today: 0, 0, 1) and the word `About` present. If the Generator wants ± 0 on print themes, the scope must say the estimator honours `break-before: page` and section `break-inside: avoid` — which contradicts scope-out line 1 — so pick one and say it.
3. **A node unit test for the pure calculation** (page-size parsing and the formula) with the negative cases listed below, so the arithmetic is pinned without a browser.

Further blockers:

- **`hint` cannot fail.** ZG-7 (a dependency) relabels the print button `Print / Save as PDF`; "text `Save as PDF` is visible next to the print button" is then satisfied with no hint at all. Assert the hint sentence itself (`Choose "Save as PDF" in the print dialog`) in an element distinct from the button, visible in both views.
- **`updates` needs ZG-5 and a fixture with no owner.** Pasting requires `#paste-input` (ZG-5); ZG-10 depends on ZG-7 only, so this probe cannot run in dependency order. Either add ZG-5 to `## Dependencies` or prove recompute without a paste (Nightgarden → Quarto changes the readout from `About 2` to `About 3`, which also pins "recomputed on theme switch", currently unprobed). The fixture clause "created in ZG-11; if absent, a 4-job fixture created here" violates the one-owner rule: depend on ZG-11 or own `frontend/fixtures/<name>.json` here and have ZG-11 reuse it.
- **`paper-size` has no negatives and one verified trap.** CSSOM returns lower-case `a4`, two of three `@page` rules are nested inside `@media print` (the walk must recurse), and Quarto's `@page :first` returns an empty `size` that must not shadow the base rule. Add: a sheet with no `@page` (apply `_blank.css` or a lab theme) → `Letter`; `size: a4` → `A4`; `:first` ignored; an unrecognised value (`size: 8.5in 11in`, `a4 landscape`) → a stated fallback with no exception.
- **`no-guide-lines` is undefined.** "No overlay element" and "nothing beyond the rendered Skeleton and the theme `<link>`" are not assertions, and the second is literally false today (the sandbox head has `<meta>`, `<title>`, a comment). Pin: `.garden-stage--print` has exactly one element child, `#garden-frame`; the iframe `body` has exactly one child, `article.rz-resume`; the iframe `head` contains no `<style>` and no `<script>`, and exactly one `link[rel=stylesheet]` once `waitForThemeHref` settles.
- **Minimum and singular.** Nothing says the readout never reads `About 0 pages` or `About 1 pages`. Pin `N ≥ 1` and the singular form in the unit test (height 0 → `About 1 page`).
- **Settling.** The estimate is recomputed after an async sheet swap; probes must wait on the value, not a timeout — carry `N` in the attribute (`[data-page-estimate="3"]`) and `waitForSelector` it.

Non-blocking: ZG-7 and ZG-10 both edit the paragraph under the print button; the dependency orders them, but the ZG-10 AC should assert ZG-7's "What you see here is what the printer prints." is still present so the second sentence does not replace the first.

**REJECT ZG-10 — `estimate-matches-pdf` ± 0 is unsatisfiable for a column-height estimate (measured: Switchyard 2 vs PDF 3) and contradicts the scope-out's own reasoning; replace with an exact stated formula at paper width plus a ± 1 same-run PDF check; `hint` is satisfied by ZG-7's button label; `updates` needs ZG-5 and an owned fixture; `paper-size` lacks the no-`@page`, lower-case and `:first` cases; `no-guide-lines` is not an assertion.**

## ZG-17 — Add the repo LICENSE and state the theme-contribution license terms

This is a grep-shaped PBI and most of it greps: `test -f LICENSE`, `CC BY 4.0` in both files, the switcher-only promise enforced from both directions, `stays yours`, first-party headers unchanged. The PO's blocker (promising credit no item ships) is closed by an AC that would catch its return. What remains are four holes a tester falls into immediately.

Blockers:

- **"No file outside … changes" contradicts the card's own DoD.** The common Definition of Done requires `progress.md` and `features.json` to change on every PBI. This is the exact defect I rejected ZG-1 for in cycle 1; the same one-line fix applies (`git diff --name-only -- . ':!progress.md' ':!features.json'` lists only the five files).
- **The template still advertises the license the README rejects.** `_blank.css` line 5 today says `(e.g. CC BY-NC-SA 4.0, MIT)` — Mika's exact complaint ("a menu, not a policy"). Scope says the line lists "exactly those two options"; the AC only greps that `CC BY 4.0` appears. Add the negative: `grep -n "NC" themes/_blank.css` prints nothing, and the `License:` line contains both `MIT` and `CC BY 4.0`.
- **Scope item with no AC.** `README.md` gains a "License" line; the only README AC is `stays yours`. Add `grep -n -i "license" README.md` hits and names `MIT`.
- **`LICENSE` content is stub-passable.** `head -1 LICENSE` containing `MIT` is satisfied by a one-word file. Pin the standard text: `grep -c "Permission is hereby granted, free of charge" LICENSE` = 1 and a `Copyright (c) <year> <holder>` line — the holder is a human decision (note it), the grep shape is not.
- **`themes/*.css` glob includes `_blank.css`.** "First-party headers still say `License: MIT`" — after this PBI `_blank.css` will not, and it matches the glob. Name the three files (`nightgarden`, `quarto`, `switchyard`).

Non-blocking: "hits inside the License section" and "explains the non-commercial exclusion" are not greps — define the section as the text between `## License` and the next `## ` heading and assert `CC BY-NC` and `not accepted` occur within it; wire the positive and negative README greps into a node test or `probes.mjs` so ZG-18 (CONTRIBUTING pointer) and ZG-19 (README edits) cannot silently reintroduce a hosted-page promise after this PBI closes; open question 3 (MIT vs dual for Cargo, holder name) stays in `notes` for the human and does not change any oracle.

**REJECT ZG-17 — the "no file outside the five" AC contradicts the DoD (`progress.md`/`features.json`), `_blank.css`'s existing `CC BY-NC-SA` example has no negative grep, the README License line has no AC, `LICENSE` content is stub-passable, and the first-party header check globs in `_blank.css`. All one-line fixes.**

---

## Summary

| id | PO cycle 2 | QA verdict | one-line reason |
| --- | --- | --- | --- |
| ZG-6 | BLESS | **REJECT** | numeric `score` vs schema AC cannot both pass; schema runner undefined/not offline; example never rendered; sidebar sentence, clipboard failure, stored-résumé-after-sample missing; `innerText`, `page.pdf`, sample-byte owner |
| ZG-10 | BLESS | **REJECT** | ± 0 vs PDF unsatisfiable for a column-height estimate (measured Switchyard 2 vs 3); `hint` satisfied by ZG-7's button label; `updates` needs ZG-5 + owned fixture; `paper-size` negatives; `no-guide-lines` undefined |
| ZG-17 | BLESS | **REJECT** | "no file outside" contradicts DoD; `CC BY-NC-SA` example not negated; README License line no AC; `LICENSE` stub-passable; glob includes `_blank.css` |

0 BLESS, 3 REJECT. All three return to the Generator; each needs the full PO → QA → CTO chain again after revision.

## Notes for the Generator (set-level, carried from cycle 1)

- **ZG-10 oracle, decided:** the readout is exact against a formula the probe can recompute (height at paper content width ÷ printable page height, minimum 1) and loose (± 1) against the same-run PDF. It is not exact against the PDF unless the scope claims the estimator models page-break rules — which scope-out line 1 says it cannot.
- **New test-order dependencies to make explicit:** ZG-10 → ZG-5 (paste) if `updates` keeps its paste route; ZG-10 → ZG-11 or ZG-10 owns the long fixture; ZG-6 owns `skeleton/samples/junior.*` in `dist/` and ZG-14's "when present" copy must not double-claim it; ZG-6 no longer needs ZG-3 once `score` is a string (the transitive edge through ZG-5 remains and is harmless).
- **Schema file:** whichever PBI first vendors `jsonresume/resume-schema` `schema.json` (ZG-6 is the natural owner) pins the upstream version in the AC; every later schema assertion (ZG-6 example, ZG-19 `contract.json` if desired) references that one file.
- **DoD contradiction pattern:** ZG-1 (cycle 1) and ZG-17 (cycle 2) both wrote "no other file changes" against a DoD that mandates two tracking files. Any future "only these files" AC must carry the `':!progress.md' ':!features.json'` exclusion.
