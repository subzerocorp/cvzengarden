(** SolidJS reactive primitives. *)

type 'a signal = (unit -> 'a) * ('a -> unit)
(** ['a signal] is a getter and setter pair. *)

val create_signal : 'a -> 'a signal
(** [create_signal v] is a signal holding [v]. *)

val create_effect : (unit -> unit) -> unit
(** [create_effect f] runs [f] when its dependencies change. *)

val create_memo : (unit -> 'a) -> unit -> 'a
(** [create_memo f] is a memoized getter. *)

val on_cleanup : (unit -> unit) -> unit
(** [on_cleanup f] runs [f] when the owner is disposed. *)

val on_mount : (unit -> unit) -> unit
(** [on_mount f] runs [f] after mount. *)

val batch : (unit -> 'a) -> 'a
(** [batch f] applies signal writes in [f] as one update. *)

val untrack : (unit -> 'a) -> 'a
(** [untrack f] reads signals in [f] without subscribing. *)

val create_root : ((unit -> unit) -> 'a) -> 'a
(** [create_root f] runs [f] under a new reactive root. *)

val global_memo : (unit -> 'a) -> unit -> 'a
(** [global_memo f] is a page-lifetime memo. *)

val signal : 'a -> 'a signal
(** [signal v] is [create_signal v] for data values, never closures. *)
