//! URL hygiene for `href` attributes. Pure calculations over Author text.
//!
//! A wild JSON Resume may carry `https://`, `//`, `javascript:alert(1)`, or a
//! bare `example.com` in any `url` field. Only `http(s)://` with a host,
//! `mailto:`, and `tel:` ever become an `href`; everything else is `None` and
//! the caller falls back to plain text or omits the node (contract §5.2).

/// Schemes that are safe to emit verbatim once they carry a non-empty body.
const OPAQUE_SCHEMES: [&str; 2] = ["mailto:", "tel:"];

/// The `href` a raw URL may be emitted as, or `None` when it must not be.
///
/// - `http://` / `https://` with a non-empty host → as written (trimmed)
/// - `mailto:` / `tel:` with a non-empty body → as written
/// - `//host…` or a bare `host…` (no scheme) → `https://host…`
/// - any other scheme (`javascript:`, `data:`, `ftp:`) or an empty host → `None`
#[must_use]
pub fn safe_href(raw: &str) -> Option<String> {
    let url = raw.trim();
    if let Some(rest) = strip_http_scheme(url) {
        return has_host(rest).then(|| url.to_string());
    }
    if OPAQUE_SCHEMES.iter().any(|scheme| has_body(url, scheme)) {
        return Some(url.to_string());
    }
    if has_scheme(url) {
        return None;
    }
    let bare = url.strip_prefix("//").unwrap_or(url);
    has_host(bare).then(|| format!("https://{bare}"))
}

/// The host part of an `http(s)` URL (or of a bare `host/path`): the text
/// after the scheme up to the first `/`, `?`, or `#`.
#[must_use]
pub fn hostname(url: &str) -> &str {
    let url = url.trim();
    let rest = strip_http_scheme(url).unwrap_or(url);
    rest.split(['/', '?', '#']).next().unwrap_or(rest)
}

fn strip_http_scheme(url: &str) -> Option<&str> {
    url.strip_prefix("https://")
        .or_else(|| url.strip_prefix("http://"))
}

/// `true` when `url` starts with `scheme` and has something after it.
fn has_body(url: &str, scheme: &str) -> bool {
    url.strip_prefix(scheme)
        .is_some_and(|body| !body.trim().is_empty())
}

/// A non-empty authority before any path, query, or fragment.
fn has_host(rest: &str) -> bool {
    !hostname(rest).is_empty()
}

/// RFC 3986 scheme: a letter, then letters / digits / `+` / `-` / `.`, then `:`.
fn has_scheme(url: &str) -> bool {
    url.split_once(':').is_some_and(|(scheme, _)| {
        scheme.starts_with(|c: char| c.is_ascii_alphabetic())
            && scheme
                .chars()
                .all(|c| c.is_ascii_alphanumeric() || matches!(c, '+' | '-' | '.'))
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn keeps_http_urls_with_a_host() {
        assert_eq!(
            safe_href("https://verify.example/abc").as_deref(),
            Some("https://verify.example/abc")
        );
        assert_eq!(
            safe_href(" http://example.com ").as_deref(),
            Some("http://example.com")
        );
    }

    #[test]
    fn prefixes_bare_and_protocol_relative_hosts() {
        assert_eq!(
            safe_href("example.com/me").as_deref(),
            Some("https://example.com/me")
        );
        assert_eq!(
            safe_href("//example.com").as_deref(),
            Some("https://example.com")
        );
    }

    #[test]
    fn keeps_mailto_and_tel_with_a_body() {
        assert_eq!(
            safe_href("mailto:a@b.example").as_deref(),
            Some("mailto:a@b.example")
        );
        assert_eq!(safe_href("tel:+1555").as_deref(), Some("tel:+1555"));
        assert_eq!(safe_href("mailto:"), None);
        assert_eq!(safe_href("tel: "), None);
    }

    #[test]
    fn rejects_empty_hosts_and_foreign_schemes() {
        for raw in [
            "https://",
            "http://",
            "//",
            "",
            "   ",
            "https:///path",
            "javascript:alert(1)",
            "JAVASCRIPT:alert(1)",
            "data:text/html,hi",
            "ftp://files.example",
            "vbscript:x",
        ] {
            assert_eq!(safe_href(raw), None, "{raw:?}");
        }
    }

    #[test]
    fn hostname_strips_scheme_path_query_and_fragment() {
        assert_eq!(hostname("https://jordanhale.example"), "jordanhale.example");
        assert_eq!(
            hostname("https://www.linkedin.com/in/jordanhale"),
            "www.linkedin.com"
        );
        assert_eq!(hostname("http://a.example?x=1"), "a.example");
        assert_eq!(hostname("a.example#top"), "a.example");
        assert_eq!(hostname("https://"), "");
    }
}
