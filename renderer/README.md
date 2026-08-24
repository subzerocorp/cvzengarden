# `renderer/`

Rust crate that turns a **JSON Resume** document into ResumeZen's **fixed semantic HTML**.

```text
resumezen_renderer::render(&resume) -> String
```

The implementation:

- Consumes [JSON Resume](https://jsonresume.org/schema) ([`../skeleton/resume.json`](../skeleton/resume.json))
- Ignores keys that are not in the [field map](../skeleton/CLASS-CONTRACT.md) (including `meta.x-schema-resume` and `work[].description`)
- Emits HTML whose `.rz-resume` tree matches [`../skeleton/example.html`](../skeleton/example.html)
- Omits empty sections, contacts, links, entries, and bullets
- Stays dependency-light: `serde` / `serde_json` only. No HTML templating language.

```bash
cargo test
```

This crate does not load themes, talk to the network, or emit PDF.
