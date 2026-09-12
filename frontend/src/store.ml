(** Global chrome state: one place for signals, navigation and persistence. Reading is a
    Calculation; every [set_*] is the edge where Actions live. *)

open Rz_shared
open Solid

let storage_key_resume = "rz.resume"

(* ── Signals ─────────────────────────────────────────────────────────── *)

let initial = Route.parse ~pathname:(Web.pathname Web.location) ~search:(Web.search Web.location)
let page, set_page = signal initial.page
let theme_id, set_theme_id = signal (Option.value initial.theme ~default:Theme_meta.default_id)
let view, set_view = signal (Option.value initial.view ~default:View_mode.Paper)
let menu_open, set_menu_open = signal false
let themes, set_themes = signal ([] : Theme_meta.t list)
let sample_junior, set_sample_junior = signal ""
let sample_long, set_sample_long = signal ""

let resume_text, set_resume_text =
  signal (Option.value (Web.storage_get storage_key_resume) ~default:"")

let pages, set_pages = signal 1

(** The Workbench's stylesheet under test, when one is loaded. *)
let custom_css, set_custom_css = signal (None : string option)

(** The main preview frame's window, so "Save as PDF" prints the right sheet. *)
let print_target, set_print_target = signal (None : Web.window option)

(* ── Derived ─────────────────────────────────────────────────────────── *)

let officials () =
  List.filter (fun (t : Theme_meta.t) -> t.status = Theme_meta.Official) (themes ())

let community () =
  List.filter (fun (t : Theme_meta.t) -> t.status <> Theme_meta.Official) (themes ())

let find_theme id = List.find_opt (fun (t : Theme_meta.t) -> t.id = id) (themes ())

let selected_theme () =
  match find_theme (theme_id ()) with
  | Some t -> Some t
  | None -> Theme_meta.find_official (theme_id ())

(** The Author's résumé: last text, decoded. Empty text falls back to the sample so the Garden
    always has something to draw. *)
let resume_source () = match resume_text () with "" -> sample_junior () | text -> text

let resume = global_memo (fun () -> Resume.of_string (resume_source ()))
let last_good = ref None

(** The Skeleton for the current résumé; when the text is mid-edit and invalid, the last valid
    render stays on the sheet. *)
let article =
  global_memo (fun () ->
      match resume () with
      | Ok r ->
          let html = Skeleton.render_article r in
          last_good := Some html;
          html
      | Error _ -> Option.value !last_good ~default:"")

let long_article =
  global_memo (fun () ->
      match Resume.of_string (sample_long ()) with
      | Ok r -> Skeleton.render_article r
      | Error _ -> "")

let is_paper () = view () = View_mode.Paper

let pages_label () =
  if is_paper () then
    let n = pages () in
    Printf.sprintf "About %d page%s %s Letter" n (if n = 1 then "" else "s") {js|·|js}
  else {js|Screen view · web motion on|js}

(* ── Actions ─────────────────────────────────────────────────────────── *)

let url_state () = { Route.page = page (); theme = Some (theme_id ()); view = Some (view ()) }

let sync_url ~push =
  let url = Route.to_url (url_state ()) in
  if push then Web.push_url url else Web.replace_url url

let navigate target =
  batch (fun () ->
      set_page target;
      set_menu_open false);
  sync_url ~push:true;
  Web.scroll_to Web.window 0 0

let pick_theme id =
  set_theme_id id;
  sync_url ~push:false

let choose_view v =
  set_view v;
  sync_url ~push:false

let toggle_menu () = set_menu_open (not (menu_open ()))
let print_sheet () = Option.iter Web.print (print_target ())
let copy_link () = Web.clipboard_write (Web.href Web.location) |> ignore
let ( let> ) = Web.( let> )

let load_themes () =
  let> body = Web.get_text "/api/themes" in
  (match Option.bind body (fun b -> Result.to_option (Decode.parse_json b)) with
  | Some json -> (
      match Js.Json.decodeObject json with
      | Some o -> (
          match Option.map Theme_meta.list_of_json (Js.Dict.get o "themes") with
          | Some (Ok list) -> set_themes list
          | _ -> set_themes Theme_meta.officials)
      | None -> set_themes Theme_meta.officials)
  | None -> set_themes Theme_meta.officials);
  Js.Promise.resolve ()

let load_samples () =
  let> junior = Web.get_text "/api/samples/junior" in
  Option.iter set_sample_junior junior;
  let> long = Web.get_text "/api/samples/jordan" in
  Option.iter set_sample_long long;
  Js.Promise.resolve ()

let remember_resume text =
  if text = "" then Web.storage_remove storage_key_resume
  else Web.storage_set storage_key_resume text

let forget_resume () =
  Web.storage_remove storage_key_resume;
  set_resume_text ""

(** Back/forward: adopt the URL without pushing. *)
let on_popstate () =
  let s = Route.parse ~pathname:(Web.pathname Web.location) ~search:(Web.search Web.location) in
  batch (fun () ->
      set_page s.page;
      Option.iter set_theme_id s.theme;
      Option.iter set_view s.view)

let start () =
  Web.window_listener Web.window "popstate" (fun _ -> on_popstate ());
  Web.window_listener Web.window "keydown" (fun e ->
      if Web.key e = "Escape" then set_menu_open false);
  create_effect (fun () -> remember_resume (resume_text ()));
  load_themes () |> ignore;
  load_samples () |> ignore;
  sync_url ~push:false
