# `renderer/`

Rust crate that turns a **JSON Resume** document into ResumeZen's **fixed semantic HTML**.

**Status:** stub only. Do not treat the public API as final.

The implementation, when it lands, must:

- Consume [JSON Resume](https://jsonresume.org/schema) ([`../skeleton/resume.json`](../skeleton/resume.json))
- Ignore keys that are not in the [field map](../skeleton/CLASS-CONTRACT.md) (including `meta.x-schema-resume` and schema-resume pass-through extras)
- Emit HTML that matches [`../skeleton/example.html`](../skeleton/example.html) and [`../skeleton/CLASS-CONTRACT.md`](../skeleton/CLASS-CONTRACT.md)
- Be byte-stable enough to lock with fixtures (same JSON → same class tree)
- Omit empty sections, contacts, links, and bullets
- Stay dependency-light; no HTML templating language that encourages a second skeleton

```text
resumezen_renderer::render(&resume) -> String
```

This crate does not load themes, talk to the network, or emit PDF.
