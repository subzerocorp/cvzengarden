(** Indented HTML emitter, byte-compatible with the golden documents in [skeleton/]. *)

type attr =
  | Kv of string * string
  | Flag of string  (** [attr] is a HTML attribute, either [key="value"] or a boolean flag. *)

val kv : string -> string -> attr
(** [kv key value] is a [key="value"] attribute. *)

val flag : string -> attr
(** [flag key] is a boolean attribute with no value. *)

type t
(** [t] is an emitter in progress. The buffer and depth are only reachable through the operations
    below. *)

val create : unit -> t
(** [create ()] is a fresh emitter. *)

val doctype : t -> unit
(** [doctype t] writes the HTML5 doctype. *)

val open_ : t -> string -> attr list -> unit
(** [open_ t tag attrs] writes an opening tag and indents one level. *)

val close : t -> string -> unit
(** [close t tag] outdents and writes a closing tag. *)

val void : t -> string -> attr list -> unit
(** [void t tag attrs] writes a void element. *)

val text_el : t -> string -> attr list -> Js.String.t -> unit
(** [text_el t tag attrs text] writes an element whose body is escaped text. *)

val raw : t -> string -> unit
(** [raw t markup] inserts pre-rendered markup at the current depth. *)

val contents : t -> string
(** [contents t] is the emitted document. *)
