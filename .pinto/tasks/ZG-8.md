+++
id = "ZG-8"
title = "Copy a link to this exact view and say so when a theme in the URL does not exist"
status = "todo"
rank = "p"
labels = ["avril", "round-1", "chrome"]
created = "2026-08-23T23:55:14.295176Z"
updated = "2026-08-23T23:55:14.295176Z"
+++

## Why
Elena nearly took screenshots because she did not know the address bar changed, could not share the print look, and `?theme=banana` silently showed the wrong theme to her friend (Elena, Marcus, Devon).
## Covers
F3, F4 — Elena, Marcus, Devon
## Scope in
- "Copy link" button (`.copy-link`) in the View section that writes `location.href` to the clipboard and shows a 2-second "Copied" state
- `view=print` / `view=screen` query param mirrored with the preview toggle (pushState, same generation as `theme`); `?theme=quarto&view=print` opens in Print preview; Back restores the previous view
- Unknown `?theme=` → keep the URL, show a dismissible note `[data-theme-notice="unknown"]` "No theme called "banana" — showing Nightgarden."; empty/absent `theme` shows no note
- `ThemeId.fromQuery` returns a result type distinguishing `Known id | Unknown raw | Absent` (pure), history stays in `ports.js`
## Scope out
- Hosted résumé links / Publish (ZG-22 reuses `.copy-link`)
- Redirecting/rewriting the URL to the fallback (loses the sender's intent)
- Persisting the Author's Resume in the URL (size, privacy)
## Acceptance criteria
- [ ] Probe `ZG-8/copy-link`: with `?theme=quarto` and Print preview active, clicking `.copy-link` puts `…/?theme=quarto&view=print` (param order-insensitive) on the clipboard and the button text becomes `Copied` for ≥1s then reverts
- [ ] Probe `ZG-8/view-url`: opening `/?theme=quarto&view=print` in a fresh context shows the Print preview button `aria-pressed="true"` and iframe `body` background is white for Nightgarden's `?theme=nightgarden&view=print` too; reload keeps `view=print`
- [ ] Probe `ZG-8/view-back`: Screen → Print preview → browser Back returns to Screen and the URL drops/sets `view=screen`
- [ ] Probe `ZG-8/unknown-theme`: `/?theme=banana` selects Nightgarden, URL still contains `theme=banana`, `[data-theme-notice="unknown"]` text contains `banana` and `Nightgarden`; clicking its close button removes it
- [ ] Probe `ZG-8/known-theme-no-notice`: `/?theme=Quarto` and `/` show no `[data-theme-notice]`
- [ ] Probe `ZG-8/invalid-view`: `?view=sideways` opens Screen with no crash and no notice
- [ ] Existing S4 permalink + Back probes still pass
- [ ] `just verify` green
## Dependencies
- none
## Notes
- none
