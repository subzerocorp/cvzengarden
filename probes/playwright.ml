(** Playwright bindings — the slice the probes drive. Everything is a promise; the locator API
    replaces [page.evaluate] so no JavaScript source ever passes through the probes. *)

type browser_type
type browser
type page
type locator
type frame_locator
type route
type console_message
type page_error
type dialog

external chromium : browser_type = "chromium" [@@mel.module "playwright"]
external launch : browser_type -> browser Js.Promise.t = "launch" [@@mel.send]
external close : browser -> unit Js.Promise.t = "close" [@@mel.send]

type viewport = { width : int; height : int }
type page_options = { viewport : viewport }

external new_page : browser -> page_options -> page Js.Promise.t = "newPage" [@@mel.send]

type goto_options = { waitUntil : string }

external goto : page -> string -> goto_options -> 'response Js.nullable Js.Promise.t = "goto"
[@@mel.send]

external route : page -> Js.Re.t -> (route -> unit) -> unit Js.Promise.t = "route" [@@mel.send]
external abort : route -> unit Js.Promise.t = "abort" [@@mel.send]
external wait_for_timeout : page -> int -> unit Js.Promise.t = "waitForTimeout" [@@mel.send]
external url : page -> string = "url" [@@mel.send]
external set_viewport_size : page -> viewport -> unit Js.Promise.t = "setViewportSize" [@@mel.send]
external press : page -> string -> unit Js.Promise.t = "press" [@@mel.send] [@@mel.scope "keyboard"]

type screenshot_options = { path : string; fullPage : bool }

external screenshot : page -> screenshot_options -> 'buffer Js.Promise.t = "screenshot" [@@mel.send]

(* ── Locators ─────────────────────────────────────────────────────────── *)

external locator : page -> string -> locator = "locator" [@@mel.send]
external frame_locator : page -> string -> frame_locator = "frameLocator" [@@mel.send]
external in_frame : frame_locator -> string -> locator = "locator" [@@mel.send]
external first : locator -> locator = "first" [@@mel.send]
external nth : locator -> int -> locator = "nth" [@@mel.send]
external count : locator -> int Js.Promise.t = "count" [@@mel.send]
external text_content : locator -> string Js.nullable Js.Promise.t = "textContent" [@@mel.send]

external get_attribute : locator -> string -> string Js.nullable Js.Promise.t = "getAttribute"
[@@mel.send]

external click : locator -> unit Js.Promise.t = "click" [@@mel.send]
external fill : locator -> string -> unit Js.Promise.t = "fill" [@@mel.send]
external is_visible : locator -> bool Js.Promise.t = "isVisible" [@@mel.send]

type box = { x : float; y : float; width : float; height : float }

external bounding_box : locator -> box Js.nullable Js.Promise.t = "boundingBox" [@@mel.send]

(* ── Events ───────────────────────────────────────────────────────────── *)

external on_console : page -> (_[@mel.as "console"]) -> (console_message -> unit) -> unit = "on"
[@@mel.send]

external on_page_error : page -> (_[@mel.as "pageerror"]) -> (page_error -> unit) -> unit = "on"
[@@mel.send]

external on_dialog : page -> (_[@mel.as "dialog"]) -> (dialog -> unit) -> unit = "on" [@@mel.send]
external message_type : console_message -> string = "type" [@@mel.send]
external message_text : console_message -> string = "text" [@@mel.send]
external error_message : page_error -> string = "message" [@@mel.get]
external dialog_accept : dialog -> string -> unit Js.Promise.t = "accept" [@@mel.send]

(* ── Sugar ────────────────────────────────────────────────────────────── *)

let ( let> ) promise f = Js.Promise.then_ f promise
let return = Js.Promise.resolve

let text loc =
  Js.Promise.then_
    (fun t -> return (Option.value (Js.Nullable.toOption t) ~default:""))
    (text_content loc)

let attribute loc name =
  Js.Promise.then_ (fun t -> return (Js.Nullable.toOption t)) (get_attribute loc name)

let visit page url_ =
  let> _ = goto page url_ { waitUntil = "domcontentloaded" } in
  wait_for_timeout page 700
