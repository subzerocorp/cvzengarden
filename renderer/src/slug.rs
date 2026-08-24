use std::collections::HashSet;

/// `slugify(primary + "-" + startYear)` with `-2`, `-3` on collision.
pub fn entry_slug(primary: &str, start_year: Option<u16>, used: &mut HashSet<String>) -> String {
    let raw = match start_year {
        Some(year) if primary.is_empty() => format!("{year:04}"),
        Some(year) => format!("{primary}-{year:04}"),
        None => primary.to_string(),
    };
    let mut base = slugify(&raw);
    if base.is_empty() {
        base = "entry".to_string();
    }
    uniquify(base, used)
}

pub fn uniquify(base: String, used: &mut HashSet<String>) -> String {
    if used.insert(base.clone()) {
        return base;
    }
    let mut n = 2u32;
    loop {
        let candidate = format!("{base}-{n}");
        if used.insert(candidate.clone()) {
            return candidate;
        }
        n += 1;
    }
}

pub fn slugify(input: &str) -> String {
    let mut out = String::new();
    let mut pending_hyphen = false;
    for ch in input.chars() {
        if ch.is_alphanumeric() {
            if pending_hyphen && !out.is_empty() {
                out.push('-');
            }
            pending_hyphen = false;
            for c in ch.to_lowercase() {
                out.push(c);
            }
        } else if !out.is_empty() {
            pending_hyphen = true;
        }
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn fixture_slugs() {
        assert_eq!(slugify("Acme Studio-2022"), "acme-studio-2022");
        assert_eq!(
            slugify("CSS Design Awards — Site of the Day-2021"),
            "css-design-awards-site-of-the-day-2021"
        );
        assert_eq!(slugify("Minutes, Plain-2019"), "minutes-plain-2019");
        assert_eq!(
            slugify("The stylesheet is a public API-2022"),
            "the-stylesheet-is-a-public-api-2022"
        );
        assert_eq!(slugify("Sam Okonkwo"), "sam-okonkwo");
    }

    #[test]
    fn collisions_append_counter() {
        let mut used = HashSet::new();
        assert_eq!(entry_slug("Acme", Some(2022), &mut used), "acme-2022");
        assert_eq!(entry_slug("Acme", Some(2022), &mut used), "acme-2022-2");
        assert_eq!(entry_slug("Acme", Some(2022), &mut used), "acme-2022-3");
    }

    #[test]
    fn year_only_and_empty_fall_back() {
        let mut used = HashSet::new();
        assert_eq!(entry_slug("", Some(2022), &mut used), "2022");
        assert_eq!(entry_slug("", None, &mut used), "entry");
        assert_eq!(entry_slug("Acme", None, &mut used), "acme");
    }
}
