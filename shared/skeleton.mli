(** The Renderer: a Resume becomes one Skeleton HTML tree. *)

val tel_href : Js.String.t -> string
(** [tel_href raw] is a [tel:] href with punctuation stripped. *)

val format_score : string -> string
(** [format_score raw] is [GPA n] for a numeric score, otherwise [raw] trimmed. *)

val profile_type : Js.String.t -> Js.String.t
(** [profile_type network] is the contract profile kind ([github], [x], [other], …). *)

val document_title : Resume.t -> Js.String.t
(** [document_title r] is the HTML title drawn from basics name and label. *)

val render_article : Resume.t -> string
(** [render_article r] is the [article.rz-resume] inner HTML. *)

val render : ?style:string -> Resume.t -> string
(** [render ?style r] is a full HTML document of [r], with optional inline CSS. *)
