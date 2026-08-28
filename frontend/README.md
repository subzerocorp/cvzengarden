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

Opens the Garden at [http://127.0.0.1:4173/](http://127.0.0.1:4173/). The Theme switcher (`.theme-switcher`) changes only the Theme `<link>` href inside the iframe. Screen view shows web motion; the View toggle **Print preview** still emulates print media and is mirrored as `?view=print` / `?view=screen`. **Copy link** (`.copy-link`) copies the address bar. An unknown `?theme=` keeps that URL and names the miss. **Print / Save as PDF** (`.preview-controls__print`) prints the sandboxed document so the active Theme’s print CSS is what you get. Print preview shows **About N pages (Paper)** (`.preview-controls__pages`); both views say to choose **Save as PDF** in the print dialog (`[data-pdf-hint]`). Testers: heading **Appearance** (not Chrome); filters **All / For screen / For paper**; badges **Screen / Paper / Screen + paper**; About opens a dialog that says **Free during the preview**. On a phone (≤720px) the résumé fills the first screen; a **Theme** button opens the sidebar as a sheet.

```bash
npm test
```

runs the unit tests and the acceptance probes (static chrome checks + a headless browser). The build compiles the renderer to Wasm with [`wasm-pack`](https://rustwasm.github.io/wasm-pack/installer/) into `static/wasm/` (gitignored), and the ZG-4 parity probe runs `cargo run --example render` in `../renderer`, so `npm test` needs a Rust toolchain plus `wasm-pack` on `PATH`. Port `4173` is often taken; set `PROBE_PORT` / `PORT`.

Harden coverage: FOUC-free dual-link Theme swap, 1280×800 date geometry, Nightgarden paper-honest print, keyboard-focusable switcher, and `?theme=` permalink + Back (unknown/empty → Nightgarden).
