(** Hono's Bun adapter: static directories served from disk. Kept apart from [Hono] so the Worker
    bundle never imports [hono/bun], whose module body touches the [Bun] global. *)

type static_options = { root : string; rewriteRequestPath : string -> string }

external serve_static : static_options -> Hono.middleware = "serveStatic" [@@mel.module "hono/bun"]

let strip_prefix prefix path =
  if Js.String.startsWith ~prefix path then Js.String.slice ~start:(String.length prefix) path
  else path

(** Serve [dir] under the URL [prefix]: [/assets/* → frontend/dist/assets/*]. *)
let mount_static app ~prefix ~dir =
  Hono.use app (prefix ^ "/*")
    (serve_static { root = dir; rewriteRequestPath = strip_prefix prefix })
