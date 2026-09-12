val non_alnum : Js.Re.t
val edge_dashes : Js.Re.t
val slugify : Js.String.t -> Js.String.t

type used = (string, unit) Hashtbl.t

val fresh : unit -> used
val uniquify : used -> string -> string
val slug_or : fallback:Js.String.t -> Js.String.t -> Js.String.t
val entry_slug : used -> primary:Js.String.t -> start_year:int option -> Js.String.t
val skill_slug : used -> Js.String.t -> Js.String.t
