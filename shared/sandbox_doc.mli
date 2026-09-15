(** Documents served inside the preview iframe, and standalone printable previews. *)

val style_id_base : string
(** [style_id_base] is the sandbox overlay style element id. *)

val style_id_theme : string
(** [style_id_theme] is the Theme stylesheet style element id. *)

val style_id_paper : string
(** [style_id_paper] is the paper-box style element id. *)

val absolute_font_urls : Js.String.t -> Js.String.t
(** [absolute_font_urls css] rewrites relative [url()] font paths to origin-absolute ones. *)

val page_style : Print_media.page_box -> string
(** [page_style box] is the chrome CSS that draws [box] on html/body. *)

val frame :
  base_css:Js.String.t ->
  paper_css:Js.String.t ->
  theme_css:Js.String.t ->
  view:View_mode.t ->
  article:Js.String.t ->
  string
(** [frame ~base_css ~paper_css ~theme_css ~view ~article] is the srcdoc for a sandboxed preview. *)

val standalone : theme_css:Js.String.t -> Resume.t -> string
(** [standalone ~theme_css resume] is a printable HTML document of [resume] in one Theme. *)
