//! `ResumeZen` renderer: JSON Resume → fixed `rz-*` Skeleton HTML.
//!
//! This crate is a pure function. It does not load Themes, talk to the
//! network, or emit PDF. Themes never see the Resume; they only target the
//! HTML class contract in `skeleton/CLASS-CONTRACT.md`.

mod date;
mod emit;
mod html;
mod resume;
mod slug;
mod url;

pub use resume::{
    Award, Basics, Certificate, Education, Interest, Language, Location, Meta, Profile, Project,
    Publication, Reference, Resume, Skill, Volunteer, Work,
};

/// Crate version. Not the HTML contract version (`data-rz-schema`).
#[must_use]
pub fn version() -> &'static str {
    env!("CARGO_PKG_VERSION")
}

/// HTML class-contract version this crate emits on `.rz-resume`.
pub const CONTRACT_VERSION: &str = "1.0";

/// Render an immutable JSON Resume into a standalone Skeleton HTML document.
///
/// Empty sections, contacts, links, entries, and bullets are omitted. Fields
/// outside the HTML contract field map (`meta`, `work[].description`,
/// `basics.location.address`, `postalCode`, unknown `additionalProperties`)
/// are ignored by the emitter.
#[must_use]
pub fn render(resume: &Resume) -> String {
    emit::render(resume)
}

/// Parse a JSON Resume document and render it.
///
/// # Errors
///
/// Returns the `serde_json::Error` when `json` is not a valid JSON Resume
/// document (malformed JSON or a field of the wrong type).
pub fn render_json(json: &str) -> Result<String, serde_json::Error> {
    Ok(render(&Resume::from_json(json)?))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn exports_contract_version() {
        assert_eq!(CONTRACT_VERSION, "1.0");
        assert_eq!(version(), env!("CARGO_PKG_VERSION"));
    }
}
