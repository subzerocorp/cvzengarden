# `skeleton/`

The **fixed HTML class contract** — ResumeZen's public API.

| File | What it is |
| --- | --- |
| [`CLASS-CONTRACT.md`](CLASS-CONTRACT.md) | Spec: markup rules, class inventory, JSON shape |
| [`example.html`](example.html) | Complete rendered output a designer can theme today |
| [`resume.json`](resume.json) | Sample input the future Rust renderer will consume |
| [`preview.css`](preview.css) | Optional readability aid for opening the example locally. **Not a theme.** |

Open `example.html` in a browser. To try a theme, add:

```html
<link rel="stylesheet" href="../themes/your-theme.css">
```

and remove or keep `preview.css` — themes must not depend on it.
