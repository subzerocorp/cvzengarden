# `converter/`

Bridge: JSON Resume ↔ [SchemaResume](https://schema-resume.org/) and [UniversalResume](https://github.com/universal-resume).

**Canonical storage and the Renderer input are [JSON Resume](https://jsonresume.org/schema).** SchemaResume and UniversalResume are import/export only — same class. Themes never see any of these JSON files; they style `rz-*` HTML.

Do not adopt UniversalResume's html-renderer or pdf-generator.

| Direction | From | To |
| --- | --- | --- |
| Import | SchemaResume JSON-LD **or** UniversalResume | JSON Resume (stored) |
| Export | JSON Resume (stored) | SchemaResume JSON-LD **or** UniversalResume (strict) |

**Status:** mapping + fixture pairs. No Rust/Elm implementation yet. Detection rules: [`DETECT.md`](DETECT.md).

| File | What it is |
| --- | --- |
| [`DETECT.md`](DETECT.md) | How Chrome tells the three dialects apart |
| [`MAPPING.md`](MAPPING.md) | JSON Resume ↔ SchemaResume |
| [`UNIVERSAL-RESUME.md`](UNIVERSAL-RESUME.md) | JSON Resume ↔ UniversalResume |
| [`fixtures/jsonresume.json`](fixtures/jsonresume.json) | Stored Resume (SchemaResume pair) |
| [`fixtures/schema-resume.json`](fixtures/schema-resume.json) | Same person as SchemaResume JSON-LD |
| [`fixtures/jsonresume-universal.json`](fixtures/jsonresume-universal.json) | Stored Resume (UniversalResume pair) |
| [`fixtures/universal-resume.json`](fixtures/universal-resume.json) | Same person as UniversalResume |

The Jordan Hale gallery sample lives in [`../skeleton/resume.json`](../skeleton/resume.json).
