(** Contract checks on a Theme stylesheet. *)

type status = Pass | Warn | Fail | Pending  (** [status] is the outcome of one check. *)

type check = { id : string; title : string; note : string; status : status }
(** [check] is one named contract result. *)

val strip_comments : Js.String.t -> Js.String.t
(** [strip_comments css] is [css] with [/* … */] comments removed. *)

val declared_target : string -> string option
(** [declared_target css] is the [rz-target] header value, if present. *)

val run : Js.String.t -> check list
(** [run css] is the six text checks on [css]. *)

val with_pages : int -> check list -> check list
(** [with_pages n checks] replaces the pending page-count check with a measured [n]. *)

val passing : check list -> int
(** [passing checks] is how many checks are [Pass]. *)

val blocking : check list -> bool
(** [blocking checks] is [true] when any check is [Fail]. *)

val to_json : check -> Js.Json.t
(** [to_json c] is the wire object for one check. *)

val list_to_json : check list -> Js.Json.t
(** [list_to_json checks] is a JSON array of checks. *)

val decode : check Decode.t
(** [decode] reads a check from a wire object. *)
