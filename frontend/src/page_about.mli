(** [/about] — the Stage. *)

val contract_url : string
(** [contract_url] is the class-contract document on this origin. *)

val example_url : string
(** [example_url] is the sample Skeleton HTML on this origin. *)

val make : unit -> H.node
(** [make ()] is the About page. *)
