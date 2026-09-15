(** [/workbench] — Theme authoring. *)

open Rz_shared

val status_icon : Theme_lint.status -> H.node
(** [status_icon s] is the check-row icon for [s]. *)

val make : unit -> H.node
(** [make ()] is the Workbench page. *)
