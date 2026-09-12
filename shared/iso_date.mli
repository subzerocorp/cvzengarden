type t = { year : int; month : int option; day : int option }

val month_names : string array
val month_name : int -> string option
val datetime : t -> string
val visible : t -> string
val is_leap_year : int -> bool
val days_in_month : int -> int -> int
val is_calendar_valid : t -> bool
val digits : int -> string -> int option
val time_tail : Js.Re.t
val date_part : Js.String.t -> Js.String.t
val ( let** ) : 'a option -> ('a -> 'b option) -> 'b option
val parse : Js.String.t -> t option
