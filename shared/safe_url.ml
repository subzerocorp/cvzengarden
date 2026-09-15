(** Safe hrefs (CLASS-CONTRACT §5.2). Only [http(s)] with a host, [mailto:] / [tel:] with a body, or
    a bare host (prefixed with [https://]) become links. *)

let strip_http_scheme url =
  if Js.String.startsWith ~prefix:"https://" url then Some (Js.String.slice ~start:8 url)
  else if Js.String.startsWith ~prefix:"http://" url then Some (Js.String.slice ~start:7 url)
  else None

let host_end = Js.Re.fromString "[/?#]"

let hostname url =
  let url = Js.String.trim url in
  let rest = Option.value (strip_http_scheme url) ~default:url in
  match Js.String.splitByRe ~regexp:host_end rest with
  | [||] -> rest
  | parts -> Option.value parts.(0) ~default:""

let has_host rest = hostname rest <> ""

let has_body url scheme =
  Js.String.startsWith ~prefix:scheme url
  && Js.String.trim (Js.String.slice ~start:(String.length scheme) url) <> ""

let scheme_shaped = Js.Re.fromString "^[A-Za-z][A-Za-z0-9+.-]*:"
let has_scheme url = Js.Re.test ~str:url scheme_shaped

let safe_href raw =
  let url = Js.String.trim raw in
  match strip_http_scheme url with
  | Some rest -> if has_host rest then Some url else None
  | None ->
      if has_body url "mailto:" || has_body url "tel:" then Some url
      else if has_scheme url then None
      else
        let bare =
          if Js.String.startsWith ~prefix:"//" url then Js.String.slice ~start:2 url else url
        in
        if has_host bare then Some ("https://" ^ bare) else None
