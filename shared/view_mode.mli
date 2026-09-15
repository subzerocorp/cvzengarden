(** The two render views: a Theme as a web page, or ink on a Letter sheet. *)

type t = Screen | Paper  (** [t] is Screen or Paper. *)

val to_key : t -> string
(** [to_key v] is the URL query spelling of [v]. *)

val of_key : string -> t option
(** [of_key s] is the view for a query value. *)

val label : t -> string
(** [label v] is the chrome label for [v]. *)

val toggle : t -> t
(** [toggle v] is the other view. *)
