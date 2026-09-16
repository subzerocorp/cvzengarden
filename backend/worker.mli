(** Cloudflare Worker entry: [export default { fetch }] over the same Hono app as [Main]. *)

open Rz_backend

type env
(** [env] is the Worker's bindings: [ASSETS] and the secrets from [wrangler.toml]. *)

type exec_ctx
(** [exec_ctx] is the execution context Workers pass; forwarded to Hono. *)

val fetch : Bun.request -> env -> exec_ctx -> Bun.response Js.Promise.t
(** [fetch request env ctx] answers one request: the app when the store is configured, the static
    assets and the chrome regardless. *)

val default : < fetch : Bun.request -> env -> exec_ctx -> Bun.response Js.Promise.t > Js.t
(** [default] is the module's default export, the object Workers call. *)
