# `themes/`

One file, one theme. Pure CSS. Nothing else.

```
themes/
  your-theme-name.css
```

## Rules

- Target the class contract in [`../skeleton/CLASS-CONTRACT.md`](../skeleton/CLASS-CONTRACT.md).
- Do **not** use JSON Resume theme templates. Input is JSON Resume; themes only see `rz-*` HTML.
- Style `html`, `body`, `.rz-*`, and `[data-rz-*]` only. Do not assume product-chrome markup exists.
- Declare `/* rz-target: web | print | both */` in the file header. See designer rules in the class contract (§2).
- No Tailwind. No CSS-in-JS. No JavaScript. No extra HTML. `@font-face` is allowed; webfont-loader JS is not.
- Do not depend on `skeleton/preview.css`. That file is a local readability aid, not part of the contract.
- You may define your own custom properties. Prefer `--rz-*` for theme-internal tokens so they cannot collide with chrome tokens.

[`_blank.css`](_blank.css) is a comment-only starting template, not a visual theme.
