(** Binding operators over [Js.Promise], so async Actions read top to bottom. *)

val ( let> ) : 'a Js.Promise.t -> ('a -> 'b Js.Promise.t) -> 'b Js.Promise.t
(** [let> x = p in f x] is [Js.Promise.then_ f p]. *)

val return : 'a -> 'a Js.Promise.t
(** [return x] is a resolved promise of [x]. *)

val flatten : 'a -> 'a Js.Promise.t
(** [flatten x] wraps a value that may already be a promise. *)

val map : ('a -> 'b) -> 'a Js.Promise.t -> 'b Js.Promise.t
(** [map f p] applies [f] to the resolved value of [p]. *)

val sequence : (unit -> unit Js.Promise.t) list -> unit Js.Promise.t
(** [sequence actions] runs [actions] in order. *)
