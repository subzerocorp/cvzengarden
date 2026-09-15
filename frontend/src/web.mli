(** The browser surface the chrome touches. Every function here is an Action. *)

type element
(** [element] is a DOM element. *)

type document
(** [document] is a DOM document. *)

type window
(** [window] is a browsing context. *)

type event
(** [event] is a DOM event. *)

type location
(** [location] is [window.location]. *)

type history
(** [history] is [window.history]. *)

type file_list
(** [file_list] is a [FileList]. *)

val document : document
(** [document] is the page document. *)

val window : window
(** [window] is the page window. *)

val location : location
(** [location] is the page location. *)

val get_element_by_id : document -> string -> element Js.nullable
(** [get_element_by_id doc id] is the element with [id], if any. *)

val query_selector : document -> string -> element Js.nullable
(** [query_selector doc sel] is the first match of [sel], if any. *)

val document_element : document -> element
(** [document_element doc] is [doc.documentElement]. *)

val body : document -> element Js.nullable
(** [body doc] is [doc.body]. *)

val set_attribute : element -> string -> string -> unit
(** [set_attribute el name value] sets an attribute. *)

val set_text_content : element -> string -> unit
(** [set_text_content el text] sets [el.textContent]. *)

val set_inner_html : element -> string -> unit
(** [set_inner_html el html] sets [el.innerHTML]. *)

val scroll_height : element -> int
(** [scroll_height el] is [el.scrollHeight]. *)

val click : element -> unit
(** [click el] clicks [el]. *)

val value : element -> string
(** [value el] is an input's value. *)

val files : element -> file_list Js.nullable
(** [files el] is a file input's files. *)

val content_document : element -> document Js.nullable
(** [content_document iframe] is the framed document. *)

val content_window : element -> window Js.nullable
(** [content_window iframe] is the framed window. *)

val print : window -> unit
(** [print w] opens the print dialog on [w]. *)

val key : event -> string
(** [key e] is the key name. *)

val prevent_default : event -> unit
(** [prevent_default e] cancels the default action. *)

val target : event -> element
(** [target e] is the event target. *)

val data_transfer_files : event -> file_list Js.nullable
(** [data_transfer_files e] is the drag-and-drop file list. *)

val window_listener : window -> string -> (event -> unit) -> unit
(** [window_listener w name f] adds a window listener. *)

val scroll_to : window -> int -> int -> unit
(** [scroll_to w x y] scrolls [w]. *)

val open_ : window -> string -> string -> unit
(** [open_ w url target] opens [url]. *)

val prompt : window -> string -> string -> string Js.nullable
(** [prompt w message def] is the dialog result. *)

val request_animation_frame : window -> (float -> unit) -> unit
(** [request_animation_frame w f] schedules [f]. *)

val first_file : file_list Js.nullable -> Js.File.t option
(** [first_file list] is the first file, if any. *)

val pathname : location -> string
(** [pathname loc] is the path. *)

val search : location -> string
(** [search loc] is the query string. *)

val href : location -> string
(** [href loc] is the full URL. *)

val push_url : string -> unit
(** [push_url url] pushes [url] onto history. *)

val replace_url : string -> unit
(** [replace_url url] replaces the current history entry. *)

val storage_get : string -> string option
(** [storage_get key] is a localStorage value, or [None] when storage is blocked. *)

val storage_set : string -> string -> unit
(** [storage_set key value] writes localStorage, ignoring a blocked store. *)

val storage_remove : string -> unit
(** [storage_remove key] removes a localStorage key, ignoring a blocked store. *)

val ( let> ) : 'a Js.Promise.t -> ('a -> 'b Js.Promise.t) -> 'b Js.Promise.t
(** [let> x = p in f x] is [Js.Promise.then_ f p]. *)

val get_text : string -> string option Js.Promise.t
(** [get_text url] is a GET text body, or [None] on failure. *)

type request_init = {
  method_ : string; [@mel.as "method"]
  headers : string Js.Dict.t;
  body : string;
}
(** [request_init] is a fetch init with a body. *)

type bodiless_init = { method_ : string; [@mel.as "method"] headers : string Js.Dict.t }
(** [bodiless_init] is a fetch init without a body. *)

val request :
  method_:string ->
  headers:(string * string) list ->
  ?body:string ->
  string ->
  (int * string) Js.Promise.t
(** [request ~method_ ~headers ?body url] is status and body, or [(0, "")] on network failure. *)

val post_json : string -> string -> (int * string) Js.Promise.t
(** [post_json url body] POSTs JSON and returns status and text. *)

val clipboard_write : string -> unit Js.Promise.t
(** [clipboard_write text] writes the clipboard. *)
