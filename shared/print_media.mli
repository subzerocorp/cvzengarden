type size = Letter | A4 | Legal
type page_box = { size : size; margin : string }

val default_margin : string
val default_page : page_box
val sheet_width : size -> string
val sheet_height : size -> string
val sheet_height_px : size -> int
val lower : Js.String.t -> Js.String.t
val includes : Js.String.t -> Js.String.t -> bool
val matching_close : string -> int -> int

type media_fate = Unwrap | Drop | Keep

val media_fate : Js.String.t -> media_fate
val emulate : Js.String.t -> string
val page_rule : Js.Re.t
val size_decl : Js.Re.t
val margin_decl : Js.Re.t
val capture : Js.Re.t -> string -> Js.String.t option
val size_of_value : Js.String.t -> size option
val page_box : Js.String.t -> page_box
