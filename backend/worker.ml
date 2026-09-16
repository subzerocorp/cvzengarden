(** Cloudflare Worker entry: [export default { fetch }]. The store is Turso over HTTP; the chrome,
    Themes, Font Library and skeleton files are static assets read through the [ASSETS] binding. The
    app is built on the first request (migration and seeding included) and reused afterwards. *)

open Rz_backend
open Promise

type env = {
  _ASSETS : assets; [@mel.as "ASSETS"]
  _DATABASE_URL : string Js.nullable; [@mel.as "DATABASE_URL"]
  _DATABASE_AUTH_TOKEN : string Js.nullable; [@mel.as "DATABASE_AUTH_TOKEN"]
  _RZ_ADMIN_TOKEN : string Js.nullable; [@mel.as "RZ_ADMIN_TOKEN"]
  _RZ_SEED_DEMO : string Js.nullable; [@mel.as "RZ_SEED_DEMO"]
}
(** The Worker's bindings, as declared in [wrangler.toml] and by [wrangler secret put]. *)

and assets

type exec_ctx
(** The execution context Workers pass; unused, passed through to Hono. *)

external assets_fetch : assets -> Bun.request -> Bun.response Js.Promise.t = "fetch" [@@mel.send]
external request_of_url : string -> Bun.request = "Request" [@@mel.new]
external request_url : Bun.request -> string = "url" [@@mel.get]

type url
(** A parsed URL, used for its [origin] and [pathname] only. *)

external parse_url : string -> url = "URL" [@@mel.new]
external origin : url -> string = "origin" [@@mel.get]
external pathname : url -> string = "pathname" [@@mel.get]
external response_of_text : string -> 'init -> Bun.response = "Response" [@@mel.new]

let optional v = match Js.Nullable.toOption v with Some "" | None -> None | Some s -> Some s

(** A JSON answer without an app: the Worker is misconfigured. *)
let unconfigured message =
  let body = Js.Dict.fromList [ ("message", Js.Json.string message) ] in
  let json = Js.Json.object_ (Js.Dict.fromList [ ("error", Js.Json.object_ body) ]) in
  let headers = Js.Dict.fromList [ ("Content-Type", "application/json; charset=utf-8") ] in
  response_of_text (Js.Json.stringify json) [%mel.obj { status = 503; headers }]

(** Build the app once for this isolate. *)
let build env origin =
  match (optional env._DATABASE_URL, optional env._DATABASE_AUTH_TOKEN) with
  | None, _ | _, None -> return (Error "DATABASE_URL and DATABASE_AUTH_TOKEN secrets are required")
  | Some url, Some auth_token ->
      let db = Db.of_client (Libsql_web.connect ~url ~auth_token) in
      let> () = Db.migrate db in
      let> () = Seed.run ~demo:(optional env._RZ_SEED_DEMO = Some "1") db in
      let fetch_asset path = assets_fetch env._ASSETS (request_of_url (origin ^ path)) in
      let config =
        {
          Api.default_config with
          admin_token = optional env._RZ_ADMIN_TOKEN;
          files = Assets fetch_asset;
        }
      in
      return (Ok (Api.build ~config db))

let app : (Hono.t, string) result Js.Promise.t option ref = ref None

(** Paths only the app can answer; everything else is a static asset or the chrome, which still
    serve when the store is misconfigured. *)
let needs_app path =
  List.exists (fun prefix -> Js.String.startsWith ~prefix path) [ "/api/"; "/preview/" ]

(** A build that raised (an unreachable store, say) is an [Error], not a rejected promise, so it is
    reported and retried like a missing secret. *)
let guarded build =
  Js.Promise.catch
    (fun error -> return (Error ("the store did not answer: " ^ Js.String.make error)))
    build

(** The app promise for this isolate: built on first use, kept only when it built, so a fixed
    configuration is picked up by the next request. *)
let app_for env origin =
  match !app with
  | Some building -> building
  | None ->
      let building = guarded (build env origin) in
      app := Some building;
      let> built = building in
      (match built with Ok _ -> () | Error _ -> app := None);
      return built

(** Without an app the chrome and the static files still answer; only the API and the previews
    report the missing store. *)
let without_app env url message request =
  let path = pathname url in
  if needs_app path then return (unconfigured message)
  else if List.mem path Api.spa_routes then
    assets_fetch env._ASSETS (request_of_url (origin url ^ "/index.html"))
  else assets_fetch env._ASSETS request

let fetch (request : Bun.request) (env : env) (ctx : exec_ctx) =
  let url = parse_url (request_url request) in
  let> built = app_for env (origin url) in
  match built with
  | Ok hono -> Hono.fetch_with_env hono request env ctx
  | Error message -> without_app env url message request

let default = [%mel.obj { fetch }]
