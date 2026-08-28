+++
id = "ZG-8"
title = "Copy a link to this exact view and say so when a theme in the URL does not exist"
status = "in-progress"
rank = "p"
labels = ["avril", "round-1", "chrome", "avril-blessed"]
start_at = "2026-08-28T00:25:00.000000Z"
created = "2026-08-23T23:55:14.295176Z"
updated = "2026-08-28T00:25:00.000000Z"
+++

## Why
Elena nearly took screenshots because she did not know the address bar changed, could not share the print look, and `?theme=banana` silently showed the wrong theme to her friend (Elena, Marcus, Devon).
## Covers
F3, F4 — Elena, Marcus, Devon
## Scope in
- "Copy link" button (`.copy-link`) in the View section that writes `location.href` to the clipboard and shows a 2-second "Copied" state (`[data-copy-state="copied"]`); when the clipboard write rejects (permission denied, insecure context, no user activation) it shows `[data-copy-state="failed"]` with the text "Copy failed — select the address bar and copy it" and never shows `Copied`
- `view=print` / `view=screen` query param mirrored with the preview toggle (pushState, same generation as `theme`); `?theme=quarto&view=print` opens in Print preview; Back restores the previous view
- Unknown `?theme=` → keep the URL, show a dismissible note `[data-theme-notice="unknown"]` "No theme called "banana" — showing Nightgarden." rendered with Elm `text` (the raw query value is always literal text, never markup); empty (`?theme=`) or absent `theme` shows no note
- `ThemeId.fromQuery` returns a result type distinguishing `Known id | Unknown raw | Absent` (pure), history stays in `ports.js`
## Scope out
- Hosted résumé links / Publish (ZG-22 reuses `.copy-link`)
- Redirecting/rewriting the URL to the fallback (loses the sender's intent)
- Persisting the Author's Resume in the URL (size, privacy)
## Acceptance criteria
- [x] Probe `ZG-8/copy-link`: in a context created with `context.grantPermissions(['clipboard-read','clipboard-write'])`, with `?theme=quarto` and Print preview active, clicking `.copy-link` puts `…/?theme=quarto&view=print` (param order-insensitive) on the clipboard and `[data-copy-state="copied"]` is present with text `Copied` for ≥ 1 s, then absent
- [x] Probe `ZG-8/copy-failed`: with `navigator.clipboard.writeText` overridden via `page.addInitScript` to reject with `NotAllowedError`, clicking `.copy-link` shows `[data-copy-state="failed"]` whose text contains `select the address bar`, the text `Copied` never appears (sampled for 500 ms), and no `pageerror` is recorded
- [x] Probe `ZG-8/view-url`: opening `/?theme=quarto&view=print` in a fresh context shows the Print preview button `aria-pressed="true"` and iframe `body` background is white for Nightgarden's `?theme=nightgarden&view=print` too; reload keeps `view=print`
- [x] Probe `ZG-8/view-back`: Screen → Print preview → browser Back returns to Screen and the URL drops/sets `view=screen`
- [x] Probe `ZG-8/unknown-theme`: `/?theme=banana` selects Nightgarden, URL still contains `theme=banana`, `[data-theme-notice="unknown"]` `textContent` contains `banana` and `Nightgarden`; clicking its close button removes it
- [x] Probe `ZG-8/notice-escaped`: `/?theme=%3Cb%3Ex%3C%2Fb%3E` shows a notice whose `textContent` contains the literal `<b>x</b>` and which contains no `<b>` element (`querySelector('b')` is null)
- [x] Probe `ZG-8/no-notice`: `/?theme=Quarto`, `/`, and `/?theme=` (empty — the existing S5 load) each show no `[data-theme-notice]`
- [x] Probe `ZG-8/invalid-view`: `?view=sideways` opens Screen with no crash and no notice
- [x] Existing S4 permalink + Back and S5 probes still pass
- [ ] `just verify` green — rust + ZG-8 / S4 / S5 / U3 / ZG-7 green; leftover is pre-existing `ZG-11/page-count quarto` (see `docs/plans/zg-8-execution.md`)
## Dependencies
- none
## Notes
- none
