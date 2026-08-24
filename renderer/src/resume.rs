use serde::Deserialize;

/// A JSON Resume document ([`jsonresume/resume-schema`]).
///
/// Unknown properties are accepted and ignored by the HTML emitter.
#[derive(Debug, Clone, Default, PartialEq, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Resume {
    #[serde(rename = "$schema", default)]
    pub schema: Option<String>,
    #[serde(default)]
    pub basics: Option<Basics>,
    #[serde(default)]
    pub work: Option<Vec<Work>>,
    #[serde(default)]
    pub volunteer: Option<Vec<Volunteer>>,
    #[serde(default)]
    pub education: Option<Vec<Education>>,
    #[serde(default)]
    pub awards: Option<Vec<Award>>,
    #[serde(default)]
    pub certificates: Option<Vec<Certificate>>,
    #[serde(default)]
    pub publications: Option<Vec<Publication>>,
    #[serde(default)]
    pub skills: Option<Vec<Skill>>,
    #[serde(default)]
    pub languages: Option<Vec<Language>>,
    #[serde(default)]
    pub interests: Option<Vec<Interest>>,
    #[serde(default)]
    pub references: Option<Vec<Reference>>,
    #[serde(default)]
    pub projects: Option<Vec<Project>>,
    #[serde(default)]
    pub meta: Option<Meta>,
}

impl Resume {
    /// Deserialize a JSON Resume document.
    ///
    /// # Errors
    ///
    /// Returns the `serde_json::Error` when `json` is malformed or a field
    /// has a type these structs do not accept (unknown fields are ignored).
    pub fn from_json(json: &str) -> Result<Self, serde_json::Error> {
        serde_json::from_str(json)
    }
}

#[derive(Debug, Clone, Default, PartialEq, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Basics {
    #[serde(default)]
    pub name: Option<String>,
    #[serde(default)]
    pub label: Option<String>,
    #[serde(default)]
    pub image: Option<String>,
    #[serde(default)]
    pub email: Option<String>,
    #[serde(default)]
    pub phone: Option<String>,
    #[serde(default)]
    pub url: Option<String>,
    #[serde(default)]
    pub summary: Option<String>,
    #[serde(default)]
    pub location: Option<Location>,
    #[serde(default)]
    pub profiles: Option<Vec<Profile>>,
}

#[derive(Debug, Clone, Default, PartialEq, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Location {
    #[serde(default)]
    pub address: Option<String>,
    #[serde(default)]
    pub postal_code: Option<String>,
    #[serde(default)]
    pub city: Option<String>,
    #[serde(default)]
    pub country_code: Option<String>,
    #[serde(default)]
    pub region: Option<String>,
}

#[derive(Debug, Clone, Default, PartialEq, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Profile {
    #[serde(default)]
    pub network: Option<String>,
    #[serde(default)]
    pub username: Option<String>,
    #[serde(default)]
    pub url: Option<String>,
}

#[derive(Debug, Clone, Default, PartialEq, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Work {
    #[serde(default)]
    pub name: Option<String>,
    #[serde(default)]
    pub location: Option<String>,
    /// Company tagline. Stored on the Resume; not rendered in HTML contract 1.0.
    #[serde(default)]
    pub description: Option<String>,
    #[serde(default)]
    pub position: Option<String>,
    #[serde(default)]
    pub url: Option<String>,
    #[serde(default)]
    pub start_date: Option<String>,
    #[serde(default)]
    pub end_date: Option<String>,
    #[serde(default)]
    pub summary: Option<String>,
    #[serde(default)]
    pub highlights: Option<Vec<String>>,
}

#[derive(Debug, Clone, Default, PartialEq, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Volunteer {
    #[serde(default)]
    pub organization: Option<String>,
    #[serde(default)]
    pub position: Option<String>,
    #[serde(default)]
    pub url: Option<String>,
    #[serde(default)]
    pub start_date: Option<String>,
    #[serde(default)]
    pub end_date: Option<String>,
    #[serde(default)]
    pub summary: Option<String>,
    #[serde(default)]
    pub highlights: Option<Vec<String>>,
}

#[derive(Debug, Clone, Default, PartialEq, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Education {
    #[serde(default)]
    pub institution: Option<String>,
    #[serde(default)]
    pub url: Option<String>,
    #[serde(default)]
    pub area: Option<String>,
    #[serde(default)]
    pub study_type: Option<String>,
    #[serde(default)]
    pub start_date: Option<String>,
    #[serde(default)]
    pub end_date: Option<String>,
    /// `"3.7"`, `3.7`, or `4` in the wild; always text here (`"3.7"`, `"4"`).
    #[serde(default, deserialize_with = "string_or_number")]
    pub score: Option<String>,
    #[serde(default)]
    pub courses: Option<Vec<String>>,
}

