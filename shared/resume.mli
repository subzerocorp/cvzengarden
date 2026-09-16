(** A JSON Resume document. *)

module Location : sig
  type t = {
    address : string option;
    postal_code : string option;
    city : string option;
    country_code : string option;
    region : string option;
  }
  (** [t] is [basics.location]. *)
end

module Profile : sig
  type t = { network : string option; username : string option; url : string option }
  (** [t] is one [basics.profiles] entry. *)
end

module Basics : sig
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
  (** [t] is [basics]. *)
end

module Work : sig
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
  (** [t] is one [work] entry. *)
end

module Volunteer : sig
  type t = {
    organization : string option;
    position : string option;
    url : string option;
    start_date : string option;
    end_date : string option;
    summary : string option;
    highlights : string list;
  }
  (** [t] is one [volunteer] entry. *)
end

module Education : sig
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
  (** [t] is one [education] entry. *)
end

module Award : sig
  type t = {
    title : string option;
    date : string option;
    awarder : string option;
    summary : string option;
  }
  (** [t] is one [awards] entry. *)
end

module Certificate : sig
  type t = {
    name : string option;
    date : string option;
    url : string option;
    issuer : string option;
  }
  (** [t] is one [certificates] entry. *)
end

module Publication : sig
  type t = {
    name : string option;
    publisher : string option;
    release_date : string option;
    url : string option;
    summary : string option;
  }
  (** [t] is one [publications] entry. *)
end

module Skill : sig
  type t = { name : string option; level : string option; keywords : string list }
  (** [t] is one [skills] entry. *)
end

module Language : sig
  type t = { language : string option; fluency : string option }
  (** [t] is one [languages] entry. *)
end

module Interest : sig
  type t = { name : string option; keywords : string list }
  (** [t] is one [interests] entry. *)
end

module Reference : sig
  type t = { name : string option; reference : string option }
  (** [t] is one [references] entry. *)
end

module Project : sig
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
  (** [t] is one [projects] entry. *)
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
(** [t] is a JSON Resume document. *)

val decode : t Decode.t
(** [decode] reads a Resume object. *)

val of_json : Js.Json.t -> (t, Decode.error) result
(** [of_json json] is a Resume, or a path-tagged error. *)

val of_string : string -> (t, Decode.error) result
(** [of_string text] parses JSON and decodes a Resume. *)

val section_counts : t -> (string * int) list
(** [section_counts r] is the non-empty section names with their entry counts. *)
