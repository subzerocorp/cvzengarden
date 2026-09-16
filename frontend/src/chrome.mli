(** Global chrome: the top bar and the drawer. *)

val top_bar : unit -> H.node
(** [top_bar ()] is the 68px header. *)

val drawer : unit -> H.node
(** [drawer ()] is the GPUI-style menu. *)
