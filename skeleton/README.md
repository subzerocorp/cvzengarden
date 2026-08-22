# `skeleton/`

The **fixed HTML class contract** — ResumeZen's public theme API — plus a JSON Resume fixture the renderer will consume.

| File | What it is |
| --- | --- |
| [`CLASS-CONTRACT.md`](CLASS-CONTRACT.md) | Spec: JSON Resume field map + `rz-*` class inventory |
| [`example.html`](example.html) | Complete rendered output a designer can theme today |
| [`resume.json`](resume.json) | Valid [JSON Resume](https://jsonresume.org/schema) input |
| [`preview.css`](preview.css) | Optional readability aid for opening the example locally. **Not a theme.** |

Open `example.html` in a browser. To try a theme, add:

```html
<link rel="stylesheet" href="../themes/your-theme.css">
```

and remove or keep `preview.css` — themes must not depend on it.

Paste/import any JSON Resume document from the wild. schema-resume files go through [`../converter/`](../converter/) first.
