# `skeleton/`

The **fixed HTML class contract** — ResumeZen's public theme API — plus a JSON Resume fixture the renderer will consume.

| File | What it is |
| --- | --- |
| [`CLASS-CONTRACT.md`](CLASS-CONTRACT.md) | Spec: JSON Resume field map + `rz-*` class inventory |
| [`example.html`](example.html) | Complete rendered output a designer can theme today |
| [`resume.json`](resume.json) | Valid [JSON Resume](https://jsonresume.org/schema) input |
| [`resume-schema.json`](resume-schema.json) | Vendored [JSON Resume schema](https://github.com/jsonresume/resume-schema/blob/b25e3f4bbafd349c2c5bbaa62602c03c228762db/schema.json) (`schema.json` at commit `b25e3f4bbafd349c2c5bbaa62602c03c228762db`, draft-07, 15 018 bytes, sha256 `8911e912ee487954b10cb59da39265c7e62ef7cba5973706d125448adc853969`) |
| [`samples/junior.json`](samples/junior.json) | Short first-timer sample (Sam Okoro). `junior.html` is the crate output, locked by `junior_sample_html_is_crate_output` |
| [`preview.css`](preview.css) | Optional readability aid for opening the example locally. **Not a theme.** |

Open `example.html` in a browser. To try a theme, add:

```html
<link rel="stylesheet" href="../themes/your-theme.css">
```

and remove or keep `preview.css` — themes must not depend on it.

Paste/import any JSON Resume document from the wild. schema-resume files go through [`../converter/`](../converter/) first.
