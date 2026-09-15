(** A JSON Resume document (jsonresume/resume-schema). Unknown properties are accepted and ignored;
    the original JSON stays the stored form. *)

open Decode

let ( let* ) = Result.bind

module Location = struct
  type t = {
    address : string option;
    postal_code : string option;
    city : string option;
    country_code : string option;
    region : string option;
  }

  let decode : t Decode.t =
    obj (fun ~path o ->
        let* address = field "address" string ~path o in
        let* postal_code = field "postalCode" string ~path o in
        let* city = field "city" string ~path o in
        let* country_code = field "countryCode" string ~path o in
        let* region = field "region" string ~path o in
        Ok { address; postal_code; city; country_code; region })
end

module Profile = struct
  type t = { network : string option; username : string option; url : string option }

  let decode : t Decode.t =
    obj (fun ~path o ->
        let* network = field "network" string ~path o in
        let* username = field "username" string ~path o in
        let* url = field "url" string ~path o in
        Ok { network; username; url })
end

module Basics = struct
  type t = {
    name : string option;
    label : string option;
    image : string option;
    email : string option;
    phone : string option;
    url : string option;
    summary : string option;
    location : Location.t option;
    profiles : Profile.t list;
  }

  let decode : t Decode.t =
    obj (fun ~path o ->
        let* name = field "name" string ~path o in
        let* label = field "label" string ~path o in
        let* image = field "image" string ~path o in
        let* email = field "email" string ~path o in
        let* phone = field "phone" string ~path o in
        let* url = field "url" string ~path o in
        let* summary = field "summary" string ~path o in
        let* location = field "location" Location.decode ~path o in
        let* profiles = field_list "profiles" Profile.decode ~path o in
        Ok { name; label; image; email; phone; url; summary; location; profiles })
end

module Work = struct
  type t = {
    name : string option;
    location : string option;
    description : string option;
    position : string option;
    url : string option;
    start_date : string option;
    end_date : string option;
    summary : string option;
    highlights : string list;
  }

  let decode : t Decode.t =
    obj (fun ~path o ->
        let* name = field "name" string ~path o in
        let* location = field "location" string ~path o in
        let* description = field "description" string ~path o in
        let* position = field "position" string ~path o in
        let* url = field "url" string ~path o in
        let* start_date = field "startDate" string ~path o in
        let* end_date = field "endDate" string ~path o in
        let* summary = field "summary" string ~path o in
        let* highlights = field_list "highlights" string ~path o in
        Ok { name; location; description; position; url; start_date; end_date; summary; highlights })
end

module Volunteer = struct
  type t = {
    organization : string option;
    position : string option;
    url : string option;
    start_date : string option;
    end_date : string option;
    summary : string option;
    highlights : string list;
  }

  let decode : t Decode.t =
    obj (fun ~path o ->
        let* organization = field "organization" string ~path o in
        let* position = field "position" string ~path o in
        let* url = field "url" string ~path o in
        let* start_date = field "startDate" string ~path o in
        let* end_date = field "endDate" string ~path o in
        let* summary = field "summary" string ~path o in
        let* highlights = field_list "highlights" string ~path o in
        Ok { organization; position; url; start_date; end_date; summary; highlights })
end

module Education = struct
  type t = {
    institution : string option;
    url : string option;
    area : string option;
    study_type : string option;
    start_date : string option;
    end_date : string option;
    score : string option;
    courses : string list;
  }

  let decode : t Decode.t =
    obj (fun ~path o ->
        let* institution = field "institution" string ~path o in
        let* url = field "url" string ~path o in
        let* area = field "area" string ~path o in
        let* study_type = field "studyType" string ~path o in
        let* start_date = field "startDate" string ~path o in
        let* end_date = field "endDate" string ~path o in
        let* score = field "score" string_or_number ~path o in
        let* courses = field_list "courses" string ~path o in
        Ok { institution; url; area; study_type; start_date; end_date; score; courses })
end

module Award = struct
  type t = {
    title : string option;
    date : string option;
    awarder : string option;
    summary : string option;
  }

  let decode : t Decode.t =
    obj (fun ~path o ->
        let* title = field "title" string ~path o in
        let* date = field "date" string ~path o in
        let* awarder = field "awarder" string ~path o in
        let* summary = field "summary" string ~path o in
        Ok { title; date; awarder; summary })
end

module Certificate = struct
  type t = {
    name : string option;
    date : string option;
    url : string option;
    issuer : string option;
  }

  let decode : t Decode.t =
    obj (fun ~path o ->
        let* name = field "name" string ~path o in
        let* date = field "date" string ~path o in
        let* url = field "url" string ~path o in
        let* issuer = field "issuer" string ~path o in
        Ok { name; date; url; issuer })
