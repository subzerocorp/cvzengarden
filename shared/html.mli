(** Indented HTML emitter, byte-compatible with the golden documents in [skeleton/]. *)

type attr = Kv of string * string | Flag of string

val kv : string -> string -> attr
val flag : string -> attr

(* An emitter in progress. Abstract: the buffer and depth are only reachable
   through the operations below. *)
type t

val create : unit -> t
val escape_text : Js.String.t -> Js.String.t
val escape_attr : Js.String.t -> Js.String.t
val doctype : t -> unit
val open_ : t -> string -> attr list -> unit
val close : t -> string -> unit
val void : t -> string -> attr list -> unit
val text_el : t -> string -> attr list -> Js.String.t -> unit
val raw : t -> string -> unit
val contents : t -> string
