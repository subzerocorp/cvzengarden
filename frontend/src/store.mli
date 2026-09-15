(** Global chrome state: signals, navigation and persistence. *)

open Rz_shared

val page : unit -> Route.page
(** [page ()] is the current route. *)

val theme_id : unit -> string
(** [theme_id ()] is the staged Theme id. *)

val view : unit -> View_mode.t
(** [view ()] is the current render view. *)

val menu_open : unit -> bool
(** [menu_open ()] is whether the drawer is open. *)

val resume_text : unit -> string
(** [resume_text ()] is the Author's pasted JSON Resume text. *)

val set_resume_text : string -> unit
(** [set_resume_text text] stores the Author's JSON Resume text. *)

val pages : unit -> int
(** [pages ()] is the estimated Letter page count. *)

val set_pages : int -> unit
(** [set_pages n] records the measured page count. *)

val custom_css : unit -> string option
(** [custom_css ()] is the Workbench stylesheet under test. *)

val set_custom_css : string option -> unit
(** [set_custom_css css] sets the Workbench stylesheet. *)

val admin_token : unit -> string
(** [admin_token ()] is the reviewer token remembered in this browser. *)

val set_print_target : Web.window option -> unit
(** [set_print_target w] registers the window "Save as PDF" should print. *)

val sample_long : unit -> string
(** [sample_long ()] is the Jordan Hale fixture text. *)

val sample_junior : unit -> string
(** [sample_junior ()] is the junior fixture text. *)

val public_themes : unit -> Theme_meta.t list
(** [public_themes ()] is first-party and approved Themes. *)

val queue : unit -> Theme_meta.t list
(** [queue ()] is Submissions in review. *)

val community : unit -> Theme_meta.t list
(** [community ()] is every Theme that is not first-party. *)

val selected_theme : unit -> Theme_meta.t option
(** [selected_theme ()] is the staged Theme card. *)

val resume_source : unit -> string
(** [resume_source ()] is the Author's text, or the sample when empty. *)

val resume : unit -> (Resume.t, Decode.error) result
(** [resume ()] is the decoded Author résumé. *)

val article : unit -> string
(** [article ()] is the last valid Skeleton HTML. *)

val long_article : unit -> string
(** [long_article ()] is the Skeleton for the long fixture. *)

val is_paper : unit -> bool
(** [is_paper ()] is [true] in Paper view. *)

val pages_label : unit -> string
(** [pages_label ()] is the chrome page-count label. *)

val navigate : Route.page -> unit
(** [navigate p] switches the route and updates the URL. *)

val pick_theme : string -> unit
(** [pick_theme id] stages [id] without a history push. *)

val choose_view : View_mode.t -> unit
(** [choose_view v] sets the render view. *)

val toggle_menu : unit -> unit
(** [toggle_menu ()] opens or closes the drawer. *)

val print_sheet : unit -> unit
(** [print_sheet ()] prints the registered preview window. *)

val copy_link : unit -> unit
(** [copy_link ()] copies the current URL. *)

val load_themes : unit -> unit Js.Promise.t
(** [load_themes ()] refreshes Theme cards from the API. *)

val forget_resume : unit -> unit
(** [forget_resume ()] clears the stored résumé. *)

val remember_admin_token : string -> unit
(** [remember_admin_token token] stores the reviewer token. *)

val start : unit -> unit
(** [start ()] wires persistence, samples, and URL sync. *)
