(** Contract diagnostics for a Theme stylesheet (CLASS-CONTRACT §1–2). Pure text analysis; the one
    check that needs a layout engine (page count) is reported as [Pending] and measured by the
    Workbench. *)

type status = Pass | Warn | Fail | Pending
type check = { id : string; title : string; note : string; status : status }

let status_key = function Pass -> "pass" | Warn -> "warn" | Fail -> "fail" | Pending -> "pending"

let status_of_key = function
  | "pass" -> Some Pass
  | "warn" -> Some Warn
  | "fail" -> Some Fail
  | "pending" -> Some Pending
  | _ -> None

let re ?(flags = "") pattern = Js.Re.fromStringWithFlags pattern ~flags
let test pattern s = Js.Re.test ~str:s pattern
let replace pattern replacement s = Js.String.replaceByRe ~regexp:pattern ~replacement s
let comments = re ~flags:"g" "/\\*[\\s\\S]*?\\*/"
let strings = re ~flags:"g" "\"(?:[^\"\\\\]|\\\\.)*\"|'(?:[^'\\\\]|\\\\.)*'"
let strip_comments css = replace comments "" css
let strip_strings css = replace strings "\"\"" css

(* ── Selector extraction ───────────────────────────────────────────────── *)

(* Where a prelude sits: a style rule (nested preludes are selectors too), a
   conditional group such as "@media" / "@supports" (preludes inside are
   selectors), or an opaque block such as "@keyframes" / "@font-face" /
   "@page" (nothing inside is a selector). *)
type context = Rule | Conditional | Opaque

let conditional_at_rules = [ "@media"; "@supports"; "@container"; "@layer"; "@scope"; "@document" ]
let starts_with_any prefixes s = List.exists (fun p -> Js.String.startsWith ~prefix:p s) prefixes

let classify_prelude stack prelude =
  if Js.String.startsWith ~prefix:"@" prelude then
    if starts_with_any conditional_at_rules prelude then (Conditional, None) else (Opaque, None)
  else match stack with Opaque :: _ -> (Opaque, None) | _ -> (Rule, Some prelude)

(** Every selector list ("prelude") of a style rule, in source order. *)
let preludes css =
  let css = strip_strings (strip_comments css) in
  let buf = Buffer.create 128 in
  let found = ref [] in
  let stack = ref [] in
  String.iter
    (fun c ->
      match c with
      | '{' ->
          let prelude = Js.String.trim (Buffer.contents buf) in
          Buffer.clear buf;
          let context, selector = classify_prelude !stack prelude in
          Option.iter (fun s -> found := s :: !found) selector;
          stack := context :: !stack
      | '}' -> (
          Buffer.clear buf;
          stack := match !stack with _ :: rest -> rest | [] -> [])
      | ';' -> Buffer.clear buf
      | c -> Buffer.add_char buf c)
    css;
  List.rev !found

(** Split a selector list on top-level commas (not the ones inside [:is()]). *)
let split_selectors prelude =
  let parts = ref [] and buf = Buffer.create 64 and depth = ref 0 in
  String.iter
    (fun c ->
      match c with
      | '(' | '[' ->
          incr depth;
          Buffer.add_char buf c
      | ')' | ']' ->
          decr depth;
          Buffer.add_char buf c
      | ',' when !depth = 0 ->
          parts := Buffer.contents buf :: !parts;
          Buffer.clear buf
      | c -> Buffer.add_char buf c)
    prelude;
  parts := Buffer.contents buf :: !parts;
  !parts |> List.rev_map Js.String.trim |> List.filter (fun s -> s <> "")

let combinators = re "[\\s>+~]+"
let pseudo_tail = re "::?[a-zA-Z-]+(\\([^)]*\\))?"

(** A compound that is the résumé document itself, not a node in it. *)
let is_document_compound compound =
  let base = replace (re ~flags:"g" "::?[a-zA-Z-]+(\\([^)]*\\))?") "" compound in
  List.mem base [ ""; "html"; "body"; "*"; ":root" ]

let is_contract_selector selector =
  Js.String.includes ~search:".rz-" selector
  || Js.String.includes ~search:"[data-rz-" selector
  ||
  let compounds =
    Js.String.splitByRe ~regexp:combinators selector
    |> Array.to_list |> List.filter_map Fun.id
    |> List.filter (fun s -> s <> "")
  in
  compounds <> [] && List.for_all is_document_compound compounds

