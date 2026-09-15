(** First-party Theme rows and optional review-queue examples. *)

val run : demo:bool -> Db.t -> unit Js.Promise.t
(** [run ~demo db] seeds officials, and demo submissions when [demo] is set. *)
