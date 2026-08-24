//! Wasm bridge for `resumezen_renderer`.
//!
//! The pure crate knows nothing about the browser; this crate is the only
//! place `wasm-bindgen` appears. Errors cross the ABI as their plain-words
//! `Display` text so the chrome can show them unchanged.

use wasm_bindgen::prelude::wasm_bindgen;

/// Render a JSON Resume document to Skeleton HTML.
///
/// # Errors
///
/// Returns the renderer's error message (naming line and column) when the
/// document is not a valid JSON Resume.
#[wasm_bindgen]
pub fn render_json(json: &str) -> Result<String, String> {
    // ABI edge: `String` is the only error shape `wasm-bindgen` carries cleanly.
    resumezen_renderer::render_json(json).map_err(|err| err.to_string())
}

/// HTML class-contract version this module emits, for skew checks against
/// the chrome and the Themes.
#[wasm_bindgen]
#[must_use]
pub fn contract_version() -> String {
    resumezen_renderer::CONTRACT_VERSION.to_owned()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn render_json_matches_pure_crate() {
        let json = r#"{"basics":{"name":"Ada Lovelace"}}"#;
        let expected = resumezen_renderer::render_json(json).expect("valid");
        assert_eq!(render_json(json), Ok(expected));
    }

    #[test]
    fn render_json_error_names_the_line() {
        let err = render_json("{").expect_err("malformed");
        assert!(err.contains("line 1"), "{err}");
    }

    #[test]
    fn contract_version_matches_pure_crate() {
        assert_eq!(contract_version(), resumezen_renderer::CONTRACT_VERSION);
    }
}
