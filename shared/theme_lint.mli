type status = Pass | Warn | Fail | Pending
type check = { id : string; title : string; note : string; status : status }

val status_key : status -> string
val status_of_key : string -> status option
val re : ?flags:string -> string -> Js.Re.t
val test : Js.Re.t -> string -> bool
val replace : Js.re -> Js.String.t -> Js.String.t -> Js.String.t
val comments : Js.Re.t
val strings : Js.Re.t
val strip_comments : Js.String.t -> Js.String.t
val strip_strings : Js.String.t -> Js.String.t

type context = Rule | Conditional | Opaque

val conditional_at_rules : string list
val starts_with_any : Js.String.t list -> Js.String.t -> bool
val classify_prelude : context list -> Js.String.t -> context * Js.String.t option

type scan = { pending : string; stack : context list; found : string list }

val scan_char : scan -> char -> scan
val preludes : Js.String.t -> string list
val split_selectors : string -> Js.String.t list
val combinators : Js.Re.t
val pseudo_tail : Js.Re.t
val is_document_compound : Js.String.t -> bool
val is_contract_compound : Js.String.t -> bool
val is_bare_compound : Js.String.t -> bool
val compounds : Js.String.t -> Js.String.t list
val is_contract_selector : Js.String.t -> bool
val offending_selectors : Js.String.t -> Js.String.t list
val quote_list : string list -> string
val check_scope : Js.String.t -> check
val header_re : Js.Re.t
val anywhere_re : Js.Re.t
val declared_target : string -> string option
val check_header : string -> check
val forbidden : (string * string) list
val check_pure_css : Js.String.t -> check
val content_decl : Js.Re.t
val quoted : Js.Re.t
val wordish : Js.Re.t
val matches_of : Js.Re.t -> string -> string list -> string list
val content_strings : Js.String.t -> string list
val check_words : Js.String.t -> check
val url_re : Js.Re.t
val external_urls : Js.String.t -> Js.String.t list

type source = Https of string | Library | Data | Insecure of string | Other_relative of string

val classify_url : Js.String.t -> source
val unique : 'a list -> 'a list
val check_fonts : Js.String.t -> check
val page_limit : int
val pages_pending : check
val pages_measured : int -> check
val motion_re : Js.Re.t
val declares_motion : Js.String.t -> bool
val check_motion : Js.String.t -> check
val run : Js.String.t -> check list
val with_pages : int -> check list -> check list
val passing : check list -> int
val blocking : check list -> bool
val to_json : check -> Js.Json.t
val list_to_json : check list -> Js.Json.t
val ( let* ) : ('a, 'b) result -> ('a -> ('c, 'b) result) -> ('c, 'b) result
val decode : check Decode.t
