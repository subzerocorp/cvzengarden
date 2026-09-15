(** The libSQL client: one API for a local SQLite file, [:memory:], and Turso. *)

type client
(** [client] is an open store. *)

type result
(** [result] is a statement outcome. *)

type row = Js.Json.t Js.Dict.t
(** [row] is one result row. *)

type statement = { sql : string; args : Js.Json.t array }
(** [statement] is a parameterised SQL string. *)

val connect : url:string -> ?auth_token:string -> unit -> client
(** [connect ~url ?auth_token ()] opens the store at [url]. *)

val execute_multiple : client -> string -> unit Js.Promise.t
(** [execute_multiple c sql] runs multiple statements. *)

val query : client -> string -> Js.Json.t array -> row array Js.Promise.t
(** [query c sql args] runs [sql] and returns rows. *)

val run : client -> string -> Js.Json.t array -> int Js.Promise.t
(** [run c sql args] runs [sql] and returns rows-affected. *)

val text : row -> string -> string option
(** [text row key] is the string column [key]. *)

val int : row -> string -> int option
(** [int row key] is the integer column [key]. *)

val s : string -> Js.Json.t
(** [s v] is a string query argument. *)

val opt : string option -> Js.Json.t
(** [opt v] is a string argument, or JSON null. *)
