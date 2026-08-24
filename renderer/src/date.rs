//! JSON Resume `iso8601` dates: `YYYY`, `YYYY-MM`, or `YYYY-MM-DD`.

const MONTHS: [&str; 12] = [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
];

/// `(datetime raw value, visible English text)`.
pub fn format_iso_date(raw: &str) -> Option<(String, String)> {
    let raw = raw.trim();
    if raw.is_empty() {
        return None;
    }

    let parts: Vec<&str> = raw.split('-').collect();
    match parts.as_slice() {
        [year] if is_year(year) => Some((raw.to_string(), (*year).to_string())),
        [year, month] if is_year(year) => {
            let visible = format!("{} {}", month_name(month)?, year);
            Some((raw.to_string(), visible))
        }
        [year, month, day] if is_year(year) => {
            let day: u32 = day.parse().ok()?;
            if !(1..=31).contains(&day) {
                return None;
            }
            let visible = format!("{} {}, {}", month_name(month)?, day, year);
            Some((raw.to_string(), visible))
        }
        _ => Some((raw.to_string(), raw.to_string())),
    }
}

fn is_year(s: &str) -> bool {
    s.len() == 4 && s.bytes().all(|b| b.is_ascii_digit())
}

fn month_name(month: &str) -> Option<&'static str> {
    let n: usize = month.parse().ok()?;
    MONTHS
        .get(n.saturating_sub(1))
        .copied()
        .filter(|_| (1..=12).contains(&n))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn formats_fixture_dates() {
        assert_eq!(
            format_iso_date("2022-03").unwrap(),
            ("2022-03".into(), "March 2022".into())
        );
        assert_eq!(
            format_iso_date("2018-06").unwrap(),
            ("2018-06".into(), "June 2018".into())
        );
        assert_eq!(
            format_iso_date("2020").unwrap(),
            ("2020".into(), "2020".into())
        );
        assert_eq!(
            format_iso_date("2022-01-15").unwrap(),
            ("2022-01-15".into(), "January 15, 2022".into())
        );
    }
}
