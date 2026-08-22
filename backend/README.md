# `backend/`

Axum + SQLite API. **Not started.**

Planned responsibilities (later):

- Persist submitted themes (pure `.css`) and metadata
- Serve the gallery listing and theme files
- Accept JSON Resume pastes if we host them; rendering stays in the Rust crate
- SchemaResume / UniversalResume bodies are converted before store (see [`../converter/`](../converter/))
- No auth or payments in the first API slice

The renderer crate lives in [`../renderer/`](../renderer/). This package should depend on it rather than re-implement HTML emission.
