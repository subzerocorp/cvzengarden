(** Theme card metadata: what the Gallery, the Switcher and the store agree on. *)

type target = Screen | Paper | Both  (** [target] is the media a Theme is built for. *)

val target_key : target -> string
(** [target_key t] is the wire spelling of [t]. *)

val target_of_key : string -> target option
(** [target_of_key s] is the target for a wire value. *)

val target_label : target -> string
(** [target_label t] is the chrome label for [t]. *)

val target_supports : target -> View_mode.t -> bool
(** [target_supports t view] is [true] when [t] can render [view]. *)

type status =
  | Official
  | Approved
  | In_review
  | Rejected  (** [status] is a Theme's place in the Garden. *)

val status_key : status -> string
(** [status_key s] is the wire spelling of [s]. *)

val status_of_key : string -> status option
(** [status_of_key s] is the status for a wire value. *)

val status_label : status -> string
(** [status_label s] is the chrome label for [s]. *)

type fonts = Library | Https_cdn  (** [fonts] is where a Theme loads its faces. *)

val fonts_key : fonts -> string
(** [fonts_key f] is the wire spelling of [f]. *)

val fonts_of_key : string -> fonts option
(** [fonts_of_key s] is the font source for a wire value. *)

type t = {
  id : string;
  name : string;
  author : string;
  author_url : string option;
  target : target;
  fonts : fonts;
  swatches : string * string * string;
  badge : string;
  bg : string;
  status : status;
}
(** [t] is a Theme card. [swatches] is ground, ink, accent. *)

val file : t -> string
(** [file t] is the stylesheet filename for [t]. *)

val is_public : t -> bool
(** [is_public t] is [true] for first-party and approved Themes. *)

val is_listed : t -> bool
(** [is_listed t] is [true] for every status except [Rejected]. *)

val officials : t list
(** [officials] is the first-party set. *)

val default_id : string
(** [default_id] is the Garden's default Theme id. *)

val find_official : string -> t option
(** [find_official id] is the first-party card with [id], if any. *)

val to_json : t -> Js.Json.t
(** [to_json t] is the wire object for a Theme card. *)

val decode : t Decode.t
(** [decode] reads a Theme card from a wire object. *)

val list_of_json : Js.Json.t -> (t list, Decode.error) result
(** [list_of_json json] decodes a [themes] array. *)
