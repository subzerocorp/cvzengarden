val ( let* ) : ('a, 'b) result -> ('a -> ('c, 'b) result) -> ('c, 'b) result

module Location : sig
  type t = {
    address : string option;
    postal_code : string option;
    city : string option;
    country_code : string option;
    region : string option;
  }

  val decode : t Decode.t
end

module Profile : sig
  type t = { network : string option; username : string option; url : string option }

  val decode : t Decode.t
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

  val decode : t Decode.t
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

  val decode : t Decode.t
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

  val decode : t Decode.t
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

  val decode : t Decode.t
end

module Award : sig
  type t = {
    title : string option;
    date : string option;
    awarder : string option;
    summary : string option;
  }

  val decode : t Decode.t
end

module Certificate : sig
  type t = {
    name : string option;
    date : string option;
    url : string option;
    issuer : string option;
  }

  val decode : t Decode.t
end

module Publication : sig
  type t = {
    name : string option;
    publisher : string option;
    release_date : string option;
    url : string option;
    summary : string option;
  }

  val decode : t Decode.t
end

module Skill : sig
  type t = { name : string option; level : string option; keywords : string list }

  val decode : t Decode.t
end

module Language : sig
  type t = { language : string option; fluency : string option }

  val decode : t Decode.t
end

module Interest : sig
  type t = { name : string option; keywords : string list }

  val decode : t Decode.t
end

module Reference : sig
  type t = { name : string option; reference : string option }

  val decode : t Decode.t
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

  val decode : t Decode.t
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

val decode : t Decode.t
val of_json : Js.Json.t -> (t, Decode.error) result
val of_string : string -> (t, Decode.error) result
val section_counts : t -> (string * int) list
