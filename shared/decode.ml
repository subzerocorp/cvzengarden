(** Small JSON decoding combinators with positioned errors, so a Studio user sees
    [work[0].highlights[2]: expected a string, found a number]. *)

type error = { path : string; message : string }
type 'a t = path:string -> Js.Json.t -> ('a, error) result

let describe json =
  match Js.Json.classify json with
  | JSONString _ -> "a string"
  | JSONNumber _ -> "a number"
  | JSONObject _ -> "an object"
  | JSONArray _ -> "an array"
  | JSONTrue | JSONFalse -> "a boolean"
  | JSONNull -> "null"

let expected what ~path json =
  Error { path; message = Printf.sprintf "expected %s, found %s" what (describe json) }

let join_field path name = if path = "" then name else path ^ "." ^ name
let join_index path i = Printf.sprintf "%s[%d]" path i

let string : string t =
 fun ~path json ->
  match Js.Json.decodeString json with Some s -> Ok s | None -> expected "a string" ~path json

(** [score] arrives as ["3.7"], [3.7], or [4] in the wild; always text here. *)
let string_or_number : string t =
 fun ~path json ->
  match Js.Json.classify json with
  | JSONString s -> Ok s
  | JSONNumber n -> Ok (Js.Float.toString n)
  | _ -> expected "a string or number" ~path json

let list (item : 'a t) : 'a list t =
 fun ~path json ->
  match Js.Json.decodeArray json with
  | None -> expected "an array" ~path json
  | Some items ->
      let rec go i acc = function
        | [] -> Ok (List.rev acc)
        | x :: rest -> (
            match item ~path:(join_index path i) x with
            | Ok v -> go (i + 1) (v :: acc) rest
            | Error e -> Error e)
      in
      go 0 [] (Array.to_list items)

let is_null json = match Js.Json.classify json with JSONNull -> true | _ -> false

(** A missing or [null] field is [None]; a present field must decode. *)
let field name (dec : 'a t) ~path (obj : Js.Json.t Js.Dict.t) : ('a option, error) result =
  match Js.Dict.get obj name with
  | None -> Ok None
  | Some v when is_null v -> Ok None
  | Some v -> Result.map Option.some (dec ~path:(join_field path name) v)

let field_list name (dec : 'a t) ~path obj =
  Result.map (Option.value ~default:[]) (field name (list dec) ~path obj)

let obj (f : path:string -> Js.Json.t Js.Dict.t -> ('a, error) result) : 'a t =
 fun ~path json ->
  match Js.Json.decodeObject json with
  | Some o -> f ~path o
  | None -> expected "an object" ~path json

let parse_json text =
  match Js.Json.parseExn text with
  | json -> Ok json
  | exception Js.Exn.Error e ->
      Error { path = ""; message = Option.value (Js.Exn.message e) ~default:"Invalid JSON" }

let error_to_string { path; message } = if path = "" then message else path ^ ": " ^ message
