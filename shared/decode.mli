type error = { path : string; message : string }
type 'a t = path:string -> Js.Json.t -> ('a, error) result

val describe : Js.Json.t -> string
val expected : string -> path:string -> Js.Json.t -> ('a, error) result
val join_field : string -> string -> string
val join_index : string -> int -> string
val string : string t
val number : float t
val string_or_number : string t
val list : 'a t -> 'a list t
val is_null : Js.Json.t -> bool
val field : Js.Dict.key -> 'a t -> path:string -> Js.Json.t Js.Dict.t -> ('a option, error) result

val field_list :
  Js.Dict.key -> 'a t -> path:string -> Js.Json.t Js.Dict.t -> ('a list, error) result

val obj : (path:string -> Js.Json.t Js.Dict.t -> ('a, error) result) -> 'a t
val parse_json : string -> (Js.Json.t, error) result
val error_to_string : error -> string
