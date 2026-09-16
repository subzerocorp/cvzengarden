(** Probe bookkeeping: named expectations, a failure count, an exit code. *)

val expecting_404 : bool ref
(** [expecting_404] is set while a probe fetches a URL that must 404. *)

val fail : string -> string -> unit
(** [fail name detail] records a failure. *)

val pass : string -> unit
(** [pass name] records a pass. *)

val expect : string -> bool -> string -> unit
(** [expect name cond detail] passes when [cond] is true. *)

val equal_int : string -> int -> int -> unit
(** [equal_int name expected actual] compares integers. *)

val equal_string : string -> string -> string -> unit
(** [equal_string name expected actual] compares strings. *)

val contains : string -> string -> string -> unit
(** [contains name needle haystack] checks inclusion. *)

val suite : string -> unit
(** [suite name] prints a suite heading. *)

val finish : unit -> unit
(** [finish ()] prints totals and exits. *)
