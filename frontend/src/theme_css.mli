(** Theme stylesheets, fetched once and shared by every preview frame. *)

val get : string -> string option
(** [get id] is the cached stylesheet, or [None] until it arrives. *)

val forget : string -> unit
(** [forget id] drops a cached stylesheet. *)