let offending_selectors css =
  preludes css |> List.concat_map split_selectors
  |> List.filter (fun s -> not (is_contract_selector s))

let quote_list items =
  items
  |> List.filteri (fun i _ -> i < 3)
  |> List.map (fun s -> "`" ^ s ^ "`")
  |> String.concat ", "

let check_scope css =
  match offending_selectors css with
  | [] ->
      {
        id = "scope";
        title = "Targets rz-* only";
        note = "No chrome selectors, no bare tags beyond html/body";
        status = Pass;
      }
  | bad ->
      let more =
        if List.length bad > 3 then Printf.sprintf " and %d more" (List.length bad - 3) else ""
      in
      {
        id = "scope";
        title = "Targets rz-* only";
        note = "Outside the contract: " ^ quote_list bad ^ more;
        status = Fail;
      }

(* ── Header ─────────────────────────────────────────────────────────────── *)

let header_re = re "^\\s*/\\*\\s*rz-target:\\s*(web|print|both)\\s*\\*/"
let anywhere_re = re "/\\*\\s*rz-target:\\s*(web|print|both)\\s*\\*/"

let declared_target css =
  Option.bind (Js.Re.exec ~str:css anywhere_re) (fun result ->
      match Js.Re.captures result with [| _; target |] -> Js.Nullable.toOption target | _ -> None)

let check_header css =
  let title = "rz-target header present" in
  if test header_re css then
    {
      id = "header";
      title;
      note =
        Printf.sprintf "/* rz-target: %s */ on line 1"
          (Option.value (declared_target css) ~default:"");
      status = Pass;
    }
  else
    match declared_target css with
    | Some target ->
        {
          id = "header";
          title;
          note = Printf.sprintf "/* rz-target: %s */ found, but not on line 1" target;
          status = Warn;
        }
    | None ->
        {
          id = "header";
          title;
          note = "Add /* rz-target: web | print | both */ as the first line";
          status = Fail;
        }

(* ── No JavaScript, no HTML ─────────────────────────────────────────────── *)

let forbidden =
  [
    ("<script", "a <script> tag");
    ("</", "an HTML closing tag");
    ("javascript:", "a javascript: URL");
    ("expression(", "an expression() call");
    ("-moz-binding", "-moz-binding");
    ("behavior:", "a behavior: binding");
  ]

let check_pure_css css =
  let haystack = Js.String.toLowerCase (strip_comments css) in
  let compact = replace (re ~flags:"g" "\\s+") "" haystack in
  let hit =
    List.find_opt (fun (needle, _) -> Js.String.includes ~search:needle compact) forbidden
  in
  match hit with
  | None ->
      {
        id = "pure";
        title = "No JavaScript, no extra HTML";
        note = "One file, pure CSS";
        status = Pass;
      }
  | Some (_, what) ->
      { id = "pure"; title = "No JavaScript, no extra HTML"; note = "Found " ^ what; status = Fail }

(* ── Fonts ──────────────────────────────────────────────────────────────── *)

let url_re = re ~flags:"g" "url\\(\\s*['\"]?([^'\")]+)['\"]?\\s*\\)|@import\\s+['\"]([^'\"]+)['\"]"

let external_urls css =
  let css = strip_comments css in
  let rec go acc =
    match Js.Re.exec ~str:css url_re with
    | None -> List.rev acc
    | Some result ->
        let caps = Js.Re.captures result in
        let pick i = if i < Array.length caps then Js.Nullable.toOption caps.(i) else None in
        let url = match pick 1 with Some u -> Some u | None -> pick 2 in
        go (Option.fold ~none:acc ~some:(fun u -> Js.String.trim u :: acc) url)
  in
  Js.Re.setLastIndex url_re 0;
  go []

type source = Https of string | Library | Data | Insecure of string | Other_relative of string

let classify_url url =
  if Js.String.startsWith ~prefix:"https://" url then Https (Safe_url.hostname url)
  else if Js.String.startsWith ~prefix:"http://" url || Js.String.startsWith ~prefix:"//" url then
    Insecure url
  else if Js.String.startsWith ~prefix:"data:" url then Data
  else if Js.String.startsWith ~prefix:"fonts/" url || Js.String.startsWith ~prefix:"/fonts/" url
  then Library
  else Other_relative url

