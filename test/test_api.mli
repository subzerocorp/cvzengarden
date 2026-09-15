(** Tests for the HTTP surface. *)

val run : unit -> unit Js.Promise.t
(** [run ()] exercises Hono routes against an in-memory store. *)
