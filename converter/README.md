# `converter/`

JSON Resume ↔ [schema-resume](https://schema-resume.org/) (JSON-LD).

**schema-resume is import/export only.** Canonical storage and the paste target are [JSON Resume](https://jsonresume.org/schema). The renderer never reads schema-resume. Themes never see either JSON — they style `rz-*` HTML.

| Direction | From | To |
| --- | --- | --- |
| Import | schema-resume JSON-LD | JSON Resume (stored) |
| Export | JSON Resume (stored) | schema-resume JSON-LD |

XML/XSD from schema-resume is out of scope for v1.

**Status:** mapping + fixture pair. No Rust/Elm implementation yet.

| File | What it is |
| --- | --- |
| [`MAPPING.md`](MAPPING.md) | Field-level import/export notes |
| [`fixtures/jsonresume.json`](fixtures/jsonresume.json) | Canonical stored document |
| [`fixtures/schema-resume.json`](fixtures/schema-resume.json) | Same person as schema-resume JSON-LD |

The Jordan Hale gallery sample lives in [`../skeleton/resume.json`](../skeleton/resume.json). These fixtures are a smaller pair that also exercises schema-resume-only extras and a `work.location` type conflict.
