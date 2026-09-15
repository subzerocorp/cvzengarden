(** Shareable URL state: the page, the staged Theme and the view. *)

open Rz_shared

type page =
  | Garden
  | Gallery
  | About
  | Studio
  | Workbench
  | Admin  (** [page] is one chrome route. *)

val all : page list
(** [all] is every route in nav order. *)

val path : page -> string
(** [path p] is the pathname for [p]. *)

val label : page -> string
(** [label p] is the chrome label for [p]. *)

val of_path : string -> page option
(** [of_path pathname] is the route for [pathname]. *)

val is_fixed : page -> bool
(** [is_fixed p] is [true] when [p] never scrolls the page. *)

val is_authoring : page -> bool
(** [is_authoring p] is [true] for Studio and Workbench. *)

type state = { page : page; theme : string option; view : View_mode.t option }
(** [state] is the shareable URL triple. *)

val parse : pathname:string -> search:string -> state
(** [parse ~pathname ~search] reads the URL. *)

val to_url : state -> string
(** [to_url s] is the path and query for [s]. *)
