(** Honest paper view: unwrap a Theme's [@media print], drop [@media screen], read [@page]. *)

type size = Letter | A4 | Legal  (** [size] is a named sheet size. *)

type page_box = { size : size; margin : string }
(** [page_box] is the Theme's [@page] size and margin. *)

val sheet_width : size -> string
(** [sheet_width s] is the CSS width of [s]. *)

val sheet_height : size -> string
(** [sheet_height s] is the CSS height of [s]. *)

val sheet_height_px : size -> int
(** [sheet_height_px s] is the pixel height used to estimate page count. *)

val emulate : Js.String.t -> string
(** [emulate css] is [css] with print media unwrapped and screen media dropped. *)

val page_box : Js.String.t -> page_box
(** [page_box css] is the Theme's [@page] box, or [default_page]. *)
