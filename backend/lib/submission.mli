(** A Theme offered to the Garden: decoded from the request body. *)

open Rz_shared

type t = {
  name : string;
  author : string;
  author_url : string option;
  target : Theme_meta.target;
  fonts : Theme_meta.fonts;
  css : string;
  swatches : (string * string * string) option;
  measured_pages : int;
}
(** [t] is a decoded submission. [measured_pages] is the Workbench count on the long fixture. *)

val decode : t Decode.t
(** [decode] reads a submission from a JSON object. *)

val fresh_id : taken:string list -> string -> string
(** [fresh_id ~taken name] is a unique Theme id past [taken]. *)

val to_meta : id:string -> t -> Theme_meta.t
(** [to_meta ~id t] is the Theme card stored for [t]. *)
