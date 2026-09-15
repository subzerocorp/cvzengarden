(** Hono bindings: the app, request context, and the Bun static adapter. *)

type t
(** [t] is a Hono app. *)

type ctx
(** [ctx] is a request context. *)

type middleware
(** [middleware] is a Hono middleware function. *)

type handler = ctx -> Bun.response Js.Promise.t
(** [handler] is a route handler. *)

val create : unit -> t
(** [create ()] is a new app. *)

val get : t -> string -> handler -> unit
(** [get app path h] registers a GET handler. *)

val post : t -> string -> handler -> unit
(** [post app path h] registers a POST handler. *)

val use : t -> string -> middleware -> unit
(** [use app path m] mounts middleware. *)

val not_found : t -> handler -> unit
(** [not_found app h] sets the 404 handler. *)

val on_error : t -> (Js.Exn.t -> ctx -> Bun.response) -> unit
(** [on_error app f] sets the unhandled-error handler. *)

val fetch : t -> Bun.fetch_fn
(** [fetch app] is the bound fetch function for [Bun.serve]. *)

val request : t -> string -> Bun.response Js.Promise.t
(** [request app path] is an in-process GET, for tests. *)

val request_raw_init :
  ?headers:(string * string) list -> string -> string -> t -> Bun.response Js.Promise.t
(** [request_raw_init ?headers path body app] is an in-process JSON POST, for tests. *)

val request_with_headers : (string * string) list -> string -> t -> Bun.response Js.Promise.t
(** [request_with_headers headers path app] is an in-process GET with headers, for tests. *)

type request_init = {
  method_ : string; [@mel.as "method"]
  headers : string Js.Dict.t;
  body : string;
}
(** [request_init] is a fetch init with a body. *)

val json : ctx -> Js.Json.t -> int -> Bun.response
(** [json ctx body status] is a JSON response. *)

val html : ctx -> string -> Bun.response
(** [html ctx markup] is an HTML response. *)

val body : ctx -> string -> int -> string Js.Dict.t -> Bun.response
(** [body ctx text status headers] is a raw body response. *)

val param : ctx -> string -> string
(** [param ctx name] is a path parameter. *)

val req_text : ctx -> string Js.Promise.t
(** [req_text ctx] is the request body as text. *)

val query_opt : ctx -> string -> string option
(** [query_opt ctx name] is a query parameter. *)

val header : ctx -> string -> string option
(** [header ctx name] is a request header. *)

val with_type : string -> string Js.Dict.t
(** [with_type content_type] is a Content-Type header dict. *)

val css : ctx -> string -> Bun.response
(** [css ctx text] is a stylesheet response. *)

val json_text : ctx -> string -> Bun.response
(** [json_text ctx text] is a JSON response from already-serialized text. *)

val response_status : Bun.response -> int
(** [response_status r] is the HTTP status. *)

val response_text : Bun.response -> string Js.Promise.t
(** [response_text r] is the response body. *)

val response_header : Bun.response -> string -> string Js.nullable
(** [response_header r name] is a response header. *)

type static_options = { root : string; rewriteRequestPath : string -> string }
(** [static_options] is the Bun static-file adapter config. *)

val mount_static : t -> prefix:string -> dir:string -> unit
(** [mount_static app ~prefix ~dir] serves [dir] under [prefix]. *)
