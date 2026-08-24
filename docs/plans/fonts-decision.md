# Fonts — locked 2026-08-24

Human decision. Amends ZG-13 notes/README AC. Font Library submit path is **not** round-1 execution (later AVRIL PBI).

## Policy

Two ways a Theme gets a face:

1. **Font Library** (Garden-hosted). Anyone may submit an original font. Inbound license: **CC BY 4.0** (same as Themes). First-party Themes and any Theme that uses a Library face load from our origin only — never a CDN. Vendored seed families that are already SIL OFL (EB Garamond, IBM Plex Sans, Syne, Outfit) **keep SIL OFL** and ship `OFL.txt`. We do not relicense other people's fonts as CC BY 4.0.

2. **Public CDN fonts** in a submitted Theme. A Designer may `@font-face` or CSS-`@import` any **public** font from an **HTTPS** CDN. JS webfont loaders stay forbidden.

## CDN limit (locked)

**No host allowlist.** A list of Google Fonts / jsDelivr / Bunny is a product we would have to maintain, and it fights the Garden's "bring your CSS" rule.

Limits that *do* exist:

- `https:` only (no `http:`).
- CSS only (`@font-face`, stylesheet `@import`). No JS loader, no extra HTML.
- First-party Themes: origin-only. BAR-L1 still fails a first-party sheet that phones a CDN.

Visitor IP to a CDN is the Designer's choice on a submitted Theme. The Font Library is the privacy-respecting path we promote. Disclose that in ZG-18 CONTRIBUTING when that PBI runs.

## What this does to the board

- **ZG-13** still vendors the three first-party faces under `themes/fonts/` and proves no third-party host on first-party sheets. README states this policy (replaces "any https origin, self-hosted preferred").
- **Font Library as a submit product** (intake, review, hosting of third-party original fonts) → next AVRIL round, not this PBI.
