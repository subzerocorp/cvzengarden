(** Playwright bindings — the slice the probes drive. *)

type browser_type
(** [browser_type] is a Playwright browser engine. *)

type browser
(** [browser] is a launched browser. *)

type page
(** [page] is a tab. *)

type locator
(** [locator] is a Playwright locator. *)

type frame_locator
(** [frame_locator] is a framed locator. *)

type route
(** [route] is a request intercept. *)

type console_message
(** [console_message] is a console event. *)

type page_error
(** [page_error] is an uncaught page exception. *)

type dialog
(** [dialog] is an alert/prompt. *)

type response
(** [response] is a network response. *)

type request
(** [request] is a network request. *)

type frame
(** [frame] is a browsing frame. *)

type buffer
(** [buffer] is a binary payload. *)

type viewport = { width : int; height : int }
(** [viewport] is a window size. *)

type page_options = { viewport : viewport }
(** [page_options] is [new_page] configuration. *)

type goto_options = { waitUntil : string }
(** [goto_options] is navigation wait policy. *)

type screenshot_options = { path : string; fullPage : bool }
(** [screenshot_options] is a screenshot request. *)

type media_options = { media : string }
(** [media_options] is print/screen emulation. *)

type pdf_options = { format : string }
(** [pdf_options] is a PDF print request. *)

type box = { x : float; y : float; width : float; height : float }
(** [box] is a bounding box. *)

type expect_options = { timeout : int }
(** [expect_options] is a Playwright expectation timeout. *)

type console_location = { url : string }
(** [console_location] is where a console message originated. *)

val chromium : browser_type
(** [chromium] is the Chromium engine. *)

val launch : browser_type -> browser Js.Promise.t
(** [launch engine] starts a browser. *)

val close : browser -> unit Js.Promise.t
(** [close b] closes [b]. *)

val new_page : browser -> page_options -> page Js.Promise.t
(** [new_page b opts] opens a tab. *)

val response_status : response -> int
(** [response_status r] is the HTTP status. *)

val goto : page -> string -> goto_options -> response Js.nullable Js.Promise.t
(** [goto page url opts] navigates. *)

val route : page -> Js.Re.t -> (route -> unit) -> unit Js.Promise.t
(** [route page pattern f] intercepts matching requests. *)

val abort : route -> unit Js.Promise.t
(** [abort r] cancels the intercepted request. *)

val wait_for_timeout : page -> int -> unit Js.Promise.t
(** [wait_for_timeout page ms] waits [ms] milliseconds. *)

val url : page -> string
(** [url page] is the current URL. *)

val set_viewport_size : page -> viewport -> unit Js.Promise.t
(** [set_viewport_size page size] resizes the viewport. *)

val press : page -> string -> unit Js.Promise.t
(** [press page key] sends a key. *)

val screenshot : page -> screenshot_options -> buffer Js.Promise.t
(** [screenshot page opts] writes a PNG. *)

val emulate_media : page -> media_options -> unit Js.Promise.t
(** [emulate_media page opts] switches print/screen. *)

val pdf : page -> pdf_options -> buffer Js.Promise.t
(** [pdf page opts] prints a PDF. *)

val buffer_to_string : buffer -> string -> string
(** [buffer_to_string buf encoding] decodes [buf]. *)

val go_back : page -> response Js.nullable Js.Promise.t
(** [go_back page] goes back in history. *)

val locator : page -> string -> locator
(** [locator page sel] is a locator for [sel]. *)

val frame_locator : page -> string -> frame_locator
(** [frame_locator page sel] is a framed locator. *)

val in_frame : frame_locator -> string -> locator
(** [in_frame frame sel] is a locator inside [frame]. *)

val first : locator -> locator
(** [first loc] is the first match. *)

val nth : locator -> int -> locator
(** [nth loc i] is match [i]. *)

val count : locator -> int Js.Promise.t
(** [count loc] is how many nodes match. *)

val click : locator -> unit Js.Promise.t
(** [click loc] clicks. *)

val fill : locator -> string -> unit Js.Promise.t
(** [fill loc text] types [text]. *)

val bounding_box : locator -> box Js.nullable Js.Promise.t
(** [bounding_box loc] is the layout box. *)

val has_css : locator -> string -> Js.Re.t -> bool Js.Promise.t
(** [has_css loc name pattern] is whether the computed style matches now. *)

val eventually_css : ?ms:int -> locator -> string -> Js.Re.t -> bool Js.Promise.t
(** [eventually_css ?ms loc name pattern] waits for the computed style. *)

val on_request : page -> (request -> unit) -> unit
(** [on_request page f] listens for requests. *)

val request_url : request -> string
(** [request_url r] is the request URL. *)

val request_frame : request -> frame
(** [request_frame r] is the initiating frame. *)

val main_frame : page -> frame
(** [main_frame page] is the top frame. *)

val on_response : page -> (response -> unit) -> unit
(** [on_response page f] listens for responses. *)

val response_url : response -> string
(** [response_url r] is the response URL. *)

val on_console : page -> (console_message -> unit) -> unit
(** [on_console page f] listens for console messages. *)

val on_page_error : page -> (page_error -> unit) -> unit
(** [on_page_error page f] listens for page errors. *)

val on_dialog : page -> (dialog -> unit) -> unit
(** [on_dialog page f] listens for dialogs. *)

val message_type : console_message -> string
(** [message_type m] is the console level. *)

val message_text : console_message -> string
(** [message_text m] is the console text. *)

val message_location : console_message -> console_location
(** [message_location m] is the origin of [m]. *)

val error_message : page_error -> string
(** [error_message e] is the exception text. *)

val dialog_accept : dialog -> string -> unit Js.Promise.t
(** [dialog_accept d text] accepts a prompt with [text]. *)

val ( let> ) : 'a Js.Promise.t -> ('a -> 'b Js.Promise.t) -> 'b Js.Promise.t
(** [let> x = p in f x] is [Js.Promise.then_ f p]. *)

val return : 'a -> 'a Js.Promise.t
(** [return x] is a resolved promise of [x]. *)

val text : locator -> string Js.Promise.t
(** [text loc] is the text content, or [""]. *)

val attribute : locator -> string -> string option Js.Promise.t
(** [attribute loc name] is an attribute value. *)

val visit : page -> string -> unit Js.Promise.t
(** [visit page url] navigates and waits for paint. *)