let unique xs = List.fold_left (fun acc x -> if List.mem x acc then acc else acc @ [ x ]) [] xs

let check_fonts css =
  let title = "Fonts from Library or HTTPS" in
  let sources = List.map classify_url (external_urls css) in
  let insecure = List.filter_map (function Insecure u -> Some u | _ -> None) sources in
  let hosts = unique (List.filter_map (function Https h -> Some h | _ -> None) sources) in
  let library = List.exists (function Library -> true | _ -> false) sources in
  let data = List.exists (function Data -> true | _ -> false) sources in
  let stray = List.filter_map (function Other_relative u -> Some u | _ -> None) sources in
  if insecure <> [] then
    { id = "fonts"; title; note = "Insecure URL: " ^ quote_list insecure; status = Fail }
  else if stray <> [] then
    {
      id = "fonts";
      title;
      note = "Relative URL outside fonts/: " ^ quote_list stray;
      status = Warn;
    }
  else if data then
    {
      id = "fonts";
      title;
      note = {js|Inline data: URI — prefer the Font Library|js};
      status = Warn;
    }
  else
    let parts =
      (if library then [ "Self-hosted from fonts/ (Library)" ] else [])
      @ List.map (fun h -> {js|@font-face → |js} ^ h) hosts
    in
    {
      id = "fonts";
      title;
      note =
        (match parts with
        | [] -> "No external resources"
        | parts -> String.concat {js| · |js} parts);
      status = Pass;
    }

(* ── Print pages (measured elsewhere) ───────────────────────────────────── *)

let page_limit = 3

let pages_pending =
  {
    id = "pages";
    title = {js|Long fixture prints in ≤ |js} ^ string_of_int page_limit ^ " pages";
    note = "Measured in the Workbench on the long fixture";
    status = Pending;
  }

(** The Workbench swaps in the measured result. *)
let pages_measured n =
  if n <= page_limit then
    {
      id = "pages";
      title = Printf.sprintf "Long fixture prints in %d page%s" n (if n = 1 then "" else "s");
      note = "Limit is " ^ string_of_int page_limit ^ {js| · Letter|js};
      status = Pass;
    }
  else
    {
      id = "pages";
      title = Printf.sprintf "Long fixture prints in %d pages" n;
      note = "Limit is " ^ string_of_int page_limit ^ {js| — tighten .rz-entry margins|js};
      status = Warn;
    }

(* ── Motion ─────────────────────────────────────────────────────────────── *)

let motion_re =
  re ~flags:"i"
    "(?:^|[\\s;{])(?:animation|transition)(?:-name|-duration)?\\s*:\\s*(?!none\\b|0s\\b)"

let declares_motion css =
  let css = strip_comments css in
  test motion_re css || Js.String.includes ~search:"@keyframes" css

let check_motion css =
  let title = "Reduced motion honoured" in
  if not (declares_motion css) then
    { id = "motion"; title; note = "No motion declared"; status = Pass }
  else if Js.String.includes ~search:"prefers-reduced-motion" css then
    { id = "motion"; title; note = "prefers-reduced-motion block found"; status = Pass }
  else
    {
      id = "motion";
      title;
      note = "Animates without a prefers-reduced-motion block";
      status = Warn;
    }

(* ── Report ─────────────────────────────────────────────────────────────── *)

let run css =
  [
    check_scope css;
    check_header css;
    check_pure_css css;
    check_fonts css;
    pages_pending;
    check_motion css;
  ]

let with_pages n checks = List.map (fun c -> if c.id = "pages" then pages_measured n else c) checks
let passing checks = List.length (List.filter (fun c -> c.status = Pass) checks)
let blocking checks = List.exists (fun c -> c.status = Fail) checks

let to_json check =
  Js.Json.object_
    (Js.Dict.fromList
       [
         ("id", Js.Json.string check.id);
         ("title", Js.Json.string check.title);
         ("note", Js.Json.string check.note);
         ("status", Js.Json.string (status_key check.status));
       ])

let list_to_json checks = Js.Json.array (Array.of_list (List.map to_json checks))
let ( let* ) = Result.bind

let decode : check Decode.t =
  Decode.obj (fun ~path o ->
      let get name = Theme_meta.required name Decode.string ~path o in
      let* id = get "id" in
      let* title = get "title" in
      let* note = get "note" in
      let* status = Theme_meta.keyed "status" status_of_key ~path o in
      Ok { id; title; note; status })
