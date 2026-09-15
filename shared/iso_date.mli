(** JSON Resume ISO-8601 dates: [YYYY], [YYYY-MM], [YYYY-MM-DD]. *)

type t = { year : int; month : int option; day : int option }
(** [t] is a calendar date with optional month and day. *)

val datetime : t -> string
(** [datetime d] is the machine [datetime] value ([YYYY], [YYYY-MM], or [YYYY-MM-DD]). *)

val visible : t -> string
(** [visible d] is the human date ([2020], [March 2020], or [January 15, 2022]). *)

val parse : Js.String.t -> t option
(** [parse raw] is the date when [raw] is a valid ISO-8601 resume date. *)
