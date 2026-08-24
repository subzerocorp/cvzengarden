//! The crate's only public error type.
//!
//! Callers (the Axum backend, the Wasm bridge, the example oracle) match on
//! `RenderError` and never need to depend on `serde_json` themselves.

/// Why a JSON Resume document could not be rendered.
#[derive(Debug, Clone, PartialEq, Eq, thiserror::Error)]
pub enum RenderError {
    /// The text is not valid JSON, or a field has a type the JSON Resume
    /// schema does not allow. `message` already names the position, so the
    /// Display of this error reads e.g.
    /// `not a valid JSON Resume document: EOF while parsing an object at line 1 column 1`.
    #[error("not a valid JSON Resume document: {message}")]
    InvalidDocument {
        /// Parser message including `at line N column M`.
        message: String,
        /// 1-based line of the failure (0 when the parser has no position).
        line: usize,
        /// 1-based column of the failure (0 when the parser has no position).
        column: usize,
    },
}

impl From<serde_json::Error> for RenderError {
    fn from(err: serde_json::Error) -> Self {
        Self::InvalidDocument {
            message: err.to_string(),
            line: err.line(),
            column: err.column(),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn parse_failure(json: &str) -> RenderError {
        serde_json::from_str::<serde_json::Value>(json)
            .expect_err("input must be malformed")
            .into()
    }

    #[test]
    fn from_serde_keeps_line_and_column() {
        let RenderError::InvalidDocument {
            message,
            line,
            column,
        } = parse_failure("{");
        assert_eq!((line, column), (1, 1));
        assert!(message.contains("line 1"), "{message}");
    }

    #[test]
    fn display_is_plain_words_with_position() {
        let text = parse_failure("{\n  \"basics\": }").to_string();
        assert!(
            text.starts_with("not a valid JSON Resume document: "),
            "{text}"
        );
        assert!(text.contains("line 2"), "{text}");
    }
}
