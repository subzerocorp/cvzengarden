(** The HTTP surface. Handlers are thin: decode → Calculation → respond. *)

open Rz_shared
open Promise

type config = {
  themes_dir : string;  (** first-party CSS and the Font Library *)
  skeleton_dir : string;  (** fixtures served as samples *)
  static_dir : string;  (** the built chrome *)
  admin_token : string option;  (** bearer token for moderation; [None] disables it *)
}

let default_config =
  {
    themes_dir = "themes";
    skeleton_dir = "skeleton";
    static_dir = "frontend/dist";
    admin_token = None;
  }

(* ── Response helpers ─────────────────────────────────────────────────── *)

let obj fields = Js.Json.object_ (Js.Dict.fromList fields)

let error_json ?path message =
  obj
    [
      ( "error",
        obj
          ([ ("message", Js.Json.string message) ]
          @ Option.fold ~none:[] ~some:(fun p -> [ ("path", Js.Json.string p) ]) path) );
    ]

let bad_request ctx (e : Decode.error) =
  let path = if e.path = "" then None else Some e.path in
  Hono.json ctx (error_json ?path e.message) 400

let not_found ctx what = Hono.json ctx (error_json (what ^ " not found")) 404

(** [Authorization: Bearer <token>] must match the configured token. *)
let authorized config ctx =
  match (config.admin_token, Hono.header ctx "authorization") with
  | None, _ -> Error (503, "Moderation is not configured on this Garden (set RZ_ADMIN_TOKEN)")
  | Some token, Some value when value = "Bearer " ^ token -> Ok ()
  | Some _, _ -> Error (401, "A reviewer token is required")

let handler f : Hono.handler = fun ctx -> f ctx

(* ── Theme CSS: first-party from disk, Submissions from the store ─────── *)

let theme_id_shape = Js.Re.fromString "^[a-z0-9_-]+$"
let well_formed_id id = Js.Re.test ~str:id theme_id_shape

(** A stylesheet on disk under [themes/]: first-party Themes and the starter [_blank.css]. Ids are
    restricted to a safe alphabet first. *)
let disk_css config id =
  if well_formed_id id then Bun.read_text (Printf.sprintf "%s/%s.css" config.themes_dir id)
  else return None

(** The stylesheet the public may fetch: first-party from disk, Submissions from the store unless
    rejected (a reviewer may still fetch those). *)
let theme_css config db ~reviewer id =
  let> stored = Db.find db id in
  match stored with
  | Some t when t.status = Theme_meta.Rejected && not reviewer -> return None
  | Some t when t.status = Theme_meta.Official -> disk_css config id
  | Some _ -> Db.stored_css db id
  | None -> disk_css config id

(* ── Routes ───────────────────────────────────────────────────────────── *)

let themes_json themes =
  obj [ ("themes", Js.Json.array (Array.of_list (List.map Theme_meta.to_json themes))) ]

let route_health app db =
  Hono.get app "/api/health"
    (handler (fun ctx ->
         let> n = Db.count db in
         return
           (Hono.json ctx
              (obj [ ("ok", Js.Json.boolean true); ("themes", Js.Json.number (float_of_int n)) ])
              200)))

let list_themes db =
  handler (fun ctx ->
      let> themes = Db.list db in
      let listed = List.filter Theme_meta.is_listed themes in
      let themes =
        match Hono.query_opt ctx "status" with
        | Some status ->
            List.filter (fun (t : Theme_meta.t) -> Theme_meta.status_key t.status = status) listed
        | None -> listed
      in
      return (Hono.json ctx (themes_json themes) 200))

let checks_json = function
  | Some text -> (
      match Decode.parse_json text with Ok json -> json | Error _ -> Js.Json.array [||])
  | None -> Js.Json.array [||]

let theme_detail db =
  handler (fun ctx ->
      let id = Hono.param ctx "id" in
      let> theme = Db.find db id in
      match theme with
      | None -> return (not_found ctx "theme")
      | Some t ->
          let> checks = Db.stored_checks db id in
          return
            (Hono.json ctx
               (obj [ ("theme", Theme_meta.to_json t); ("checks", checks_json checks) ])
               200))

let theme_stylesheet db config =
  handler (fun ctx ->
      let id = Js.String.replace ~search:".css" ~replacement:"" (Hono.param ctx "id") in
      let reviewer = Result.is_ok (authorized config ctx) in
      let> css = theme_css config db ~reviewer id in
      match css with
      | Some css -> return (Hono.css ctx css)
      | None -> return (not_found ctx "stylesheet"))

let route_themes app db config =
  Hono.get app "/api/themes" (list_themes db);
  Hono.get app "/api/themes/:id" (theme_detail db);
  Hono.get app "/api/themes/:id/css" (theme_stylesheet db config);
  Hono.get app "/themes/:id{.+\\.css}" (theme_stylesheet db config)

