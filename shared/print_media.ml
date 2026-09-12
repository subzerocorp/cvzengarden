(** Honest print-media emulation for the Paper view. The Theme's own [@media print] rules are
    unwrapped, its [@media screen] rules dropped, and its [@page] box (size, margin) is read so the
    chrome can draw the sheet the browser would print. Nothing here restyles an [rz-*] node. *)

type size = Letter | A4 | Legal

type page_box = {
  size : size;
  margin : string;  (** CSS shorthand as written in [@page], or the UA default *)
}

let default_margin = "0.5in"
let default_page = { size = Letter; margin = default_margin }
let sheet_width = function Letter | Legal -> "8.5in" | A4 -> "210mm"
let sheet_height = function Letter -> "11in" | Legal -> "14in" | A4 -> "297mm"

(** Page height in CSS pixels at 96dpi, for page-count estimates. *)
let sheet_height_px = function Letter -> 1056 | Legal -> 1344 | A4 -> 1123

let lower = Js.String.toLowerCase
let includes needle s = Js.String.includes ~search:needle s

(* ── Brace matching ─────────────────────────────────────────────────── *)

(** Index of the [}] closing the block opened at [open_idx], or the end. *)
let matching_close css open_idx =
  let n = String.length css in
  let rec go i depth =
    if i >= n then n
    else
      match css.[i] with
      | '{' -> go (i + 1) (depth + 1)
      | '}' -> if depth = 1 then i else go (i + 1) (depth - 1)
      | _ -> go (i + 1) depth
  in
  go open_idx 0

(** How an [@media] query behaves when the medium is print. *)
type media_fate =
  | Unwrap  (** matches print: its rules apply unconditionally *)
  | Drop  (** screen-only: gone on paper *)
  | Keep  (** feature queries such as reduced motion: left as written *)

let media_fate prelude =
  let q = lower prelude in
  if includes "not print" q || includes "not all" q then Drop
  else if includes "print" q then Unwrap
  else if includes "screen" q then Drop
  else Keep

(** The stylesheet as print media would apply it. *)
let emulate css =
  let n = String.length css in
  let out = Buffer.create n in
  let rec go i =
    if i < n then
      if css.[i] = '@' then (
        let brace = Js.String.indexOf ~search:"{" ~start:i css in
        let semi = Js.String.indexOf ~search:";" ~start:i css in
        if brace < 0 || (semi >= 0 && semi < brace) then (
          (* a statement at-rule: @import, @charset *)
          let stop = if semi < 0 then n else semi + 1 in
          Buffer.add_string out (Js.String.slice ~start:i ~end_:stop css);
          go stop)
        else
          let close = matching_close css brace in
          let prelude = Js.String.trim (Js.String.slice ~start:i ~end_:brace css) in
          let stop = min n (close + 1) in
          if Js.String.startsWith ~prefix:"@media" prelude then
            match media_fate (Js.String.slice ~start:6 prelude) with
            | Unwrap -> Buffer.add_string out (Js.String.slice ~start:(brace + 1) ~end_:close css)
            | Drop -> ()
            | Keep -> Buffer.add_string out (Js.String.slice ~start:i ~end_:stop css)
          else Buffer.add_string out (Js.String.slice ~start:i ~end_:stop css);
          go stop)
      else if css.[i] = '{' then (
        (* a plain rule: copy it whole so an inner '@' is never re-read *)
        let close = matching_close css i in
        let stop = min n (close + 1) in
        Buffer.add_string out (Js.String.slice ~start:i ~end_:stop css);
        go stop)
      else (
        Buffer.add_char out css.[i];
        go (i + 1))
  in
  go 0;
  Buffer.contents out

(* ── The page box ───────────────────────────────────────────────────── *)

let page_rule = Js.Re.fromStringWithFlags "@page\\b[^{]*\\{([^}]*)\\}" ~flags:"g"
let size_decl = Js.Re.fromStringWithFlags "(?:^|[\\s;{])size\\s*:\\s*([^;}]+)" ~flags:"i"
let margin_decl = Js.Re.fromStringWithFlags "(?:^|[\\s;{])margin\\s*:\\s*([^;}]+)" ~flags:"i"

let capture re body =
  Option.bind (Js.Re.exec ~str:body re) (fun r ->
      match Js.Re.captures r with
      | [| _; v |] -> Option.map Js.String.trim (Js.Nullable.toOption v)
      | _ -> None)

let size_of_value v =
  let v = lower v in
  if includes "a4" v then Some A4
  else if includes "legal" v then Some Legal
  else if includes "letter" v then Some Letter
  else None

(** The last [@page] block wins, as it would in the cascade. *)
let page_box css =
  let css = Theme_lint.strip_comments css in
  let rec go acc =
    match Js.Re.exec ~str:css page_rule with
    | None -> acc
    | Some r -> (
        match Js.Re.captures r with
        | [| _; body |] ->
            let body = Option.value (Js.Nullable.toOption body) ~default:"" in
            let size =
              Option.value (Option.bind (capture size_decl body) size_of_value) ~default:acc.size
            in
            let margin = Option.value (capture margin_decl body) ~default:acc.margin in
            go { size; margin }
        | _ -> go acc)
  in
  Js.Re.setLastIndex page_rule 0;
  go default_page
