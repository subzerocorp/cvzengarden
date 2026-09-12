val strip_http_scheme : Js.String.t -> Js.String.t option
val host_end : Js.Re.t
val hostname : Js.String.t -> Js.String.t
val has_host : Js.String.t -> bool
val has_body : Js.String.t -> Js.String.t -> bool
val scheme_shaped : Js.Re.t
val has_scheme : string -> bool
val safe_href : Js.String.t -> Js.String.t option
