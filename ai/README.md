# `ai/`

Grok system prompts that emit **pure CSS** against the class contract. **Not started.**

When this lands, prompts must:

- Target only documented `rz-*` classes ([`../skeleton/CLASS-CONTRACT.md`](../skeleton/CLASS-CONTRACT.md))
- Produce a single `.css` file (no HTML, JS, Tailwind, or CSS-in-JS)
- Treat `skeleton/example.html` as the fixture the CSS is written against
- Leave product chrome alone

Prompts go here as markdown / text. Generated CSS is reviewed and, if kept, lives in [`../themes/`](../themes/).
