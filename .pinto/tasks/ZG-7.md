+++
id = "ZG-7"
title = "Rewrite the chrome in plain language with an About panel and a free-during-preview line"
status = "todo"
rank = "o"
labels = ["avril", "round-1", "chrome"]
created = "2026-08-23T23:55:14.235484Z"
updated = "2026-08-23T23:55:14.235484Z"
+++

## Why
Elena said the sidebar "made me feel dumb", Priya mistook "CHROME" for her browser and clicked the wrong "Print", and nobody could find a price; plain words, one About panel and an honest "free during preview" line answer them (Priya, Elena, Mika).
## Covers
F1, F2, B3 — Priya, Elena, Mika
## Scope in
- Replace developer copy in `frontend/src/Main.elm`: lede → "Pick a look for your résumé. Your content stays the same. Print it or share the link."; drop "Labels come from /* rz-target */…" and "Print preview emulates @media print…"; print hint → "What you see here is what the printer prints."
- Heading "Chrome" → "Appearance"; filter chips "All / For screen / For paper"; badges `web|print|both` → "Screen" / "Paper" / "Screen + paper"; a one-line note "Every theme prints in dark ink on white paper" under the list
- Print action button label "Print / Save as PDF"; filter group and action get distinct accessible names
- "About" link (sidebar footer) opening an in-chrome panel (`.about-panel`, `role="dialog"`) with: what ResumeZen is in three sentences, "Free during the preview. Pricing is not announced.", link to the GitHub repo, and a slot ("For designers") that ZG-14 fills
- `frontend/README.md` sentence for testers describing the new labels
## Scope out
- Designer links, privacy answers, share controls (ZG-14, ZG-22, ZG-8)
- Inventing a price or a launch date (open question 4)
- Restyling the sidebar (GPUI tokens stay); mobile layout (ZG-9)
## Acceptance criteria
- [ ] Probe `ZG-7/no-jargon`: chrome `body.innerText` (About panel closed) contains none of `rz-target`, `@media`, `Skeleton`, `judged on hover`, `CHROME` (case-sensitive heading) and does contain `Appearance`, `For paper`, `Print / Save as PDF`, `Pick a look for your résumé`
- [ ] Probe `ZG-7/one-print`: exactly one button with accessible name starting `Print` exists; `page.getByRole('button', { name: 'Print / Save as PDF' })` resolves to one element and clicking it calls `print()` on the iframe (existing U3 probe wiring)
- [ ] Probe `ZG-7/badges`: theme option badges read `Screen`, `Paper`, `Screen + paper` for Nightgarden, Quarto, Switchyard respectively; no badge text equals `web`, `print`, or `both`
- [ ] Probe `ZG-7/about`: clicking "About" opens `[role="dialog"].about-panel` whose text contains `Free during the preview` and an `<a href="https://github.com/subzerocorp/cvzengarden">`; Escape closes it and focus returns to the About link
- [ ] Probe `ZG-7/print-on-white`: the switcher contains the text `prints in dark ink on white paper`
- [ ] Existing RZ-3 / S1–S5 / U3 probes still pass (selectors `#theme-option-*`, `.preview-controls__print` retained)
- [ ] Chrome still has no `rz-` class or id; BAR-Q1 name `Independent Product Experience Guardian` remains in `qa/MARKET-QUALITY-BAR.md` (unchanged)
- [ ] `just verify` green
## Dependencies
- none
## Notes
- none
