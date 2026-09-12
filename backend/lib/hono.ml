(** Hono bindings: the app, request context, and the Bun static adapter. *)

type t
type ctx
type middleware
type handler = ctx -> Bun.response Js.Promise.t

external create : unit -> t = "Hono" [@@mel.module "hono"] [@@mel.new]
external get : t -> string -> handler -> unit = "get" [@@mel.send]
external post : t -> string -> handler -> unit = "post" [@@mel.send]
external use : t -> string -> middleware -> unit = "use" [@@mel.send]
external not_found : t -> handler -> unit = "notFound" [@@mel.send]
external on_error : t -> (Js.Exn.t -> ctx -> Bun.response) -> unit = "onError" [@@mel.send]
external fetch : t -> Bun.fetch_fn = "fetch" [@@mel.get]

external request_raw : t -> string -> 'init -> 'a = "request"
[@@mel.send]
(** [app.request] returns a Response or a promise of one; normalise. *)

let request app path : Bun.response Js.Promise.t =
  Promise.flatten (request_raw app path Js.undefined)

type request_init = {
  method_ : string; [@mel.as "method"]
  headers : string Js.Dict.t;
  body : string;
}

(** A JSON POST through [app.request], for tests. *)
let request_raw_init ?(headers = []) path body app : Bun.response Js.Promise.t =
  Promise.flatten
    (request_raw app path
       {
         method_ = "POST";
         headers = Js.Dict.fromList (("Content-Type", "application/json") :: headers);
         body;
       })

(** A GET with extra headers through [app.request], for tests. *)
let request_with_headers headers path app : Bun.response Js.Promise.t =
  Promise.flatten
    (request_raw app path { method_ = "GET"; headers = Js.Dict.fromList headers; body = "" })

(* ── Context ─────────────────────────────────────────────────────────── *)

external json : ctx -> Js.Json.t -> int -> Bun.response = "json" [@@mel.send]
external html : ctx -> string -> Bun.response = "html" [@@mel.send]
external body : ctx -> string -> int -> string Js.Dict.t -> Bun.response = "body" [@@mel.send]
external redirect : ctx -> string -> Bun.response = "redirect" [@@mel.send]
external param : ctx -> string -> string = "param" [@@mel.send] [@@mel.scope "req"]
external query : ctx -> string -> string Js.nullable = "query" [@@mel.send] [@@mel.scope "req"]
external path : ctx -> string = "path" [@@mel.get] [@@mel.scope "req"]
external req_text : ctx -> string Js.Promise.t = "text" [@@mel.send] [@@mel.scope "req"]

external header_raw : ctx -> string -> string Js.nullable = "header"
[@@mel.send] [@@mel.scope "req"]

let query_opt ctx name = Js.Nullable.toOption (query ctx name)
let header ctx name = Js.Nullable.toOption (header_raw ctx name)
let with_type content_type = Js.Dict.fromList [ ("Content-Type", content_type) ]
let css ctx text = body ctx text 200 (with_type "text/css; charset=utf-8")
let json_text ctx text = body ctx text 200 (with_type "application/json; charset=utf-8")

(* ── Responses ───────────────────────────────────────────────────────── *)

external response_status : Bun.response -> int = "status" [@@mel.get]
external response_text : Bun.response -> string Js.Promise.t = "text" [@@mel.send]

external response_header : Bun.response -> string -> string Js.nullable = "get"
[@@mel.send] [@@mel.scope "headers"]

(* ── Static files (Bun adapter) ──────────────────────────────────────── *)

type static_options = { root : string; rewriteRequestPath : string -> string }

external serve_static : static_options -> middleware = "serveStatic" [@@mel.module "hono/bun"]

let strip_prefix prefix path =
  if Js.String.startsWith ~prefix path then Js.String.slice ~start:(String.length prefix) path
  else path

(** Serve [dir] under the URL [prefix]: [/assets/* → frontend/dist/assets/*]. *)
let mount_static app ~prefix ~dir =
  use app (prefix ^ "/*") (serve_static { root = dir; rewriteRequestPath = strip_prefix prefix })
