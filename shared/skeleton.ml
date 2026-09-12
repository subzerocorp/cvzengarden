(** Resume → Skeleton: the one semantic HTML tree every Theme restyles. A direct port of the
    contract rules in [skeleton/CLASS-CONTRACT.md]; byte-stable against [skeleton/example.html] and
    [skeleton/samples/]. *)

open Resume

let contract_version = "1.0"

let known_profile_types =
  [
    "website";
    "github";
    "gitlab";
    "linkedin";
    "mastodon";
    "bluesky";
    "dribbble";
    "behance";
    "x";
    "other";
  ]

(* ── Calculations on field values ─────────────────────────────────────── *)

let nonempty value =
  Option.bind value (fun s ->
      let trimmed = Js.String.trim s in
      if trimmed = "" then None else Some trimmed)

let trimmed items = items |> List.map Js.String.trim |> List.filter (fun s -> s <> "")
let any_nonblank items = trimmed items <> []

let normalize_newlines text =
  Js.String.replaceByRe
    ~regexp:(Js.Re.fromStringWithFlags "\\r\\n" ~flags:"g")
    ~replacement:"\n" text

let numeric =
  Js.Re.fromStringWithFlags
    "^[+-]?(?:(?:[0-9]+\\.?[0-9]*|\\.[0-9]+)(?:[eE][+-]?[0-9]+)?|inf|infinity|nan)$" ~flags:"i"

let format_score score = if Js.Re.test ~str:score numeric then "GPA " ^ score else score

let tel_href phone =
  "tel:"
  ^ Js.String.replaceByRe
      ~regexp:(Js.Re.fromStringWithFlags "[^0-9+]" ~flags:"g")
      ~replacement:"" phone

let profile_type network =
  let n = Js.String.toLowerCase (Js.String.trim network) in
  let mapped = match n with "twitter" | "x" -> "x" | other -> other in
  if List.mem mapped known_profile_types then mapped else "other"

let location_text (location : Location.t option) =
  Option.bind location (fun (l : Location.t) ->
      match (nonempty l.city, nonempty l.region) with
      | Some c, Some r -> Some (c ^ ", " ^ r)
      | Some c, None -> Some c
      | None, Some r -> Some r
      | None, None -> nonempty l.country_code)

let education_secondary (e : Education.t) =
  match (nonempty e.study_type, nonempty e.area) with
  | Some s, Some a -> Some (s ^ " in " ^ a)
  | Some s, None -> Some s
  | None, Some a -> Some a
  | None, None -> None

let document_title (resume : Resume.t) =
  let basics = resume.basics in
  let name = Option.bind basics (fun (b : Basics.t) -> nonempty b.name) in
  let label = Option.bind basics (fun (b : Basics.t) -> nonempty b.label) in
  match (name, label) with
  | Some n, Some l -> n ^ {js| — |js} ^ l
  | Some n, None -> n
  | None, Some l -> l
  | None, None -> ""

(* ── View models ───────────────────────────────────────────────────────── *)

type primary = { text : string; href : string option }
(** The entry's headline: the name (linked when the URL is safe), or the hostname when only a safe
    URL was given. *)

let primary_link ~name ~url =
  let href = Option.bind (nonempty url) Safe_url.safe_href in
  let text =
    match nonempty name with Some n -> Some n | None -> Option.map Safe_url.hostname href
  in
  Option.map (fun text -> { text; href }) text

type date_token = { raw : string; parsed : Iso_date.t option }
(** A date as the Author wrote it, plus what the renderer made of it. *)

let date_token raw = Option.map (fun raw -> { raw; parsed = Iso_date.parse raw }) (nonempty raw)

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

let blank_entry =
  {
    kind = "extra";
    primary = None;
    secondary = None;
    start = None;
    end_ = None;
    single_date = None;
    location = None;
    score = None;
    summary = None;
    highlights = [];
    tags = [];
    meta = [];
  }

let has_header e =
  Option.is_some e.primary || Option.is_some e.secondary || Option.is_some e.start
  || Option.is_some e.end_ || Option.is_some e.single_date || Option.is_some e.location
  || Option.is_some e.score

let has_content e =
  has_header e || Option.is_some e.summary || e.meta <> [] || any_nonblank e.tags
  || any_nonblank e.highlights

let slug_year e =
  let token = match e.single_date with Some d -> Some d | None -> e.start in
  Option.bind token (fun t -> Option.map (fun (d : Iso_date.t) -> d.year) t.parsed)

