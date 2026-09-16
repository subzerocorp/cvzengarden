(** Safe hrefs: http(s), mailto, tel; everything else is dropped. *)

val hostname : Js.String.t -> Js.String.t
(** [hostname href] is the host of [href], or [""] when none is present. *)

val safe_href : Js.String.t -> Js.String.t option
(** [safe_href raw] is a usable href, or [None] for javascript/data/empty/unknown schemes. *)
