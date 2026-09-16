(** A tiny assertion harness: named cases, counted failures, non-zero exit. *)

val read : string -> string
(** [read path] is the UTF-8 contents of [path]. *)

val fail : string -> string -> unit
(** [fail name detail] records a failure. *)

val equal : ?show:('a -> string) -> string -> 'a -> 'a -> unit
(** [equal ?show name expected actual] compares values. *)

val string : string -> string -> string -> unit
(** [string name expected actual] compares strings. *)

val int : string -> int -> int -> unit
(** [int name expected actual] compares integers. *)

val bool : string -> bool -> bool -> unit
(** [bool name expected actual] compares booleans. *)

val string_option : string -> string option -> string option -> unit
(** [string_option name expected actual] compares optional strings. *)

val is_true : string -> bool -> unit
(** [is_true name cond] passes when [cond] is true. *)

val is_false : string -> bool -> unit
(** [is_false name cond] passes when [cond] is false. *)

val document : string -> string -> string -> unit
(** [document name expected actual] compares whole documents with a line diff. *)

val suite : string -> (unit -> unit) -> unit
(** [suite name run] prints [name] and runs [run]. *)

val report : unit -> unit
(** [report ()] prints totals and exits non-zero on failure. *)
