//! JSON Resume `iso8601` dates: `YYYY`, `YYYY-MM`, or `YYYY-MM-DD`.
//!
//! Pure calculations over user text. Nothing here indexes bytes: an Author
//! may write fullwidth digits, kanji, or currency signs in a date field and
//! the answer is simply `None`.

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

/// A calendar-valid date with the precision the Author gave.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct IsoDate {
    pub year: u16,
    pub month: Option<u8>,
    pub day: Option<u8>,
}

impl IsoDate {
    /// Canonical `datetime` attribute value: `YYYY`, `YYYY-MM`, or `YYYY-MM-DD`.
    pub fn datetime(self) -> String {
        match (self.month, self.day) {
            (Some(month), Some(day)) => format!("{:04}-{month:02}-{day:02}", self.year),
            (Some(month), None) => format!("{:04}-{month:02}", self.year),
            _ => format!("{:04}", self.year),
        }
    }

    /// Visible English text: `2020`, `March 2020`, `January 15, 2022`.
    pub fn visible(self) -> String {
        let month = self.month.and_then(month_name);
        match (month, self.day) {
            (Some(month), Some(day)) => format!("{month} {day}, {}", self.year),
            (Some(month), None) => format!("{month} {}", self.year),
            _ => self.year.to_string(),
        }
    }
}

/// Parse an `iso8601` date, dropping a time component after `T` or a space.
///
/// Returns `None` for anything that is not a calendar-valid `YYYY`,
/// `YYYY-MM`, or `YYYY-MM-DD` in ASCII digits (`March 2020`, `2020-13`,
/// `2020-02-30`, `２０２０`), including a date followed by prose
/// (`2020 (approx)`): only a time-like tail (`09:00…`) is dropped.
pub fn parse_iso_date(raw: &str) -> Option<IsoDate> {
    let parts: Vec<&str> = date_part(raw.trim()).split('-').collect();
    let date = match parts.as_slice() {
        [year] => IsoDate {
            year: digits(year, 4)?,
            month: None,
            day: None,
        },
        [year, month] => IsoDate {
            year: digits(year, 4)?,
            month: Some(digits(month, 2)?),
            day: None,
        },
        [year, month, day] => IsoDate {
            year: digits(year, 4)?,
            month: Some(digits(month, 2)?),
            day: Some(digits(day, 2)?),
        },
        _ => return None,
    };
    is_calendar_valid(date).then_some(date)
}

/// The text before a `T` or space that introduces a time (`HH:`); otherwise
/// the whole string, so `2020 (approx)` stays unparseable rather than
/// silently becoming `2020`.
fn date_part(raw: &str) -> &str {
    raw.split_once(['T', ' '])
        .filter(|(_, tail)| starts_with_time(tail))
        .map_or(raw, |(date, _)| date)
}

/// `HH:` — two ASCII digits then a colon.
fn starts_with_time(tail: &str) -> bool {
    let mut chars = tail.chars();
    let hour = [chars.next(), chars.next()];
    hour.iter().all(|c| c.is_some_and(|c| c.is_ascii_digit())) && chars.next() == Some(':')
}

/// Exactly `len` ASCII digits, as a number.
fn digits<N: std::str::FromStr>(text: &str, len: usize) -> Option<N> {
    let well_formed = text.chars().count() == len && text.chars().all(|c| c.is_ascii_digit());
    well_formed.then(|| text.parse().ok()).flatten()
}

fn is_calendar_valid(date: IsoDate) -> bool {
    match (date.month, date.day) {
        (None, _) => true,
        (Some(month), None) => (1..=12).contains(&month),
        (Some(month), Some(day)) => day >= 1 && day <= days_in_month(date.year, month),
    }
}

/// Days in `month` of `year`; `0` for a month outside `1..=12`.
fn days_in_month(year: u16, month: u8) -> u8 {
    match month {
        1 | 3 | 5 | 7 | 8 | 10 | 12 => 31,
        4 | 6 | 9 | 11 => 30,
        2 if is_leap_year(year) => 29,
        2 => 28,
        _ => 0,
    }
}

fn is_leap_year(year: u16) -> bool {
    year.is_multiple_of(4) && (!year.is_multiple_of(100) || year.is_multiple_of(400))
}

