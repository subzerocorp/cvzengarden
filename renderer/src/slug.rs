use std::collections::HashSet;

const ENTRY_FALLBACK: &str = "entry";
const SKILL_FALLBACK: &str = "skill";

/// `slugify(primary) + "-" + startYear` with `-2`, `-3` on collision.
/// A name that slugifies to nothing (`🔥🔥`, `""`) becomes `entry` first, so
/// the year is never the whole id (`entry-2020`).
pub fn entry_slug(primary: &str, start_year: Option<u16>, used: &mut HashSet<String>) -> String {
    let name = slug_or(primary, ENTRY_FALLBACK);
    let base = start_year.map_or_else(|| name.clone(), |year| format!("{name}-{year:04}"));
    uniquify(base, used)
}

/// `slugify(name)` with `-2`, `-3` on collision; `skill` when nothing survives.
pub fn skill_slug(name: &str, used: &mut HashSet<String>) -> String {
    uniquify(slug_or(name, SKILL_FALLBACK), used)
}

fn slug_or(input: &str, fallback: &str) -> String {
    let slug = slugify(input);
    if slug.is_empty() {
        fallback.to_string()
    } else {
        slug
    }
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
    fn empty_name_falls_back_to_entry_before_year() {
        let mut used = HashSet::new();
        assert_eq!(entry_slug("", Some(2022), &mut used), "entry-2022");
        assert_eq!(entry_slug("", None, &mut used), "entry");
        assert_eq!(entry_slug("Acme", None, &mut used), "acme");
    }

    #[test]
    fn emoji_only_name_falls_back_to_entry_and_counts() {
        let mut used = HashSet::new();
        assert_eq!(entry_slug("🔥🔥", Some(2020), &mut used), "entry-2020");
        assert_eq!(entry_slug("🔥🔥", Some(2020), &mut used), "entry-2020-2");
        assert_eq!(entry_slug("🔥🔥", None, &mut used), "entry");
    }

    #[test]
    fn skill_slug_falls_back_and_counts() {
        let mut used = HashSet::new();
        assert_eq!(skill_slug("🎨", &mut used), "skill");
        assert_eq!(skill_slug("", &mut used), "skill-2");
        assert_eq!(skill_slug("Front-end", &mut used), "front-end");
    }
}