let is_current e =
  Option.is_none e.single_date
  && (match e.start with Some { parsed = Some _; _ } -> true | _ -> false)
  && Option.is_none e.end_

type section = { id : string; title : string; extra : bool; data_kind : string option }

let builtin id title = { id; title; extra = false; data_kind = None }
let extra id title kind = { id; title; extra = true; data_kind = Some kind }
let summary_section = builtin "summary" "Summary"
let experience = builtin "experience" "Experience"
let volunteer_section = extra "volunteer" "Volunteer" "entries"
let education_section = builtin "education" "Education"
let awards_section = extra "awards" "Awards" "entries"
let certificates_section = extra "certificates" "Certificates" "entries"
let publications_section = extra "publications" "Publications" "entries"
let skills_section = builtin "skills" "Skills"
let languages_section = extra "languages" "Languages" "list"
let interests_entries = extra "interests" "Interests" "entries"
let interests_tags = extra "interests" "Interests" "tags"
let references_section = extra "references" "References" "entries"
let projects_section = builtin "projects" "Projects"

let work_entry (w : Work.t) =
  {
    blank_entry with
    kind = "experience";
    primary = primary_link ~name:w.name ~url:w.url;
    secondary = nonempty w.position;
    start = date_token w.start_date;
    end_ = date_token w.end_date;
    location = nonempty w.location;
    summary = nonempty w.summary;
    highlights = w.highlights;
  }

let volunteer_entry (v : Volunteer.t) =
  {
    blank_entry with
    primary = primary_link ~name:v.organization ~url:v.url;
    secondary = nonempty v.position;
    start = date_token v.start_date;
    end_ = date_token v.end_date;
    summary = nonempty v.summary;
    highlights = v.highlights;
  }

let education_entry (e : Education.t) =
  {
    blank_entry with
    kind = "education";
    primary = primary_link ~name:e.institution ~url:e.url;
    secondary = education_secondary e;
    start = date_token e.start_date;
    end_ = date_token e.end_date;
    score = Option.map format_score (nonempty e.score);
    tags = e.courses;
  }

let award_entry (a : Award.t) =
  {
    blank_entry with
    primary = primary_link ~name:a.title ~url:None;
    secondary = nonempty a.awarder;
    single_date = date_token a.date;
    summary = nonempty a.summary;
  }

let certificate_entry (c : Certificate.t) =
  {
    blank_entry with
    primary = primary_link ~name:c.name ~url:c.url;
    secondary = nonempty c.issuer;
    single_date = date_token c.date;
  }

let publication_entry (p : Publication.t) =
  {
    blank_entry with
    primary = primary_link ~name:p.name ~url:p.url;
    secondary = nonempty p.publisher;
    single_date = date_token p.release_date;
    summary = nonempty p.summary;
  }

let reference_entry (r : Reference.t) =
  { blank_entry with primary = primary_link ~name:r.name ~url:None; summary = nonempty r.reference }

let project_meta (p : Project.t) =
  let roles =
    match trimmed p.roles with [] -> None | roles -> Some ("Roles", String.concat ", " roles)
  in
  let entity = Option.map (fun e -> ("Affiliation", e)) (nonempty p.entity) in
  let kind = Option.map (fun k -> ("Type", k)) (nonempty p.type_) in
  List.filter_map Fun.id [ roles; entity; kind ]

let project_entry (p : Project.t) =
  {
    blank_entry with
    kind = "project";
    primary = primary_link ~name:p.name ~url:p.url;
    secondary = nonempty p.description;
    start = date_token p.start_date;
    end_ = date_token p.end_date;
    highlights = p.highlights;
    tags = p.keywords;
    meta = project_meta p;
  }

(* ── Emission ───────────────────────────────────────────────────────────── *)

open Html

let emit_value html ~attrs ~href text =
  match href with
  | Some href -> text_el html "a" (attrs @ [ kv "href" href ]) text
  | None -> text_el html "span" attrs text

type contact = {
  c_kind : string;
  c_label : string;
  c_itemprop : string option;
  c_href : string option;
  c_text : string;
}

let contacts (b : Basics.t) =
  let email =
    Option.map
      (fun email ->
        {
          c_kind = "email";
          c_label = "Email";
          c_itemprop = Some "email";
          c_href = Some ("mailto:" ^ email);
          c_text = email;
        })
      (nonempty b.email)
  in
  let phone =
    Option.map
      (fun phone ->
        {
          c_kind = "phone";
          c_label = "Phone";
          c_itemprop = None;
          c_href = Some (tel_href phone);
          c_text = phone;
        })
      (nonempty b.phone)
  in
  let url =
    Option.map
      (fun href ->
        {
          c_kind = "url";
          c_label = "Website";
          c_itemprop = Some "url";
          c_href = Some href;
          c_text = Safe_url.hostname href;
        })
      (Option.bind (nonempty b.url) Safe_url.safe_href)
  in
  let location =
    Option.map
      (fun text ->
        {
          c_kind = "location";
          c_label = "Location";
          c_itemprop = Some "address";
          c_href = None;
          c_text = text;
        })
      (location_text b.location)
  in
  List.filter_map Fun.id [ email; phone; url; location ]

