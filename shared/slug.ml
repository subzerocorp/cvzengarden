(** Renderer slugs for [data-rz-entry] and [data-rz-skill-group]. *)

let non_alnum = Js.Re.fromStringWithFlags "[^\\p{Alphabetic}\\p{N}]+" ~flags:"gu"
let edge_dashes = Js.Re.fromStringWithFlags "^-+|-+$" ~flags:"g"

let slugify input =
  input |> Js.String.toLowerCase
  |> Js.String.replaceByRe ~regexp:non_alnum ~replacement:"-"
  |> Js.String.replaceByRe ~regexp:edge_dashes ~replacement:""

type used = (string, unit) Hashtbl.t
(** Slugs already handed out in one document. *)

let fresh () : used = Hashtbl.create 32

let uniquify (used : used) base =
  if not (Hashtbl.mem used base) then (
    Hashtbl.add used base ();
    base)
  else
    let rec go n =
      let candidate = Printf.sprintf "%s-%d" base n in
      if Hashtbl.mem used candidate then go (n + 1)
      else (
        Hashtbl.add used candidate ();
        candidate)
    in
    go 2

let slug_or ~fallback input = match slugify input with "" -> fallback | slug -> slug

let entry_slug used ~primary ~start_year =
  let name = slug_or ~fallback:"entry" primary in
  let base =
    match start_year with Some year -> Printf.sprintf "%s-%04d" name year | None -> name
  in
  uniquify used base

let skill_slug used name = uniquify used (slug_or ~fallback:"skill" name)