#[derive(Debug, Clone, Default, PartialEq, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Award {
    #[serde(default)]
    pub title: Option<String>,
    #[serde(default)]
    pub date: Option<String>,
    #[serde(default)]
    pub awarder: Option<String>,
    #[serde(default)]
    pub summary: Option<String>,
}

#[derive(Debug, Clone, Default, PartialEq, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Certificate {
    #[serde(default)]
    pub name: Option<String>,
    #[serde(default)]
    pub date: Option<String>,
    #[serde(default)]
    pub url: Option<String>,
    #[serde(default)]
    pub issuer: Option<String>,
}

#[derive(Debug, Clone, Default, PartialEq, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Publication {
    #[serde(default)]
    pub name: Option<String>,
    #[serde(default)]
    pub publisher: Option<String>,
    #[serde(default)]
    pub release_date: Option<String>,
    #[serde(default)]
    pub url: Option<String>,
    #[serde(default)]
    pub summary: Option<String>,
}

#[derive(Debug, Clone, Default, PartialEq, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Skill {
    #[serde(default)]
    pub name: Option<String>,
    #[serde(default)]
    pub level: Option<String>,
    #[serde(default)]
    pub keywords: Option<Vec<String>>,
}

#[derive(Debug, Clone, Default, PartialEq, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Language {
    #[serde(default)]
    pub language: Option<String>,
    #[serde(default)]
    pub fluency: Option<String>,
}

#[derive(Debug, Clone, Default, PartialEq, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Interest {
    #[serde(default)]
    pub name: Option<String>,
    #[serde(default)]
    pub keywords: Option<Vec<String>>,
}

#[derive(Debug, Clone, Default, PartialEq, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Reference {
    #[serde(default)]
    pub name: Option<String>,
    #[serde(default)]
    pub reference: Option<String>,
}

#[derive(Debug, Clone, Default, PartialEq, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Project {
    #[serde(default)]
    pub name: Option<String>,
    #[serde(default)]
    pub description: Option<String>,
    #[serde(default)]
    pub highlights: Option<Vec<String>>,
    #[serde(default)]
    pub keywords: Option<Vec<String>>,
    #[serde(default)]
    pub start_date: Option<String>,
    #[serde(default)]
    pub end_date: Option<String>,
    #[serde(default)]
    pub url: Option<String>,
    #[serde(default)]
    pub roles: Option<Vec<String>>,
    #[serde(default)]
    pub entity: Option<String>,
    #[serde(default)]
    pub r#type: Option<String>,
}

/// A JSON string or number, as an untagged shape for `string_or_number`.
#[derive(Deserialize)]
#[serde(untagged)]
enum StringOrNumber {
    String(String),
    Number(serde_json::Number),
}

impl From<StringOrNumber> for String {
    fn from(value: StringOrNumber) -> Self {
        match value {
            StringOrNumber::String(text) => text,
            StringOrNumber::Number(number) => number.to_string(),
        }
    }
}

/// Accept a JSON string or number where the schema says string. Integers
/// print without a decimal point (`4`); floats print as written (`3.7`).
fn string_or_number<'de, D>(deserializer: D) -> Result<Option<String>, D::Error>
where
    D: serde::Deserializer<'de>,
{
    Option::<StringOrNumber>::deserialize(deserializer).map(|value| value.map(String::from))
}

/// JSON Resume `meta`. Never rendered. Extra keys (`x-schema-resume`, …) stay here.
#[derive(Debug, Clone, Default, PartialEq, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Meta {
    #[serde(default)]
    pub canonical: Option<String>,
    #[serde(default)]
    pub version: Option<String>,
    #[serde(default)]
    pub last_modified: Option<String>,
    #[serde(flatten)]
    pub extra: serde_json::Map<String, serde_json::Value>,
}

#[cfg(test)]
mod tests {
    use super::*;

    fn score_of(json: &str) -> Option<String> {
        let education: Education = serde_json::from_str(json).expect("valid education");
        education.score
    }

    #[test]
    fn score_accepts_string_float_and_integer() {
        assert_eq!(score_of(r#"{"score":"3.7"}"#).as_deref(), Some("3.7"));
        assert_eq!(score_of(r#"{"score":3.7}"#).as_deref(), Some("3.7"));
        assert_eq!(score_of(r#"{"score":4}"#).as_deref(), Some("4"));
        assert_eq!(
            score_of(r#"{"score":"First Class"}"#).as_deref(),
            Some("First Class")
        );
    }

    #[test]
    fn score_missing_or_null_is_none() {
        assert_eq!(score_of("{}"), None);
        assert_eq!(score_of(r#"{"score":null}"#), None);
    }

    #[test]
    fn score_rejects_other_shapes() {
        assert!(serde_json::from_str::<Education>(r#"{"score":[3.7]}"#).is_err());
        assert!(serde_json::from_str::<Education>(r#"{"score":true}"#).is_err());
    }
}
