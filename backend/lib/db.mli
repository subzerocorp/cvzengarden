(** The store: one [themes] table holding first-party rows and Submissions. *)

open Rz_shared

type t
(** [t] is an open store. *)

val connect : url:string -> ?auth_token:string -> unit -> t
(** [connect ~url ?auth_token ()] opens the store. *)

val migrate : t -> unit Js.Promise.t
(** [migrate db] creates the schema and idempotent columns. *)

type insert_conflict =
  | Fail
  | Ignore  (** [insert_conflict] is what [insert] does when the id already exists. *)

val insert :
  conflict:insert_conflict ->
  t ->
  Theme_meta.t ->
  css:string option ->
  checks_json:string option ->
  int Js.Promise.t
(** [insert ~conflict db t ~css ~checks_json] writes a Theme row. *)

val list : t -> Theme_meta.t list Js.Promise.t
(** [list db] is every Theme card, officials first. *)

val find : t -> string -> Theme_meta.t option Js.Promise.t
(** [find db id] is the card with [id], if any. *)

val stored_css : t -> string -> string option Js.Promise.t
(** [stored_css db id] is the stylesheet stored on the row. *)

val stored_checks : t -> string -> string option Js.Promise.t
(** [stored_checks db id] is the checks JSON stored on the row. *)

type review = {
  checks_json : string option;
  review_note : string option;
  reviewed_at : string option;
}
(** [review] is what a reviewer sees beyond the card. *)

val review : t -> string -> review option Js.Promise.t
(** [review db id] is the review payload for [id]. *)

val set_status : t -> string -> Theme_meta.status -> note:string option -> bool Js.Promise.t
(** [set_status db id status ~note] updates a non-official row; [true] if a row changed. *)

val exists : t -> string -> bool Js.Promise.t
(** [exists db id] is whether a row with [id] is present. *)

val count_where : t -> string -> int Js.Promise.t
(** [count_where db status] is how many rows have [status]. *)

val count : t -> int Js.Promise.t
(** [count db] is the number of Theme rows. *)
