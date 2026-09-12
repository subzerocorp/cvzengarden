type t = Screen | Paper

val to_key : t -> string
val of_key : string -> t option
val label : t -> string
val toggle : t -> t
