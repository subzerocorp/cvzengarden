+++
id = "ZG-7"
title = "Rewrite the chrome in plain language with an About panel and a free-during-preview line"
status = "done"
rank = "o"
labels = ["avril", "round-1", "chrome", "avril-blessed"]
start_at = "2026-08-27T23:20:00.000000Z"
done_at = "2026-08-27T23:55:00.000000Z"
commits = ["2fbb4ff", "1751ba4", "4fd68b8", "797a7a0", "6d360cf", "a1f9f36"]
created = "2026-08-23T23:55:14.235484Z"
updated = "2026-08-27T23:55:00.000000Z"
+++

## Why
Elena said the sidebar "made me feel dumb", Priya mistook "CHROME" for her browser and clicked the wrong "Print", and nobody could find a price; plain words, one About panel and an honest "free during preview" line answer them (Priya, Elena, Mika).
## Covers
F1, F2, B3 — Priya, Elena, Mika
## Scope in
- Replace developer copy in `frontend/src/Main.elm`: lede → "Pick a look for your résumé. Your content stays the same. Print it or share the link."; drop "Labels come from /* rz-target */…" and "Print preview emulates @media print…"; print hint → "What you see here is what the printer prints."
- Heading "Chrome" → "Appearance"; filter chips "All / For screen / For paper"; badges `web|print|both` → "Screen" / "Paper" / "Screen + paper"; a one-line note "Every theme prints in dark ink on white paper" under the list
- Print action button label "Print / Save as PDF"; the View toggle keeps its name "Print preview" (existing S4/U3 selectors untouched); filter group and action get distinct accessible names
- "About" link (sidebar footer) opening an in-chrome panel (`.about-panel`, `role="dialog"`) with: what ResumeZen is in three sentences, "Free during the preview. Pricing is not announced.", link to the GitHub repo, and a slot ("For designers") that ZG-14 fills
- `frontend/README.md` sentence for testers describing the new labels
## Scope out
- Designer links, privacy answers, share controls (ZG-14, ZG-22, ZG-8)
- Inventing a price or a launch date (open question 4)
- Restyling the sidebar (GPUI tokens stay); mobile layout (ZG-9)
- Renaming the "Print preview" toggle (would break existing S4/U3 probes for no persona gain)
## Acceptance criteria
- [x] Probe `ZG-7/no-jargon`: chrome `document.body.textContent` (About panel closed; `textContent`, not `innerText`, so CSS `text-transform` cannot mask it) contains none of `rz-target`, `@media`, `Skeleton`, `judged on hover`, and no heading element whose `textContent` is `Chrome` or `CHROME`; it does contain `Appearance`, `For paper`, `Print / Save as PDF`, `Pick a look for your résumé`
- [x] Probe `ZG-7/one-print`: exactly one button whose accessible name starts with `Print /` exists; `page.getByRole('button', { name: 'Print / Save as PDF' })` resolves to one element and clicking it calls `print()` on the iframe (existing U3 probe wiring); `page.getByRole('button', { name: 'Print preview' })` still resolves to exactly one element (the View toggle)
- [x] Probe `ZG-7/badges`: theme option badges read `Screen`, `Paper`, `Screen + paper` for Nightgarden, Quarto, Switchyard respectively; no badge `textContent` equals `web`, `print`, or `both`
- [x] Probe `ZG-7/about`: clicking "About" opens `[role="dialog"].about-panel` whose `textContent` contains `Free during the preview` and an `<a href="https://github.com/subzerocorp/cvzengarden">` (asserted by `href` string equality — never fetched; `just verify` stays offline); Escape closes it and focus returns to the About link
- [x] Probe `ZG-7/print-on-white`: the switcher `textContent` contains `prints in dark ink on white paper`; this is a BAR-U3 claim, so the existing S3/U3 print probes (white `body` background, no motion, `U3_PRINT_PAGES`) are the guard and must be green in the same run
- [x] Existing RZ-3 / S1–S5 / U3 probes still pass (selectors `#theme-option-*`, `.preview-controls__print`, button name `Print preview` retained)
- [x] Chrome still has no `rz-` class or id; BAR-Q1 name `Independent Product Experience Guardian` remains in `qa/MARKET-QUALITY-BAR.md` (unchanged)
- [x] `just verify` green
## Dependencies
- none
## Notes
- none

## Execution Evidence (commits 2fbb4ff, 1751ba4, 4fd68b8, 797a7a0, 6d360cf, a1f9f36)

Full probe/unit evidence: `docs/plans/zg-7-execution.md`, `docs/plans/zg-7-tester.md`. Reviewer: `docs/plans/zg-7-reviewer.md`. GAN close: `docs/plans/zg-7-completion.md`.

- [x] `ZG-7/no-jargon` — isolated + full PASS (`textContent`, About closed)
- [x] `ZG-7/one-print` — isolated + full PASS (one `Print / Save as PDF`; iframe `print()`; unique `Print preview`)
- [x] `ZG-7/badges` — isolated + full PASS (Nightgarden Screen, Quarto Paper, Switchyard Screen + paper)
- [x] `ZG-7/about` — isolated + full PASS (dialog, Free during the preview, exact GitHub href, Escape + focus)
- [x] `ZG-7/print-on-white` — isolated + full PASS; S3/U3 honesty guard green in the same full run
- [x] Existing RZ-3 / S1–S5 / U3 — all PASS; U3 Jordan 2/2/2
- [x] Chrome has no `rz-` class or id; `qa/MARKET-QUALITY-BAR.md` unchanged
- [x] `just verify` recipes green except the carved-out ZG-11 quarto long-resume 4-vs-3

GAN: Reviewer BLESS (`6d360cf`) → Tester BLESS (`a1f9f36`) → Architect BLESS. PR #23 left open. Production not published.