fn month_name(month: u8) -> Option<&'static str> {
    MONTHS.get(usize::from(month).checked_sub(1)?).copied()
}

#[cfg(test)]
mod tests {
    use super::*;

    fn date(year: u16, month: Option<u8>, day: Option<u8>) -> IsoDate {
        IsoDate { year, month, day }
    }

    #[test]
    fn parses_year_month_and_day_precision() {
        assert_eq!(parse_iso_date("2020"), Some(date(2020, None, None)));
        assert_eq!(parse_iso_date("2022-03"), Some(date(2022, Some(3), None)));
        assert_eq!(
            parse_iso_date("2020-12-31"),
            Some(date(2020, Some(12), Some(31)))
        );
        assert_eq!(parse_iso_date(" 2020 "), Some(date(2020, None, None)));
    }

    #[test]
    fn rejects_unpadded_month_and_month_zero() {
        assert_eq!(parse_iso_date("2020-1"), None);
        assert_eq!(parse_iso_date("2020-00"), None);
        assert_eq!(parse_iso_date("2020-13"), None);
    }

    #[test]
    fn validates_day_against_month_and_leap_year() {
        assert_eq!(parse_iso_date("2021-02-29"), None);
        assert_eq!(parse_iso_date("2020-02-30"), None);
        assert_eq!(parse_iso_date("2021-04-31"), None);
        assert_eq!(parse_iso_date("2020-05-00"), None);
        assert_eq!(
            parse_iso_date("2020-02-29"),
            Some(date(2020, Some(2), Some(29)))
        );
        assert_eq!(
            parse_iso_date("2024-02-29"),
            Some(date(2024, Some(2), Some(29)))
        );
        assert_eq!(parse_iso_date("1900-02-29"), None);
        assert_eq!(
            parse_iso_date("2000-02-29"),
            Some(date(2000, Some(2), Some(29)))
        );
    }

    #[test]
    fn rejects_out_of_range_parts_at_day_precision() {
        // Arrange: a month outside 1..=12 with a day, a day above every
        // month's length, and a fourth `-` part.
        let out_of_range = ["2020-13-01", "2020-00-15", "2020-01-32", "2020-01-01-01"];

        for raw in out_of_range {
            // Act
            let parsed = parse_iso_date(raw);

            // Assert
            assert_eq!(parsed, None, "{raw:?}");
        }
    }

    #[test]
    fn truncates_time_component_at_t_or_space() {
        assert_eq!(
            parse_iso_date("2020-05-31T09:00:00Z"),
            Some(date(2020, Some(5), Some(31)))
        );
        assert_eq!(
            parse_iso_date("2020-05-31 09:00"),
            Some(date(2020, Some(5), Some(31)))
        );
    }

    #[test]
    fn keeps_prose_after_a_space_unparseable() {
        // Arrange: a space followed by something that is not `HH:`.
        let prose = ["2020 (approx)", "2020 ish", "2020-05 9:00", "2020T"];

        for raw in prose {
            // Act
            let parsed = parse_iso_date(raw);

            // Assert
            assert_eq!(parsed, None, "{raw:?}");
        }
    }

    #[test]
    fn rejects_non_ascii_and_prose_without_panicking() {
        for raw in [
            "２０２０",
            "日本語",
            "€€",
            "20€0",
            "March 2020",
            "Present",
            "",
            "-",
        ] {
            assert_eq!(parse_iso_date(raw), None, "{raw:?}");
        }
    }

    #[test]
    fn formats_fixture_dates() {
        let fmt = |raw: &str| {
            let d = parse_iso_date(raw).unwrap();
            (d.datetime(), d.visible())
        };
        assert_eq!(fmt("2022-03"), ("2022-03".into(), "March 2022".into()));
        assert_eq!(fmt("2018-06"), ("2018-06".into(), "June 2018".into()));
        assert_eq!(fmt("2020"), ("2020".into(), "2020".into()));
        assert_eq!(
            fmt("2022-01-15"),
            ("2022-01-15".into(), "January 15, 2022".into())
        );
        assert_eq!(
            fmt("2023-05-31T09:00:00Z"),
            ("2023-05-31".into(), "May 31, 2023".into())
        );
    }
}
