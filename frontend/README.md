# `frontend/`

Elm + vanilla CSS product chrome. **Not started.**

This is the gallery, theme switcher, JSON paste, and forms — not the résumé itself. Chrome detects JSON Resume vs SchemaResume vs UniversalResume ([`../converter/DETECT.md`](../converter/DETECT.md)) and stores JSON Resume only.

- Visual language: [`DESIGN.md`](DESIGN.md) (GPUI Component).
- Résumé markup: [`../skeleton/CLASS-CONTRACT.md`](../skeleton/CLASS-CONTRACT.md).
- Themes: [`../themes/`](../themes/).

Chrome CSS must not use the `rz-` prefix. Preview a résumé in a sandbox so designer CSS cannot style this UI.

No Tailwind. No CSS-in-JS.
