(** Lucide-style inline icons. Each call builds a fresh element. *)

val menu : unit -> H.node
(** [menu ()] is the drawer trigger icon. *)

val download : ?size:int -> unit -> H.node
(** [download ?size ()] is the download icon. *)

val upload : ?size:int -> unit -> H.node
(** [upload ?size ()] is the upload icon. *)

val star : unit -> H.node
(** [star ()] is the GitHub star icon. *)

val check : unit -> H.node
(** [check ()] is a passing-check icon. *)

val warn : unit -> H.node
(** [warn ()] is a warning-check icon. *)

val cross : unit -> H.node
(** [cross ()] is a failing-check icon. *)

val clock : unit -> H.node
(** [clock ()] is a pending-check icon. *)
