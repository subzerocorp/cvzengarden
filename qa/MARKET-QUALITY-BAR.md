# ResumeZen market-quality bar

## Living quality model

This file is independent of RZ-2..RZ-9 and of PR #2. This file is the living quality model.

Product and QA judge every PR against this file, not against CTO RZ-2..RZ-9 or PR #2.

Each rule below has a stable `BAR-*` id a probe can print, plus a FAIL condition. A one-line stub that only says “we care about quality” is not this bar.

## Live product

- Live product URL exactly: https://cvzengarden.netlify.app
- cvzengarden.com and resumezengarden.com are parked Epik pages, not the product.

## Binding priority — BAR-Q1

**Independent Product Experience Guardian.** Binding priority (BAR-Q1): Independent Product Experience Guardian; (1) ease of use, (2) UI look and feel, (3) consistency, (4) category-leading vs CSS Zen Garden + Teal / Rezi / Enhancv.

**FAIL** if a PR, README, or probe omits the name Independent Product Experience Guardian, or omits, reorders, or replaces that priority.

## Default apply-list

This mapping is the default apply-list, not an exclusive partition. Extra `BAR-*` ids still apply when the change presents the matching failure.

| Change kind | Default apply-list |
| --- | --- |
| Chrome / theme / garden-asset PRs | BAR-U1, BAR-U2, BAR-U3, BAR-U4, BAR-L1, BAR-T1, BAR-T2, BAR-X2 |
| Renderer PRs | BAR-R1 |
| Docs / README / probes | BAR-X1, BAR-X3, BAR-J1, BAR-Q1, BAR-D1 |

BAR-X1 and BAR-J1 still apply to any PR that presents paste+download as the paid product. BAR-X3 still applies to any PR that treats parked hosts as the garden.

## Product-shape rules

### BAR-X1

A PR that presents paste-JSON-and-download-HTML/CSS as the job-seeker (paid) product FAILS, even if the ticket is labeled RZ-4.

### BAR-X2

Any theme `content:` property value containing a resume word (name, job title, company, dates, or a bullet sentence) FAILS. Decorative separators (empty, middle-dot, en-dash, comma, colon, space) are allowed. `justify-content` is not `content:`.

### BAR-X3

A PR, README, or probe that treats the parked custom domains as the live garden FAILS. The live garden is https://cvzengarden.netlify.app. cvzengarden.com and resumezengarden.com are parked Epik pages, not the product.

### BAR-J1

Job seekers pay for a URL and paper, not an HTML file.

**FAIL** if a PR presents an HTML file (or paste-JSON-and-download-HTML/CSS) as what the job seeker pays for.

### BAR-D1

A designer path requires reachable sample HTML, a blank/starting CSS file, and a visible submit/contribute path.

**FAIL** if a designer path is missing reachable sample HTML, a blank/starting CSS file, or a visible submit/contribute path. Do not treat `/skeleton/example.html` 404 as a designer pass (BAR-D1 covers sample HTML reachability).

## Theme and garden-asset rules

### BAR-T1

Nightgarden is web and has keyframes plus prefers-reduced-motion; Quarto is print and has no keyframes; Switchyard is both and has no keyframes.

**FAIL** if Nightgarden is not web, lacks keyframes, or lacks prefers-reduced-motion; if Quarto is not print or has keyframes; or if Switchyard is not both or has keyframes.

### BAR-T2

`/skeleton/preview.css` must not ship as a Theme; production 404 for `/skeleton/preview.css` is the pass. Do not treat `/skeleton/example.html` 404 as a designer pass (BAR-D1 covers sample HTML reachability).

**FAIL** if `/skeleton/preview.css` ships as a Theme, or if production does not 404 `/skeleton/preview.css`.

### BAR-U1 FOUC

A theme swap that paints unstyled HTML (default serif / unstyled flash) FAILS. Today's live garden FAILS this rule.

### BAR-U2 Overflow

A first-party theme that clips dates or shows a horizontal scrollbar on the resume at a 1280px-wide viewport FAILS. Quarto today FAILS this rule. The rule remains if a later walk is clean.

### BAR-U3 Print honesty

A web-target theme whose print is not paper-honest (Nightgarden ≥5 pages of dark ink vs Quarto/Switchyard ~3) FAILS. Chrome that claims print-honesty ("Print stays print") while a listed theme fails U3 FAILS. Do not lock that slogan as a pass.

### BAR-U4 Permalink

No shareable theme URL (query or path) and Back does nothing FAILS. Today's live garden FAILS.

### BAR-L1 Look-and-feel

Pairwise visual distinctness (computed color or font-family of `.rz-name` differs for every pair); a first-party theme that loads a third-party webfont CDN (jsDelivr etc.) with no self-hosted/@font-face fallback FAILS.

**FAIL** if any first-party theme pair shares both computed color and font-family of `.rz-name`, or if a first-party theme loads a third-party webfont CDN (jsDelivr etc.) with no self-hosted/@font-face fallback.

## Renderer rule

### BAR-R1

`{ "basics": { "name": "Ada" } }` must render Ada and must not emit Jordan Hale, `#rz-experience`, contacts, or a photo.

**FAIL** if that Resume does not render Ada, or if it emits Jordan Hale, `#rz-experience`, contacts, or a photo.

## Explicitly out of this file

These are not `BAR-*` locks here and must not be smuggled in as if they were:

- Theme file byte-size windows
- BAR-A1 / BAR-A2
- CLASS-CONTRACT.md 404 and non-sticky mobile switcher as BAR-* locks
- Pixel brand guidelines or a second glossary
