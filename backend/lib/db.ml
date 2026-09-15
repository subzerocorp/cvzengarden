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
  review_note   TEXT,
  reviewed_at   TEXT,
  created_at    TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at    TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);
CREATE INDEX IF NOT EXISTS themes_status ON themes (status, created_at);
|}

let connect ~url ?auth_token () = Libsql.connect ~url ?auth_token ()

(* Stores created before the review columns existed gain them here; the
   ALTERs fail harmlessly once the columns are present. *)
let add_column db column =
  Libsql.run db (Printf.sprintf "ALTER TABLE themes ADD COLUMN %s TEXT" column) [||]
  |> Promise.map (fun (_ : int) -> ())
  |> Js.Promise.catch (fun _ -> return ())

let migrate (db : t) =
  let> () = Libsql.execute_multiple db schema in
  let> () = add_column db "review_note" in
  add_column db "reviewed_at"

(* ── Row ↔ Theme_meta ─────────────────────────────────────────────────── *)

let ( let** ) = Option.bind

(** A stored row as a card, or [None] when any keyed column does not decode: a corrupt row must not
    be presented as a valid Theme. *)
let meta_of_row row : Theme_meta.t option =
  let open Libsql in
  let** id = text row "id" in
  let** name = text row "name" in
  let** author = text row "author" in
  let** target = Option.bind (text row "target") Theme_meta.target_of_key in
  let** fonts = Option.bind (text row "fonts") Theme_meta.fonts_of_key in
  let** ground = text row "swatch_ground" in
  let** ink = text row "swatch_ink" in
  let** accent = text row "swatch_accent" in
  let** badge = text row "badge" in
  let** bg = text row "bg" in
  let** status = Option.bind (text row "status") Theme_meta.status_of_key in
  Some
    {
      Theme_meta.id;
      name;
      author;
      author_url = text row "author_url";
      target;
      fonts;
      swatches = (ground, ink, accent);
      badge;
      bg;
      status;
    }

let columns =
  "id, name, author, author_url, target, fonts, swatch_ground, swatch_ink, swatch_accent, badge, \
   bg, status"

type insert_conflict = Fail | Ignore

let insert_sql = function
  | Fail ->
      Printf.sprintf
        "INSERT INTO themes (%s, css, checks_json) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, \
         ?)"
        columns
  | Ignore ->
      Printf.sprintf
        "INSERT OR IGNORE INTO themes (%s, css, checks_json) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, \
         ?, ?, ?, ?)"
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

let insert ~conflict db (t : Theme_meta.t) ~css ~checks_json =
  Libsql.run db (insert_sql conflict) (insert_args t ~css ~checks_json)

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

type review = {
  checks_json : string option;
  review_note : string option;
  reviewed_at : string option;
}
(** What a reviewer sees beyond the card: the checks and the last note. *)

let review db id =
  let> rows =
    Libsql.query db "SELECT checks_json, review_note, reviewed_at FROM themes WHERE id = ?"
      [| Libsql.s id |]
  in
  return
    (if Array.length rows = 0 then None
     else
       let row = rows.(0) in
       Some
         {
           checks_json = Libsql.text row "checks_json";
           review_note = Libsql.text row "review_note";
           reviewed_at = Libsql.text row "reviewed_at";
         })

(** Move a Submission through review. Only rows that are not first-party can change status; returns
    whether a row changed. *)
let set_status db id (status : Theme_meta.status) ~note =
  let> n =
    Libsql.run db
      "UPDATE themes SET status = ?, review_note = ?, reviewed_at = strftime('%Y-%m-%dT%H:%M:%fZ', \
       'now'), updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now') WHERE id = ? AND status <> \
       'official'"
      [| Libsql.s (Theme_meta.status_key status); Libsql.opt note; Libsql.s id |]
  in
  return (n > 0)

let exists db id = Promise.map Option.is_some (find db id)

let count_where db status =
  let> rows =
    Libsql.query db "SELECT COUNT(*) AS n FROM themes WHERE status = ?" [| Libsql.s status |]
  in
  return (if Array.length rows = 0 then 0 else Option.value (Libsql.int rows.(0) "n") ~default:0)

let count db =
  let> rows = Libsql.query db "SELECT COUNT(*) AS n FROM themes" [||] in
  return (if Array.length rows = 0 then 0 else Option.value (Libsql.int rows.(0) "n") ~default:0)