let css_of_body body =
  Option.bind
    (Result.to_option (Decode.parse_json body))
    (fun json ->
      Option.bind (Js.Json.decodeObject json) (fun o ->
          Option.bind (Js.Dict.get o "css") Js.Json.decodeString))

let route_lint app =
  Hono.post app "/api/lint"
    (handler (fun ctx ->
         let> body = Hono.req_text ctx in
         match css_of_body body with
         | None -> return (bad_request ctx { path = "css"; message = "is required" })
         | Some css ->
             let checks = Theme_lint.run css in
             return
               (Hono.json ctx
                  (obj
                     [
                       ("checks", Theme_lint.list_to_json checks);
                       ("passing", Js.Json.number (float_of_int (Theme_lint.passing checks)));
                       ("blocking", Js.Json.boolean (Theme_lint.blocking checks));
                     ])
                  200)))

let route_render app db config =
  Hono.post app "/api/render"
    (handler (fun ctx ->
         let> body = Hono.req_text ctx in
         match Resume.of_string body with
         | Error e -> return (bad_request ctx e)
         | Ok resume ->
             let> theme_css =
               match Hono.query_opt ctx "theme" with
               | Some id -> theme_css config db ~reviewer:false id
               | None -> return None
             in
             let document =
               match theme_css with
               | Some css -> Sandbox_doc.standalone ~theme_css:css resume
               | None -> Skeleton.render resume
             in
             return
               (Hono.json ctx
                  (obj
                     [
                       ("title", Js.Json.string (Skeleton.document_title resume));
                       ("article", Js.Json.string (Skeleton.render_article resume));
                       ("html", Js.Json.string document);
                     ])
                  200)))

let sample_path config = function
  | "junior" -> Some (config.skeleton_dir ^ "/samples/junior.json")
  | "jordan" | "long" -> Some (config.skeleton_dir ^ "/resume.json")
  | _ -> None

(** [/preview/:id.html?sample=jordan|junior] — the sample résumé in one Theme as a standalone
    document, printable as the browser would. *)
let route_preview app db config =
  Hono.get app "/preview/:id{.+\\.html}"
    (handler (fun ctx ->
         let id = Js.String.replace ~search:".html" ~replacement:"" (Hono.param ctx "id") in
         let sample = Option.value (Hono.query_opt ctx "sample") ~default:"jordan" in
         let> css = theme_css config db ~reviewer:false id in
         let> json =
           match sample_path config sample with
           | Some path -> Bun.read_text path
           | None -> return None
         in
         match (css, Option.bind json (fun j -> Result.to_option (Resume.of_string j))) with
         | Some css, Some resume ->
             return (Hono.html ctx (Sandbox_doc.standalone ~theme_css:css resume))
         | None, _ -> return (not_found ctx "stylesheet")
         | _, None -> return (not_found ctx "sample")))

let route_samples app config =
  Hono.get app "/api/samples/:name"
    (handler (fun ctx ->
         match sample_path config (Hono.param ctx "name") with
         | None -> return (not_found ctx "sample")
         | Some path ->
             let> text = Bun.read_text path in
             return
               (match text with Some t -> Hono.json_text ctx t | None -> not_found ctx "sample")))

let review_queue db =
  handler (fun ctx ->
      let> themes = Db.list db in
      let queue = List.filter (fun (t : Theme_meta.t) -> t.status = Theme_meta.In_review) themes in
      return (Hono.json ctx (themes_json queue) 200))

let rejected_json checks =
  obj
    [
      ("error", obj [ ("message", Js.Json.string "The stylesheet fails a contract check") ]);
      ("checks", Theme_lint.list_to_json checks);
    ]

(** Store a linted Submission under a fresh id and answer with its card. *)
let accept db (submission : Submission.t) checks ctx =
  let> existing = Db.list db in
  let taken = List.map (fun (t : Theme_meta.t) -> t.id) existing in
  let meta = Submission.to_meta ~id:(Submission.fresh_id ~taken submission.name) submission in
  let checks_json = Js.Json.stringify (Theme_lint.list_to_json checks) in
  let> _ =
    Db.insert ~conflict:Fail db meta ~css:(Some submission.css) ~checks_json:(Some checks_json)
  in
  return
    (Hono.json ctx
       (obj [ ("theme", Theme_meta.to_json meta); ("checks", Theme_lint.list_to_json checks) ])
       201)

let submit db =
  handler (fun ctx ->
      let> body = Hono.req_text ctx in
      match Result.bind (Decode.parse_json body) (Submission.decode ~path:"") with
      | Error e -> return (bad_request ctx e)
      | Ok submission ->
          let checks =
            Theme_lint.with_pages submission.measured_pages (Theme_lint.run submission.css)
          in
          if Theme_lint.blocking checks then return (Hono.json ctx (rejected_json checks) 422)
          else accept db submission checks ctx)

