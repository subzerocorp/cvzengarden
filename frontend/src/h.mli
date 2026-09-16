(** Solid hyperscript. [h tag props children] returns a lazy element thunk. *)

type node
(** [node] is a hyperscript child or element. *)

type prop
(** [prop] is a Solid prop value. *)

val h : string -> prop Js.Dict.t -> node array -> node
(** [h tag props children] is a hyperscript element. *)

val str : string -> prop
(** [str s] is a string prop. *)

val bool : bool -> prop
(** [bool b] is a boolean prop. *)

val int : int -> prop
(** [int n] is an integer prop. *)

val handler : ('e -> unit) -> prop
(** [handler f] is an event or ref callback. *)

val dyn : (unit -> 'a) -> prop
(** [dyn f] is a reactive attribute getter. *)

val props : (Js.Dict.key * prop) list -> prop Js.Dict.t
(** [props pairs] is a prop dictionary. *)

val text : string -> node
(** [text s] is a text node. *)

val show : (unit -> node) -> node
(** [show f] is a reactive child. *)

val show_text : (unit -> string) -> node
(** [show_text f] is a reactive text child. *)

val many : node array -> node
(** [many nodes] flattens an array of children. *)

val of_nullable : node Js.nullable -> node
(** [of_nullable n] is a nullable child. *)

val nothing : node
(** [nothing] is an absent child. *)

val list : node list -> node
(** [list nodes] is [nodes] as children. *)

val when_ : bool -> node -> node
(** [when_ cond node] is [node] when [cond] is true, otherwise [nothing]. *)

val opt : node option -> node
(** [opt n] is the node, or [nothing]. *)

val el : string -> ?a:(Js.Dict.key * prop) list -> node list -> node
(** [el tag ?a children] is a tagged element. *)

val div : ?a:(Js.Dict.key * prop) list -> node list -> node
(** [div ?a children] is a [div]. *)

val span : ?a:(Js.Dict.key * prop) list -> node list -> node
(** [span ?a children] is a [span]. *)

val p : ?a:(Js.Dict.key * prop) list -> node list -> node
(** [p ?a children] is a [p]. *)

val button : ?a:(Js.Dict.key * prop) list -> node list -> node
(** [button ?a children] is a [button]. *)

val a : ?a:(Js.Dict.key * prop) list -> node list -> node
(** [a ?a children] is an [a]. *)

val ul : ?a:(Js.Dict.key * prop) list -> node list -> node
(** [ul ?a children] is a [ul]. *)

val li : ?a:(Js.Dict.key * prop) list -> node list -> node
(** [li ?a children] is a [li]. *)

val ol : ?a:(Js.Dict.key * prop) list -> node list -> node
(** [ol ?a children] is an [ol]. *)

val h1 : ?a:(Js.Dict.key * prop) list -> node list -> node
(** [h1 ?a children] is an [h1]. *)

val h2 : ?a:(Js.Dict.key * prop) list -> node list -> node
(** [h2 ?a children] is an [h2]. *)

val h3 : ?a:(Js.Dict.key * prop) list -> node list -> node
(** [h3 ?a children] is an [h3]. *)

val label : ?a:(Js.Dict.key * prop) list -> node list -> node
(** [label ?a children] is a [label]. *)

val input : ?a:(Js.Dict.key * prop) list -> node list -> node
(** [input ?a children] is an [input]. *)

val textarea : ?a:(Js.Dict.key * prop) list -> node list -> node
(** [textarea ?a children] is a [textarea]. *)

val section : ?a:(Js.Dict.key * prop) list -> node list -> node
(** [section ?a children] is a [section]. *)

val header : ?a:(Js.Dict.key * prop) list -> node list -> node
(** [header ?a children] is a [header]. *)

val aside : ?a:(Js.Dict.key * prop) list -> node list -> node
(** [aside ?a children] is an [aside]. *)

val main : ?a:(Js.Dict.key * prop) list -> node list -> node
(** [main ?a children] is a [main]. *)

val nav : ?a:(Js.Dict.key * prop) list -> node list -> node
(** [nav ?a children] is a [nav]. *)

val iframe : ?a:(Js.Dict.key * prop) list -> node list -> node
(** [iframe ?a children] is an [iframe]. *)
