(** Unique slugs for [data-rz-entry] and [data-rz-skill-group]. *)

val slugify : Js.String.t -> Js.String.t
(** [slugify input] is a lowercase dash-separated identifier. *)

type used
(** [used] is the set of slugs already handed out in one document. *)

val fresh : unit -> used
(** [fresh ()] is an empty slug set. *)

val slug_or : fallback:Js.String.t -> Js.String.t -> Js.String.t
(** [slug_or ~fallback input] is [slugify input], or [fallback] when that is empty. *)

val entry_slug : used -> primary:Js.String.t -> start_year:int option -> Js.String.t
(** [entry_slug used ~primary ~start_year] is a unique entry slug, recorded in [used]. *)

val skill_slug : used -> Js.String.t -> Js.String.t
(** [skill_slug used name] is a unique skill-group slug, recorded in [used]. *)