end

module Publication = struct
  type t = {
    name : string option;
    publisher : string option;
    release_date : string option;
    url : string option;
    summary : string option;
  }

  let decode : t Decode.t =
    obj (fun ~path o ->
        let* name = field "name" string ~path o in
        let* publisher = field "publisher" string ~path o in
        let* release_date = field "releaseDate" string ~path o in
        let* url = field "url" string ~path o in
        let* summary = field "summary" string ~path o in
        Ok { name; publisher; release_date; url; summary })
end

module Skill = struct
  type t = { name : string option; level : string option; keywords : string list }

  let decode : t Decode.t =
    obj (fun ~path o ->
        let* name = field "name" string ~path o in
        let* level = field "level" string ~path o in
        let* keywords = field_list "keywords" string ~path o in
        Ok { name; level; keywords })
end

module Language = struct
  type t = { language : string option; fluency : string option }

  let decode : t Decode.t =
    obj (fun ~path o ->
        let* language = field "language" string ~path o in
        let* fluency = field "fluency" string ~path o in
        Ok { language; fluency })
end

module Interest = struct
  type t = { name : string option; keywords : string list }

  let decode : t Decode.t =
    obj (fun ~path o ->
        let* name = field "name" string ~path o in
        let* keywords = field_list "keywords" string ~path o in
        Ok { name; keywords })
end

module Reference = struct
  type t = { name : string option; reference : string option }

  let decode : t Decode.t =
    obj (fun ~path o ->
        let* name = field "name" string ~path o in
        let* reference = field "reference" string ~path o in
        Ok { name; reference })
end

module Project = struct
  type t = {
    name : string option;
    description : string option;
    highlights : string list;
    keywords : string list;
    start_date : string option;
    end_date : string option;
    url : string option;
    roles : string list;
    entity : string option;
    type_ : string option;
  }

  let decode : t Decode.t =
    obj (fun ~path o ->
        let* name = field "name" string ~path o in
        let* description = field "description" string ~path o in
        let* highlights = field_list "highlights" string ~path o in
        let* keywords = field_list "keywords" string ~path o in
        let* start_date = field "startDate" string ~path o in
        let* end_date = field "endDate" string ~path o in
        let* url = field "url" string ~path o in
        let* roles = field_list "roles" string ~path o in
        let* entity = field "entity" string ~path o in
        let* type_ = field "type" string ~path o in
        Ok
          {
            name;
            description;
            highlights;
            keywords;
            start_date;
            end_date;
            url;
            roles;
            entity;
            type_;
          })
end

type t = {
  basics : Basics.t option;
  work : Work.t list;
  volunteer : Volunteer.t list;
  education : Education.t list;
  awards : Award.t list;
  certificates : Certificate.t list;
  publications : Publication.t list;
  skills : Skill.t list;
  languages : Language.t list;
  interests : Interest.t list;
  references : Reference.t list;
  projects : Project.t list;
}

let decode : t Decode.t =
  obj (fun ~path o ->
      let* basics = field "basics" Basics.decode ~path o in
      let* work = field_list "work" Work.decode ~path o in
      let* volunteer = field_list "volunteer" Volunteer.decode ~path o in
      let* education = field_list "education" Education.decode ~path o in
      let* awards = field_list "awards" Award.decode ~path o in
      let* certificates = field_list "certificates" Certificate.decode ~path o in
      let* publications = field_list "publications" Publication.decode ~path o in
      let* skills = field_list "skills" Skill.decode ~path o in
      let* languages = field_list "languages" Language.decode ~path o in
      let* interests = field_list "interests" Interest.decode ~path o in
      let* references = field_list "references" Reference.decode ~path o in
      let* projects = field_list "projects" Project.decode ~path o in
      Ok
        {
          basics;
          work;
          volunteer;
          education;
          awards;
          certificates;
          publications;
          skills;
          languages;
          interests;
          references;
          projects;
        })

let of_json json = decode ~path:"" json

(** Parse JSON text and decode it. The error carries a JSON path when the shape is wrong and an
    empty path when the text is not JSON at all. *)
let of_string text =
  let* json = Decode.parse_json text in
  of_json json

(** Section sizes for the Studio's summary tags, in contract order. *)
let section_counts t =
  List.filter
    (fun (_, n) -> n > 0)
    [
      ("work", List.length t.work);
      ("volunteer", List.length t.volunteer);
      ("education", List.length t.education);
      ("awards", List.length t.awards);
      ("certificates", List.length t.certificates);
      ("publications", List.length t.publications);
      ("skills", List.length t.skills);
      ("languages", List.length t.languages);
      ("interests", List.length t.interests);
      ("references", List.length t.references);
      ("projects", List.length t.projects);
    ]
