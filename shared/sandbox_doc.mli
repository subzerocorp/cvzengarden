val style_id_base : string
val style_id_theme : string
val style_id_paper : string
val inert_css : Js.String.t -> Js.String.t
val font_urls_re : Js.Re.t
val absolute_font_urls : Js.String.t -> Js.String.t
val view_attr : View_mode.t -> string
val page_style : Print_media.page_box -> string

val frame :
  base_css:Js.String.t ->
  paper_css:Js.String.t ->
  theme_css:Js.String.t ->
  view:View_mode.t ->
  article:Js.String.t ->
  string

val standalone : theme_css:Js.String.t -> Resume.t -> string
