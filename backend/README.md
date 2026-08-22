# `backend/`

Axum + SQLite API. **Not started.**

Planned responsibilities (later):

- Persist submitted themes (pure `.css`) and metadata
- Serve the gallery listing and theme files
- Accept `resume.json` only if we host pastes; rendering stays in the Rust crate
- No auth or payments in the first API slice

The renderer crate lives in [`../renderer/`](../renderer/). This package should depend on it rather than re-implement HTML emission.
