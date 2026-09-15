(** The libSQL client ([@libsql/client] on npm): one API for a local SQLite file, [:memory:], and
    Turso. *)

type client
type result
type row = Js.Json.t Js.Dict.t

external create_client : string Js.Dict.t -> client = "createClient" [@@mel.module "@libsql/client"]

type statement = { sql : string; args : Js.Json.t array }

external execute : client -> statement -> result Js.Promise.t = "execute" [@@mel.send]
external execute_multiple : client -> string -> unit Js.Promise.t = "executeMultiple" [@@mel.send]
external rows : result -> row array = "rows" [@@mel.get]
external rows_affected : result -> int = "rowsAffected" [@@mel.get]

let connect ~url ?auth_token () =
  let config = Js.Dict.empty () in
  Js.Dict.set config "url" url;
  Option.iter (Js.Dict.set config "authToken") auth_token;
  create_client config

let query client sql args = Promise.map rows (execute client { sql; args })
let run client sql args = Promise.map rows_affected (execute client { sql; args })

(* ── Row readers ─────────────────────────────────────────────────────── *)

let text row key = Option.bind (Js.Dict.get row key) Js.Json.decodeString

let int row key =
  Option.bind (Js.Dict.get row key) (fun v ->
      match Js.Json.classify v with
      | JSONNumber n -> Some (int_of_float n)
      | JSONString s -> int_of_string_opt s
      | _ -> None)

(* ── Argument builders ───────────────────────────────────────────────── *)

let s = Js.Json.string
let opt = function Some v -> Js.Json.string v | None -> Js.Json.null