let emit_contact html c =
  open_ html "li" [ kv "class" ("rz-contact rz-contact--" ^ c.c_kind); kv "data-rz-type" c.c_kind ];
  text_el html "span" [ kv "class" "rz-contact-label" ] c.c_label;
  let attrs =
    kv "class" "rz-contact-value" :: Option.to_list (Option.map (kv "itemprop") c.c_itemprop)
  in
  emit_value html ~attrs ~href:c.c_href c.c_text;
  close html "li"

let emit_contacts html basics =
  match contacts basics with
  | [] -> ()
  | rows ->
      open_ html "address" [ kv "class" "rz-contacts" ];
      open_ html "ul" [ kv "class" "rz-contact-list" ];
      List.iter (emit_contact html) rows;
      close html "ul";
      close html "address"

type link = { l_kind : string; l_label : string; l_href : string option; l_text : string }

let profile_link (p : Profile.t) =
  let href = Option.bind (nonempty p.url) Safe_url.safe_href in
  let text =
    match nonempty p.username with Some u -> Some u | None -> Option.map Safe_url.hostname href
  in
  match text with
  | None | Some "" -> None
  | Some text ->
      let network = Option.value (nonempty p.network) ~default:"" in
      let kind = profile_type network in
      let label = if network = "" then kind else network in
      Some { l_kind = kind; l_label = label; l_href = href; l_text = text }

let emit_link html l =
  open_ html "li" [ kv "class" ("rz-link rz-link--" ^ l.l_kind); kv "data-rz-type" l.l_kind ];
  text_el html "span" [ kv "class" "rz-link-label" ] l.l_label;
  emit_value html ~attrs:[ kv "class" "rz-link-value" ] ~href:l.l_href l.l_text;
  close html "li"

let emit_links html profiles =
  match List.filter_map profile_link profiles with
  | [] -> ()
  | rows ->
      open_ html "nav" [ kv "class" "rz-links"; kv "aria-label" "Profiles" ];
      open_ html "ul" [ kv "class" "rz-link-list" ];
      List.iter (emit_link html) rows;
      close html "ul";
      close html "nav"

let emit_header html (basics : Basics.t option) =
  match basics with
  | None -> ()
  | Some b -> (
      match nonempty b.name with
      | None -> ()
      | Some name ->
          open_ html "header" [ kv "class" "rz-header" ];
          open_ html "div" [ kv "class" "rz-identity" ];
          text_el html "h1" [ kv "class" "rz-name"; kv "itemprop" "name" ] name;
          Option.iter
            (fun label ->
              text_el html "p" [ kv "class" "rz-title"; kv "itemprop" "jobTitle" ] label)
            (nonempty b.label);
          close html "div";
          Option.iter
            (fun image ->
              open_ html "figure" [ kv "class" "rz-photo" ];
              void html "img"
                [ kv "class" "rz-photo-img"; kv "src" image; kv "alt" ("Portrait of " ^ name) ];
              close html "figure")
            (nonempty b.image);
          emit_contacts html b;
          emit_links html b.profiles;
          close html "header")

let open_section html section =
  let class_ =
    if section.extra then "rz-section rz-section--extra rz-section--" ^ section.id
    else "rz-section rz-section--" ^ section.id
  in
  let attrs =
    [ kv "class" class_; kv "id" ("rz-" ^ section.id); kv "data-rz-section" section.id ]
    @ Option.to_list (Option.map (kv "data-rz-kind") section.data_kind)
  in
  open_ html "section" attrs;
  text_el html "h2" [ kv "class" "rz-section-title" ] section.title

let emit_prose html class_ text =
  let text = normalize_newlines text in
  open_ html "div" [ kv "class" class_ ];
  Js.String.split ~sep:"\n\n" text |> Array.to_list |> trimmed
  |> List.iter (fun para -> text_el html "p" [] para);
  close html "div"

let emit_summary html (basics : Basics.t option) =
  match Option.bind basics (fun (b : Basics.t) -> nonempty b.summary) with
  | None -> ()
  | Some summary ->
      open_section html summary_section;
      emit_prose html "rz-prose rz-summary" summary;
      close html "section"

