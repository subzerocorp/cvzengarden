(** The Bun runtime surface the server needs: files, env, serve. *)

type file
(** [file] is a Bun file handle. *)

val file : string -> file
(** [file path] is a handle on [path]. *)

val exists : file -> bool Js.Promise.t
(** [exists f] is whether [f] is on disk. *)

val text : file -> string Js.Promise.t
(** [text f] is the UTF-8 contents of [f]. *)

val env : string Js.Dict.t
(** [env] is [process.env]. *)

val cwd : unit -> string
(** [cwd ()] is the process working directory. *)

val log : string -> unit
(** [log msg] writes [msg] to stdout. *)

val error : string -> unit
(** [error msg] writes [msg] to stderr. *)

val exit : int -> unit
(** [exit code] ends the process. *)

type request
(** [request] is an HTTP request. *)

type response
(** [response] is an HTTP response. *)

type fetch_fn
(** [fetch_fn] is a bound [(request) => Promise<Response>], e.g. Hono's [app.fetch]. *)

type serve_options = { port : int; hostname : string; fetch : fetch_fn }
(** [serve_options] is what [Bun.serve] takes. *)

type server
(** [server] is a running Bun HTTP server. *)

val serve : serve_options -> server
(** [serve opts] starts the HTTP server. *)

val server_port : server -> int
(** [server_port s] is the bound port. *)

val env_or : string -> string -> string
(** [env_or key default] is [env]'s [key], or [default]. *)

val read_text : string -> string option Js.Promise.t
(** [read_text path] is the file contents, or [None] when it is missing. *)
