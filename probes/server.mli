(** The server under probe: a child Bun process on a free port. *)

val token : string
(** [token] is the reviewer token the child process is started with. *)

type subprocess
(** [subprocess] is the child Bun process. *)

type spawn_options = { env : string Js.Dict.t; stdout : string; stderr : string }
(** [spawn_options] is how the child Bun process is started. *)

type t = { port : int; base : string; child : subprocess }
(** [t] is a running probe server. *)

val start : unit -> t Js.Promise.t
(** [start ()] spawns the API on a free port and waits until it answers. *)

val stop : t -> unit
(** [stop t] kills the child process. *)
