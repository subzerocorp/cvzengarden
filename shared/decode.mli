(** JSON decoding combinators with JSON-path errors. *)

type error = { path : string; message : string }
(** [error] is a failure at [path] with a human [message]. *)

type 'a t = path:string -> Js.Json.t -> ('a, error) result
(** ['a t] is a decoder of a JSON value at a path. *)

val string : string t
(** [string] decodes a JSON string. *)

val number : float t
(** [number] decodes a JSON number. *)

val string_or_number : string t
(** [string_or_number] decodes a string, or a number as its decimal text. *)

val list : 'a t -> 'a list t
(** [list item] decodes a JSON array with [item] at each index. *)

val field : Js.Dict.key -> 'a t -> path:string -> Js.Json.t Js.Dict.t -> ('a option, error) result
(** [field name dec ~path obj] is [None] when [name] is missing or null, otherwise [dec]. *)

val field_list :
  Js.Dict.key -> 'a t -> path:string -> Js.Json.t Js.Dict.t -> ('a list, error) result
(** [field_list name dec ~path obj] is [[]] when [name] is missing or null, otherwise a list. *)

val obj : (path:string -> Js.Json.t Js.Dict.t -> ('a, error) result) -> 'a t
(** [obj f] decodes a JSON object by handing its dictionary to [f]. *)

val required : Js.Dict.key -> 'a t -> path:string -> Js.Json.t Js.Dict.t -> ('a, error) result
(** [required name dec ~path obj] is [dec] of [name], or an error when it is missing. *)

val keyed :
  Js.Dict.key -> (string -> 'a option) -> path:string -> Js.Json.t Js.Dict.t -> ('a, error) result
(** [keyed name of_key ~path obj] decodes a string field and maps it through [of_key]. *)

val parse_json : string -> (Js.Json.t, error) result
(** [parse_json text] is the JSON value, or a parse error with an empty path. *)

val error_to_string : error -> string
(** [error_to_string e] is [path: message], or just [message] when the path is empty. *)