let route_submissions app db =
  Hono.get app "/api/submissions" (review_queue db);
  Hono.post app "/api/submissions" (submit db)

(* ── Moderation ───────────────────────────────────────────────────────── *)

let review_json (t : Theme_meta.t) (review : Db.review option) =
  let checks =
    match
      Option.bind review (fun r ->
          Option.bind r.checks_json (fun c -> Result.to_option (Decode.parse_json c)))
    with
    | Some json -> json
    | None -> Js.Json.array [||]
  in
  let text = function Some s -> Js.Json.string s | None -> Js.Json.null in
  obj
    [
      ("theme", Theme_meta.to_json t);
      ("checks", checks);
      ("reviewNote", text (Option.bind review (fun r -> r.review_note)));
      ("reviewedAt", text (Option.bind review (fun r -> r.reviewed_at)));
    ]

let guarded config f : Hono.handler =
  handler (fun ctx ->
      match authorized config ctx with
      | Error (status, message) -> return (Hono.json ctx (error_json message) status)
      | Ok () -> f ctx)

let note_of_body body =
  match Decode.parse_json body with
  | Ok json ->
      Option.bind (Js.Json.decodeObject json) (fun o ->
          Option.bind (Js.Dict.get o "note") Js.Json.decodeString)
  | Error _ -> None

let decide db config status =
  guarded config (fun ctx ->
      let id = Hono.param ctx "id" in
      let> body = Hono.req_text ctx in
      let note =
        Option.bind (note_of_body body) (fun raw ->
            match Js.String.trim raw with "" -> None | trimmed -> Some trimmed)
      in
      let> changed = Db.set_status db id status ~note in
      if not changed then return (not_found ctx "submission")
      else
        let> theme = Db.find db id in
        let> review = Db.review db id in
        match theme with
        | Some t -> return (Hono.json ctx (review_json t review) 200)
        | None -> return (not_found ctx "submission"))

let route_admin app db config =
  Hono.get app "/api/admin/queue"
    (guarded config (fun ctx ->
         let> themes = Db.list db in
         let queue =
           List.filter (fun (t : Theme_meta.t) -> t.status <> Theme_meta.Official) themes
         in
         let> entries =
           Js.Promise.all
             (Array.of_list
                (List.map
                   (fun (t : Theme_meta.t) ->
                     Promise.map (fun r -> review_json t r) (Db.review db t.id))
                   queue))
         in
         return (Hono.json ctx (obj [ ("queue", Js.Json.array entries) ]) 200)));
  Hono.post app "/api/admin/themes/:id/approve" (decide db config Theme_meta.Approved);
  Hono.post app "/api/admin/themes/:id/reject" (decide db config Theme_meta.Rejected)

(* ── Static chrome ────────────────────────────────────────────────────── *)

let spa_routes = [ "/"; "/gallery"; "/about"; "/studio"; "/workbench"; "/admin" ]

let route_static app config =
  Hono.mount_static app ~prefix:"/assets" ~dir:(config.static_dir ^ "/assets");
  (* BAR-T2: preview.css is a local readability aid, never a served asset. *)
  Hono.get app "/skeleton/preview.css" (handler (fun ctx -> return (not_found ctx "preview.css")));
  Hono.mount_static app ~prefix:"/skeleton" ~dir:config.skeleton_dir;
  Hono.mount_static app ~prefix:"/fonts" ~dir:(config.themes_dir ^ "/fonts");
  Hono.mount_static app ~prefix:"/themes/fonts" ~dir:(config.themes_dir ^ "/fonts");
  let index =
    handler (fun ctx ->
        let> html = Bun.read_text (config.static_dir ^ "/index.html") in
        match html with
        | Some html -> return (Hono.html ctx html)
        | None ->
            return
              (Hono.body ctx "The chrome is not built yet. Run `just build`." 503
                 (Hono.with_type "text/plain; charset=utf-8")))
  in
  List.iter (fun path -> Hono.get app path index) spa_routes

(* ── App ──────────────────────────────────────────────────────────────── *)

let build ?(config = default_config) db =
  let app = Hono.create () in
  Hono.on_error app (fun exn ctx ->
      Bun.error ("unhandled: " ^ Option.value (Js.Exn.message exn) ~default:"error");
      Hono.json ctx (error_json "Internal error") 500);
  route_health app db;
  route_themes app db config;
  route_lint app;
  route_render app db config;
  route_samples app config;
  route_preview app db config;
  route_submissions app db;
  route_admin app db config;
  route_static app config;
  Hono.not_found app (handler (fun ctx -> return (not_found ctx "route")));
  app
