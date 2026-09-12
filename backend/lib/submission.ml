(** A Theme offered to the Garden: decoded from the request body, validated, linted, and turned into
    a Theme_meta row awaiting review. *)

open Rz_shared

type t = {
  name : string;
  author : string;
  author_url : string option;
  target : Theme_meta.target;
  fonts : Theme_meta.fonts;
  css : string;
  swatches : (string * string * string) option;
  measured_pages : int option;  (** the Workbench's Letter page count on the long fixture *)
}

let ( let* ) = Result.bind
let max_css_bytes = 512 * 1024
let field_error path message = Error { Decode.path; message }

let trimmed_string name ~min ~max ~path o =
  let* v = Theme_meta.required name Decode.string ~path o in
  let v = Js.String.trim v in
  let n = String.length v in
  if n < min then
    field_error name
      (Printf.sprintf "must be at least %d character%s" min (if min = 1 then "" else "s"))
  else if n > max then field_error name (Printf.sprintf "must be at most %d characters" max)
  else Ok v

let decode : t Decode.t =
  Decode.obj (fun ~path o ->
      let* name = trimmed_string "name" ~min:1 ~max:60 ~path o in
      let* author = trimmed_string "author" ~min:1 ~max:80 ~path o in
      let* author_url = Decode.field "authorUrl" Decode.string ~path o in
      let author_url = Option.bind author_url Safe_url.safe_href in
      let* target = Theme_meta.keyed "target" Theme_meta.target_of_key ~path o in
      let* fonts = Theme_meta.keyed "fonts" Theme_meta.fonts_of_key ~path o in
      let* css = Theme_meta.required "css" Decode.string ~path o in
      let* css =
        if Js.String.trim css = "" then field_error "css" "is empty"
        else if String.length css > max_css_bytes then field_error "css" "is larger than 512 KiB"
        else Ok css
      in
      let* swatches = Decode.field_list "swatches" Decode.string ~path o in
      let swatches = match swatches with [ g; i; a ] -> Some (g, i, a) | _ -> None in
      let* measured_pages = Decode.field "measuredPages" Decode.number ~path o in
      let measured_pages = Option.map int_of_float measured_pages in
      Ok { name; author; author_url; target; fonts; css; swatches; measured_pages })

(* ── Swatches: the first three distinct colours a stylesheet paints ────── *)

let hex_colour = Js.Re.fromStringWithFlags "#(?:[0-9a-fA-F]{3}){1,2}\\b" ~flags:"g"

let colours css =
  let rec go acc =
    match Js.Re.exec ~str:css hex_colour with
    | None -> List.rev acc
    | Some r -> (
        match Js.Nullable.toOption (Js.Re.captures r).(0) with
        | Some c when not (List.mem (Js.String.toLowerCase c) acc) ->
            go (Js.String.toLowerCase c :: acc)
        | _ -> go acc)
  in
  Js.Re.setLastIndex hex_colour 0;
  go []

let swatches_of_css css =
  match colours (Theme_lint.strip_comments css) with
  | g :: i :: a :: _ -> (g, i, a)
  | [ g; i ] -> (g, i, i)
  | [ g ] -> (g, "#201e1d", "#c67139")
  | [] -> ("#f5ead8", "#201e1d", "#c67139")

let badge_for = function
  | Theme_meta.Screen -> "#2563eb"
  | Theme_meta.Paper -> "#d97706"
  | Theme_meta.Both -> "#16a34a"

(* ── Ids ─────────────────────────────────────────────────────────────── *)

let base_id name = Slug.slug_or ~fallback:"theme" name
let is_taken taken id = List.mem id taken

(** [slug], then [slug-2], [slug-3] … past ids already in the store. *)
let fresh_id ~taken name =
  let base = base_id name in
  if not (is_taken taken base) then base
  else
    let rec go n =
      let candidate = Printf.sprintf "%s-%d" base n in
      if is_taken taken candidate then go (n + 1) else candidate
    in
    go 2

let to_meta ~id t : Theme_meta.t =
  let swatches = Option.value t.swatches ~default:(swatches_of_css t.css) in
  let g, _, _ = swatches in
  {
    id;
    name = t.name;
    author = t.author;
    author_url = t.author_url;
    target = t.target;
    fonts = t.fonts;
    swatches;
    badge = badge_for t.target;
    bg = g;
    status = Theme_meta.In_review;
  }
