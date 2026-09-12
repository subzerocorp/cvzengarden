(** The store: one [themes] table holding first-party rows (CSS on disk) and Submissions (CSS in the
    row). Migrations are idempotent. *)

open Rz_shared
open Promise

type t = Libsql.client

let schema =
  {|
CREATE TABLE IF NOT EXISTS themes (
  id            TEXT PRIMARY KEY,
  name          TEXT NOT NULL,
  author        TEXT NOT NULL,
  author_url    TEXT,
  target        TEXT NOT NULL,
  fonts         TEXT NOT NULL,
  swatch_ground TEXT NOT NULL,
  swatch_ink    TEXT NOT NULL,
  swatch_accent TEXT NOT NULL,
  badge         TEXT NOT NULL,
  bg            TEXT NOT NULL,
  status        TEXT NOT NULL,
  css           TEXT,
  checks_json   TEXT,
  created_at    TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at    TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);
CREATE INDEX IF NOT EXISTS themes_status ON themes (status, created_at);
|}

let connect ~url ?auth_token () = Libsql.connect ~url ?auth_token ()
let migrate (db : t) = Libsql.execute_multiple db schema

(* ── Row ↔ Theme_meta ─────────────────────────────────────────────────── *)

let meta_of_row row : Theme_meta.t option =
  let open Libsql in
  let ( let* ) = Option.bind in
  let* id = text row "id" in
  let* target = Option.bind (text row "target") Theme_meta.target_of_key in
  let* status = Option.bind (text row "status") Theme_meta.status_of_key in
  let fonts =
    Option.value
      (Option.bind (text row "fonts") Theme_meta.fonts_of_key)
      ~default:Theme_meta.Library
  in
  Some
    {
      Theme_meta.id;
      name = text_or row "name" id;
      author = text_or row "author" "";
      author_url = text row "author_url";
      target;
      fonts;
      swatches =
        ( text_or row "swatch_ground" "#ffffff",
          text_or row "swatch_ink" "#000000",
          text_or row "swatch_accent" "#888888" );
      badge = text_or row "badge" "#2563eb";
      bg = text_or row "bg" "#ffffff";
      status;
    }

let columns =
  "id, name, author, author_url, target, fonts, swatch_ground, swatch_ink, swatch_accent, badge, \
   bg, status"

let insert_sql ~or_ignore =
  Printf.sprintf
    "INSERT %s INTO themes (%s, css, checks_json) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
    (if or_ignore then "OR IGNORE" else "")
    columns

let insert_args (t : Theme_meta.t) ~css ~checks_json =
  let ground, ink, accent = t.swatches in
  Libsql.
    [|
      s t.id;
      s t.name;
      s t.author;
      opt t.author_url;
      s (Theme_meta.target_key t.target);
      s (Theme_meta.fonts_key t.fonts);
      s ground;
      s ink;
      s accent;
      s t.badge;
      s t.bg;
      s (Theme_meta.status_key t.status);
      opt css;
      opt checks_json;
    |]

let insert ?(or_ignore = false) db (t : Theme_meta.t) ~css ~checks_json =
  Libsql.run db (insert_sql ~or_ignore) (insert_args t ~css ~checks_json)

let list db =
  let> rows =
    Libsql.query db
      (Printf.sprintf
         "SELECT %s FROM themes ORDER BY CASE status WHEN 'official' THEN 0 WHEN 'approved' THEN 1 \
          ELSE 2 END, created_at, name"
         columns)
      [||]
  in
  return (rows |> Array.to_list |> List.filter_map meta_of_row)

let find db id =
  let> rows =
    Libsql.query db (Printf.sprintf "SELECT %s FROM themes WHERE id = ?" columns) [| Libsql.s id |]
  in
  return (if Array.length rows = 0 then None else meta_of_row rows.(0))

let stored_css db id =
  let> rows = Libsql.query db "SELECT css FROM themes WHERE id = ?" [| Libsql.s id |] in
  return (if Array.length rows = 0 then None else Libsql.text rows.(0) "css")

let stored_checks db id =
  let> rows = Libsql.query db "SELECT checks_json FROM themes WHERE id = ?" [| Libsql.s id |] in
  return (if Array.length rows = 0 then None else Libsql.text rows.(0) "checks_json")

let exists db id = Promise.map Option.is_some (find db id)

let count_where db status =
  let> rows =
    Libsql.query db "SELECT COUNT(*) AS n FROM themes WHERE status = ?" [| Libsql.s status |]
  in
  return (if Array.length rows = 0 then 0 else Option.value (Libsql.int rows.(0) "n") ~default:0)

let count db =
  let> rows = Libsql.query db "SELECT COUNT(*) AS n FROM themes" [||] in
  return (if Array.length rows = 0 then 0 else Option.value (Libsql.int rows.(0) "n") ~default:0)
