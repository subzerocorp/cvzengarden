# `frontend/`

Elm + vanilla CSS product chrome. RZ-3 ships the live Garden Theme switcher around a sandboxed Skeleton.

- Visual language: [`DESIGN.md`](DESIGN.md) (GPUI Component).
- Résumé markup: [`../skeleton/CLASS-CONTRACT.md`](../skeleton/CLASS-CONTRACT.md).
- Themes: [`../themes/`](../themes/). The catalog is generated from `themes/*.css` at build time (`scripts/generate.mjs`). `_blank.css` and `skeleton/preview.css` are not Themes.

Chrome CSS must not use the `rz-` prefix. The résumé lives in an iframe (`sandbox.html`) so designer CSS cannot style this UI.

No Tailwind. No CSS-in-JS.

## Run locally

```bash
cd frontend
npm install
npm start
```

Opens the Garden at [http://127.0.0.1:4173/](http://127.0.0.1:4173/). The Theme switcher (`.theme-switcher`) changes only the Theme `<link>` href inside the iframe. Screen view shows web motion; **Print preview** emulates `@media print`. **Print** prints the sandboxed document so the active Theme’s print CSS is what you get.

```bash
npm test
```

runs the RZ-3 + RZ-S1…S5 acceptance probes (static chrome checks + a headless browser).

Harden coverage: FOUC-free dual-link Theme swap, 1280×800 date geometry, Nightgarden paper-honest print, keyboard-focusable switcher, and `?theme=` permalink + Back (unknown/empty → Nightgarden).
