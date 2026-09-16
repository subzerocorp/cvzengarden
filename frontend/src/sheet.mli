(** The sandboxed résumé preview iframe. *)

open Rz_shared

type props = {
  css : unit -> string option;
  view : unit -> View_mode.t;
  article : unit -> string;
  primary : bool;
  on_pages : (int -> unit) option;
  class_ : string;
}
(** [props] is what one preview frame needs. [primary] registers the print target. *)

val load_overlays : unit -> unit Js.Promise.t
(** [load_overlays ()] fetches sandbox.css and paper.css. *)

val make : props -> H.node
(** [make p] is the preview iframe for [p]. *)
