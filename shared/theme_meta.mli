type target = Screen | Paper | Both

val target_key : target -> string
val target_of_key : string -> target option
val target_label : target -> string
val target_supports : target -> View_mode.t -> bool

type status = Official | Approved | In_review | Rejected

val status_key : status -> string
val status_of_key : string -> status option
val status_label : status -> string

type fonts = Library | Https_cdn

val fonts_key : fonts -> string
val fonts_of_key : string -> fonts option

type t = {
  id : string;
  name : string;
  author : string;
  author_url : string option;
  target : target;
  fonts : fonts;
  swatches : string * string * string;
  badge : string;
  bg : string;
  status : status;
}

val file : t -> string
val is_public : t -> bool
val is_listed : t -> bool
val officials : t list
val default_id : string
val find_official : string -> t option
val to_json : t -> Js.Json.t
val ( let* ) : ('a, 'b) result -> ('a -> ('c, 'b) result) -> ('c, 'b) result

val required :
  Js.Dict.key -> 'a Decode.t -> path:string -> Js.Json.t Js.Dict.t -> ('a, Decode.error) result

val keyed :
  Js.Dict.key ->
  (string -> 'a option) ->
  path:string ->
  Js.Json.t Js.Dict.t ->
  ('a, Decode.error) result

val decode : t Decode.t
val list_of_json : Js.Json.t -> (t list, Decode.error) result
