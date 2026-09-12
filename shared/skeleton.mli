val contract_version : string
val known_profile_types : string list
val nonempty : Js.String.t option -> Js.String.t option
val trimmed : Js.String.t list -> Js.String.t list
val any_nonblank : Js.String.t list -> bool
val normalize_newlines : Js.String.t -> Js.String.t
val numeric : Js.Re.t
val format_score : string -> string
val tel_href : Js.String.t -> string
val profile_type : Js.String.t -> Js.String.t
val location_text : Resume.Location.t option -> Js.String.t option
val education_secondary : Resume.Education.t -> Js.String.t option
val document_title : Resume.t -> Js.String.t

type primary = { text : string; href : string option }

val primary_link : name:Js.String.t option -> url:Js.String.t option -> primary option

type date_token = { raw : string; parsed : Iso_date.t option }

val date_token : Js.String.t option -> date_token option

type entry = {
  kind : string;
  primary : primary option;
  secondary : string option;
  start : date_token option;
  end_ : date_token option;
  single_date : date_token option;
  location : string option;
  score : string option;
  summary : string option;
  highlights : string list;
  tags : string list;
  meta : (string * string) list;
}

val blank_entry : entry
val has_header : entry -> bool
val has_content : entry -> bool
val slug_year : entry -> int option
val is_current : entry -> bool

type section = { id : string; title : string; extra : bool; data_kind : string option }

val builtin : string -> string -> section
val extra : string -> string -> string -> section
val summary_section : section
val experience : section
val volunteer_section : section
val education_section : section
val awards_section : section
val certificates_section : section
val publications_section : section
val skills_section : section
val languages_section : section
val interests_entries : section
val interests_tags : section
val references_section : section
val projects_section : section
val work_entry : Resume.Work.t -> entry
val volunteer_entry : Resume.Volunteer.t -> entry
val education_entry : Resume.Education.t -> entry
val award_entry : Resume.Award.t -> entry
val certificate_entry : Resume.Certificate.t -> entry
val publication_entry : Resume.Publication.t -> entry
val reference_entry : Resume.Reference.t -> entry
val project_meta : Resume.Project.t -> (string * Js.String.t) list
val project_entry : Resume.Project.t -> entry
val emit_value : Html.t -> attrs:Html.attr list -> href:string option -> Js.String.t -> unit

type contact = {
  c_kind : string;
  c_label : string;
  c_itemprop : string option;
  c_href : string option;
  c_text : string;
}

val contacts : Resume.Basics.t -> contact list
val emit_contact : Html.t -> contact -> unit
val emit_contacts : Html.t -> Resume.Basics.t -> unit

type link = { l_kind : string; l_label : string; l_href : string option; l_text : string }

val profile_link : Resume.Profile.t -> link option
val emit_link : Html.t -> link -> unit
val emit_links : Html.t -> Resume.Profile.t list -> unit
val emit_header : Html.t -> Resume.Basics.t option -> unit
val open_section : Html.t -> section -> unit
val emit_prose : Html.t -> string -> Js.String.t -> unit
val emit_summary : Html.t -> Resume.Basics.t option -> unit
val emit_date : Html.t -> string -> date_token -> unit
val emit_dates : Html.t -> entry -> unit
val emit_primary : Html.t -> primary -> unit
val emit_entry_header : Html.t -> entry -> unit
val emit_meta : Html.t -> (Js.String.t * Js.String.t) list -> unit

val emit_list :
  Html.t ->
  list_class:string ->
  item_class:string ->
  map:(Js.String.t -> Js.String.t) ->
  Js.String.t list ->
  unit

val emit_tags : Html.t -> Js.String.t list -> unit
val emit_bullets : Html.t -> Js.String.t list -> unit
val emit_entry : Html.t -> Slug.used -> entry -> unit
val emit_entry_section : Html.t -> Slug.used -> section -> entry list -> unit
val skill_has_content : Resume.Skill.t -> bool
val emit_skill_group : Html.t -> Slug.used -> Resume.Skill.t -> unit
val emit_skills : Html.t -> Resume.Skill.t list -> unit
val emit_languages : Html.t -> Resume.Language.t list -> unit
val emit_interests : Html.t -> Slug.used -> Resume.Interest.t list -> unit
val emit_article : Html.t -> Resume.t -> unit
val render_article : Resume.t -> string
val render : ?style:string -> Resume.t -> string
