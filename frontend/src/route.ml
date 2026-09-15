(** Routes and the URL state the chrome keeps shareable: the page, the staged Theme and the view.
    Pure; the History API lives in [Store]. *)

open Rz_shared

type page = Garden | Gallery | About | Studio | Workbench | Admin

let all = [ Garden; Gallery; About; Studio; Workbench; Admin ]

let path = function
  | Garden -> "/"
  | Gallery -> "/gallery"
  | About -> "/about"
  | Studio -> "/studio"
  | Workbench -> "/workbench"
  | Admin -> "/admin"

let label = function
  | Garden -> "Garden"
  | Gallery -> "Gallery"
  | About -> "About"
  | Studio -> "Studio"
  | Workbench -> "Workbench"
  | Admin -> "Review queue"

let of_path pathname =
  let trimmed =
    if String.length pathname > 1 && Js.String.endsWith ~suffix:"/" pathname then
      Js.String.slice ~start:0 ~end_:(String.length pathname - 1) pathname
    else pathname
  in
  List.find_opt (fun page -> path page = trimmed) all

(** Fixed-height routes never scroll the page; the others do. *)
let is_fixed = function Garden | Studio | Workbench -> true | Gallery | About | Admin -> false

let is_authoring = function Studio | Workbench -> true | _ -> false

type state = { page : page; theme : string option; view : View_mode.t option }

let query_pairs search =
  let raw =
    if Js.String.startsWith ~prefix:"?" search then Js.String.slice ~start:1 search else search
  in
  Js.String.split ~sep:"&" raw |> Array.to_list
  |> List.filter_map (fun pair ->
      match Js.String.split ~sep:"=" pair |> Array.to_list with
      | [ k; v ] when k <> "" ->
          Some (Js.Global.decodeURIComponent k, Js.Global.decodeURIComponent v)
      | [ k ] when k <> "" -> Some (Js.Global.decodeURIComponent k, "")
      | _ -> None)

let parse ~pathname ~search =
  let pairs = query_pairs search in
  {
    page = Option.value (of_path pathname) ~default:Garden;
    theme = List.assoc_opt "theme" pairs;
    view = Option.bind (List.assoc_opt "view" pairs) View_mode.of_key;
  }

let to_url { page; theme; view } =
  let query =
    List.filter_map Fun.id
      [
        Option.map (fun t -> "theme=" ^ Js.Global.encodeURIComponent t) theme;
        Option.map (fun v -> "view=" ^ View_mode.to_key v) view;
      ]
  in
  match query with [] -> path page | q -> path page ^ "?" ^ String.concat "&" q
