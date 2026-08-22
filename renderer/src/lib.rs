//! ResumeZen renderer stub.
//!
//! Future work: parse `resume.json` and emit the fixed HTML class contract
//! documented in `/skeleton/CLASS-CONTRACT.md`. This crate is a placeholder
//! so the workspace layout is real before the implementation lands.

/// Crate version. Not the HTML contract version (`data-rz-schema`).
pub fn version() -> &'static str {
    env!("CARGO_PKG_VERSION")
}

/// HTML class-contract version this crate will target once implemented.
pub const CONTRACT_VERSION: &str = "1.0";

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn stub_exports_contract_version() {
        assert_eq!(CONTRACT_VERSION, "1.0");
        assert_eq!(version(), env!("CARGO_PKG_VERSION"));
    }
}