let emit_date html class_ token =
  match token.parsed with
  | Some date ->
      text_el html "time"
        [ kv "class" class_; kv "datetime" (Iso_date.datetime date) ]
        (Iso_date.visible date)
  | None -> text_el html "span" [ kv "class" class_ ] token.raw

let emit_dates html e =
  let single date =
    open_ html "p" [ kv "class" "rz-dates" ];
    emit_date html "rz-date" date;
    close html "p"
  in
  match (e.single_date, e.start, e.end_) with
  | Some date, _, _ | None, None, Some date -> single date
  | None, Some start, end_ ->
      open_ html "p" [ kv "class" "rz-dates" ];
      emit_date html "rz-date rz-date--start" start;
      text_el html "span" [ kv "class" "rz-date-sep"; kv "aria-hidden" "true" ] {js|–|js};
      (match end_ with
      | Some end_ -> emit_date html "rz-date rz-date--end" end_
      | None -> text_el html "span" [ kv "class" "rz-date rz-date--end rz-date--present" ] "Present");
      close html "p"
  | None, None, None -> ()

let emit_primary html primary =
  match primary.href with
  | Some href ->
      open_ html "h3" [ kv "class" "rz-entry-primary" ];
      text_el html "a" [ kv "class" "rz-entry-primary-link"; kv "href" href ] primary.text;
      close html "h3"
  | None -> text_el html "h3" [ kv "class" "rz-entry-primary" ] primary.text

let emit_entry_header html e =
  open_ html "div" [ kv "class" "rz-entry-header" ];
  Option.iter (emit_primary html) e.primary;
  Option.iter (text_el html "p" [ kv "class" "rz-entry-secondary" ]) e.secondary;
  emit_dates html e;
  Option.iter (text_el html "p" [ kv "class" "rz-location" ]) e.location;
  Option.iter (text_el html "p" [ kv "class" "rz-score" ]) e.score;
  close html "div"

let emit_meta html meta =
  match meta with
  | [] -> ()
  | meta ->
      open_ html "ul" [ kv "class" "rz-meta-list" ];
      List.iter
        (fun (label, detail) ->
          open_ html "li" [ kv "class" "rz-meta" ];
          text_el html "span" [ kv "class" "rz-meta-label" ] label;
          text_el html "span" [ kv "class" "rz-meta-detail" ] detail;
          close html "li")
        meta;
      close html "ul"

let emit_list html ~list_class ~item_class ~map items =
  match trimmed items with
  | [] -> ()
  | items ->
      open_ html "ul" [ kv "class" list_class ];
      List.iter (fun item -> text_el html "li" [ kv "class" item_class ] (map item)) items;
      close html "ul"

let emit_tags html = emit_list html ~list_class:"rz-tags" ~item_class:"rz-tag" ~map:Fun.id

let emit_bullets html =
  emit_list html ~list_class:"rz-bullets" ~item_class:"rz-bullet" ~map:normalize_newlines

let emit_entry html slugs e =
  let primary_text = Option.fold ~none:"" ~some:(fun p -> p.text) e.primary in
  let slug = Slug.entry_slug slugs ~primary:primary_text ~start_year:(slug_year e) in
  let current = is_current e in
  let class_ = "rz-entry rz-entry--" ^ e.kind ^ if current then " rz-is-current" else "" in
  let attrs =
    [ kv "class" class_; kv "data-rz-entry" slug ]
    @ if current then [ kv "data-rz-current" "true" ] else []
  in
  open_ html "li" attrs;
  if has_header e then emit_entry_header html e;
  Option.iter (emit_prose html "rz-prose") e.summary;
  emit_meta html e.meta;
  emit_tags html e.tags;
  emit_bullets html e.highlights;
  close html "li"

(** Emit a section of entries, skipping entries with nothing to show and the whole section when none
    remain (Invariant 5). *)
let emit_entry_section html slugs section entries =
  match List.filter has_content entries with
  | [] -> ()
  | entries ->
      open_section html section;
      open_ html "ol" [ kv "class" "rz-entries" ];
      List.iter (emit_entry html slugs) entries;
      close html "ol";
      close html "section"

let skill_has_content (s : Skill.t) =
  Option.is_some (nonempty s.name) || Option.is_some (nonempty s.level) || any_nonblank s.keywords

