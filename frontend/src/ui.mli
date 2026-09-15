(** Shared chrome pieces: pills, the view toggle, the sheet shell. *)

open Rz_shared

val on_click : (unit -> unit) -> string * H.prop
(** [on_click f] is an [onClick] handler that ignores the event. *)

val data_on : (unit -> bool) -> string * H.prop
(** [data_on getter] is a reactive [data-on] attribute. *)

val link : ?class_:string -> Route.page -> H.node list -> H.node
(** [link ?class_ page children] is an in-app link to [page]. *)

val conic : string * string * string -> string
(** [conic swatches] is a conic-gradient background for ground, ink, accent. *)

type swatch = Dot | Disc | No_swatch  (** [swatch] is how a Theme pill shows colour. *)

val theme_pill :
  ?swatch:swatch -> ?extra:(string * H.prop) list -> ?small:bool -> Theme_meta.t -> H.node
(** [theme_pill ?swatch ?extra ?small t] is a Theme picker pill. *)

val theme_pills : ?swatch:swatch -> ?small:bool -> ?with_target:bool -> unit -> H.node
(** [theme_pills ?swatch ?small ?with_target ()] is a pill row of public Themes. *)

val view_seg : ?small:bool -> unit -> H.node
(** [view_seg ?small ()] is the Screen / Paper toggle. *)

val pages_label : unit -> H.node
(** [pages_label ()] is the page-count caption. *)

val pdf_button : ?icon:bool -> unit -> H.node
(** [pdf_button ?icon ()] is the Save as PDF control. *)

val sheet_style : unit -> string
(** [sheet_style ()] is the CSS custom properties for the preview sheet. *)

val primary_sheet : class_:string -> H.node
(** [primary_sheet ~class_] is the main preview of the staged Theme. *)

val tag : ?kind:string -> string -> H.node
(** [tag ?kind label] is a status chip. *)