let emit_skill_group html group_slugs (s : Skill.t) =
  let name = nonempty s.name in
  let slug = Slug.skill_slug group_slugs (Option.value name ~default:"") in
  open_ html "li" [ kv "class" "rz-skill-group"; kv "data-rz-skill-group" slug ];
  Option.iter (text_el html "h3" [ kv "class" "rz-skill-group-name" ]) name;
  Option.iter (text_el html "p" [ kv "class" "rz-skill-level" ]) (nonempty s.level);
  emit_list html ~list_class:"rz-skill-list" ~item_class:"rz-skill" ~map:Fun.id s.keywords;
  close html "li"

let emit_skills html skills =
  match List.filter skill_has_content skills with
  | [] -> ()
  | groups ->
      open_section html skills_section;
      open_ html "ul" [ kv "class" "rz-skill-groups" ];
      let group_slugs = Slug.fresh () in
      List.iter (emit_skill_group html group_slugs) groups;
      close html "ul";
      close html "section"

let emit_languages html languages =
  let rows =
    List.filter_map
      (fun (l : Language.t) ->
        Option.map (fun name -> (name, nonempty l.fluency)) (nonempty l.language))
      languages
  in
  match rows with
  | [] -> ()
  | rows ->
      open_section html languages_section;
      open_ html "ul" [ kv "class" "rz-meta-list" ];
      List.iter
        (fun (name, fluency) ->
          open_ html "li" [ kv "class" "rz-meta" ];
          text_el html "span" [ kv "class" "rz-meta-label" ] name;
          Option.iter (text_el html "span" [ kv "class" "rz-meta-detail" ]) fluency;
          close html "li")
        rows;
      close html "ul";
      close html "section"

let emit_interests html slugs interests =
  let items =
    List.filter_map
      (fun (i : Interest.t) -> Option.map (fun name -> (name, i)) (nonempty i.name))
      interests
  in
  match items with
  | [] -> ()
  | items ->
      let as_entries = List.exists (fun (_, (i : Interest.t)) -> any_nonblank i.keywords) items in
      if as_entries then
        items
        |> List.map (fun (name, (i : Interest.t)) ->
            {
              blank_entry with
              primary = primary_link ~name:(Some name) ~url:None;
              tags = i.keywords;
            })
        |> emit_entry_section html slugs interests_entries
      else (
        open_section html interests_tags;
        open_ html "ul" [ kv "class" "rz-tags" ];
        List.iter (fun (name, _) -> text_el html "li" [ kv "class" "rz-tag" ] name) items;
        close html "ul";
        close html "section")

let emit_article html (resume : Resume.t) =
  open_ html "article"
    [
      kv "class" "rz-resume";
      kv "data-rz-schema" contract_version;
      kv "dir" "auto";
      flag "itemscope";
      kv "itemtype" "https://schema.org/Person";
    ];
  let slugs = Slug.fresh () in
  emit_header html resume.basics;
  emit_summary html resume.basics;
  emit_entry_section html slugs experience (List.map work_entry resume.work);
  emit_entry_section html slugs volunteer_section (List.map volunteer_entry resume.volunteer);
  emit_entry_section html slugs education_section (List.map education_entry resume.education);
  emit_entry_section html slugs awards_section (List.map award_entry resume.awards);
  emit_entry_section html slugs certificates_section
    (List.map certificate_entry resume.certificates);
  emit_entry_section html slugs publications_section
    (List.map publication_entry resume.publications);
  emit_skills html resume.skills;
  emit_languages html resume.languages;
  emit_interests html slugs resume.interests;
  emit_entry_section html slugs references_section (List.map reference_entry resume.references);
  emit_entry_section html slugs projects_section (List.map project_entry resume.projects);
  close html "article"

(** The [<article class="rz-resume">] alone, for injection into a sandbox. *)
let render_article resume =
  let html = Html.create () in
  emit_article html resume;
  Html.contents html

(** A complete standalone document. [?style] inlines a Theme as a [<style>] element; without it the
    output is byte-identical to the golden fixtures. *)
let render ?style (resume : Resume.t) =
  let html = Html.create () in
  doctype html;
  open_ html "html" [ kv "lang" "en" ];
  open_ html "head" [];
  void html "meta" [ kv "charset" "utf-8" ];
  void html "meta" [ kv "name" "viewport"; kv "content" "width=device-width, initial-scale=1" ];
  text_el html "title" [] (document_title resume);
  Option.iter
    (fun css ->
      open_ html "style" [];
      Html.raw html (css ^ "\n");
      close html "style")
    style;
  close html "head";
  open_ html "body" [];
  emit_article html resume;
  close html "body";
  close html "html";
  Html.contents html
