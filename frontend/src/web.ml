(** The browser surface the chrome touches. Every function here is an Action; the rest of the app
    stays a Calculation over signals. *)

type element
type document
type window
type event
type location
type history
type storage
type file_list

external document : document = "document"
external window : window = "window"
external location : location = "location"
external history : history = "history"

(* ── Elements ─────────────────────────────────────────────────────────── *)

external get_element_by_id : document -> string -> element Js.nullable = "getElementById"
[@@mel.send]

external query_selector : document -> string -> element Js.nullable = "querySelector" [@@mel.send]
external create_element : document -> string -> element = "createElement" [@@mel.send]
external document_element : document -> element = "documentElement" [@@mel.get]
external body : document -> element Js.nullable = "body" [@@mel.get]
external set_attribute : element -> string -> string -> unit = "setAttribute" [@@mel.send]
external set_text_content : element -> string -> unit = "textContent" [@@mel.set]
external set_inner_html : element -> string -> unit = "innerHTML" [@@mel.set]
external scroll_height : element -> int = "scrollHeight" [@@mel.get]
external click : element -> unit = "click" [@@mel.send]
external focus : element -> unit = "focus" [@@mel.send]
external value : element -> string = "value" [@@mel.get]
external set_value : element -> string -> unit = "value" [@@mel.set]
external checked : element -> bool = "checked" [@@mel.get]
external files : element -> file_list Js.nullable = "files" [@@mel.get]
external set_href : element -> string -> unit = "href" [@@mel.set]
external set_download : element -> string -> unit = "download" [@@mel.set]
external append_child : element -> element -> unit = "appendChild" [@@mel.send]
external remove : element -> unit = "remove" [@@mel.send]

external add_listener : element -> string -> (event -> unit) -> unit = "addEventListener"
[@@mel.send]

(* ── Iframes ──────────────────────────────────────────────────────────── *)

external content_document : element -> document Js.nullable = "contentDocument" [@@mel.get]
external content_window : element -> window Js.nullable = "contentWindow" [@@mel.get]
external print : window -> unit = "print" [@@mel.send]

(* ── Events ───────────────────────────────────────────────────────────── *)

external key : event -> string = "key" [@@mel.get]
external prevent_default : event -> unit = "preventDefault" [@@mel.send]
external target : event -> element = "target" [@@mel.get]
external current_target : event -> element = "currentTarget" [@@mel.get]

external data_transfer_files : event -> file_list Js.nullable = "files"
[@@mel.get] [@@mel.scope "dataTransfer"]

external file_item : file_list -> int -> Js.File.t Js.nullable = "item" [@@mel.send]

external window_listener : window -> string -> (event -> unit) -> unit = "addEventListener"
[@@mel.send]

external window_unlisten : window -> string -> (event -> unit) -> unit = "removeEventListener"
[@@mel.send]

external scroll_to : window -> int -> int -> unit = "scrollTo" [@@mel.send]
external open_ : window -> string -> string -> unit = "open" [@@mel.send]
external prompt : window -> string -> string -> string Js.nullable = "prompt" [@@mel.send]

external request_animation_frame : window -> (float -> unit) -> unit = "requestAnimationFrame"
[@@mel.send]

let first_file list =
  Option.bind (Js.Nullable.toOption list) (fun l -> Js.Nullable.toOption (file_item l 0))

(* ── Location & history ──────────────────────────────────────────────── *)

external pathname : location -> string = "pathname" [@@mel.get]
external search : location -> string = "search" [@@mel.get]
external href : location -> string = "href" [@@mel.get]

external push_state : history -> 'state Js.nullable -> string -> string -> unit = "pushState"
[@@mel.send]

external replace_state : history -> 'state Js.nullable -> string -> string -> unit = "replaceState"
[@@mel.send]

let push_url url = push_state history Js.Nullable.null "" url
let replace_url url = replace_state history Js.Nullable.null "" url

(* ── Storage (may throw in private windows; every call is guarded) ────── *)

external local_storage : storage = "localStorage"
external get_item : storage -> string -> string Js.nullable = "getItem" [@@mel.send]
external set_item : storage -> string -> string -> unit = "setItem" [@@mel.send]
external remove_item : storage -> string -> unit = "removeItem" [@@mel.send]

(* A private window or blocked site data makes the storage accessor throw a
   DOMException; that is the only failure these swallow. *)
let storage_get key =
  try Js.Nullable.toOption (get_item local_storage key) with Js.Exn.Error _ -> None

let storage_set key value = try set_item local_storage key value with Js.Exn.Error _ -> ()
let storage_remove key = try remove_item local_storage key with Js.Exn.Error _ -> ()

(* ── Fetch ────────────────────────────────────────────────────────────── *)

type response

type request_init = {
  method_ : string; [@mel.as "method"]
  headers : string Js.Dict.t;
  body : string;
}

external fetch : string -> response Js.Promise.t = "fetch"
external fetch_with : string -> request_init -> response Js.Promise.t = "fetch"
external ok : response -> bool = "ok" [@@mel.get]
external status : response -> int = "status" [@@mel.get]
external response_text : response -> string Js.Promise.t = "text" [@@mel.send]

let ( let> ) promise f = Js.Promise.then_ f promise

(** GET a text body; [None] on a non-2xx status or a network failure. *)
let get_text url : string option Js.Promise.t =
  fetch url
  |> Js.Promise.then_ (fun r ->
      if ok r then Js.Promise.then_ (fun t -> Js.Promise.resolve (Some t)) (response_text r)
      else Js.Promise.resolve None)
  |> Js.Promise.catch (fun _ -> Js.Promise.resolve None)

type bodiless_init = { method_ : string; [@mel.as "method"] headers : string Js.Dict.t }

external fetch_bodiless : string -> bodiless_init -> response Js.Promise.t = "fetch"

let status_and_text r =
  Js.Promise.then_ (fun t -> Js.Promise.resolve (status r, t)) (response_text r)

(** A request with explicit method and headers, and a body only when one is given (a GET with a body
    is rejected by [fetch]); resolves to the status and the response text, [(0, "")] on a network
    failure. *)
let request ~method_ ~headers ?body url : (int * string) Js.Promise.t =
  (match body with
    | Some body -> fetch_with url { method_; headers = Js.Dict.fromList headers; body }
    | None -> fetch_bodiless url { method_; headers = Js.Dict.fromList headers })
  |> Js.Promise.then_ status_and_text
  |> Js.Promise.catch (fun _ -> Js.Promise.resolve (0, ""))

(** POST a JSON body; resolves to the status and the response text. *)
let post_json url body : (int * string) Js.Promise.t =
  fetch_with url
    { method_ = "POST"; headers = Js.Dict.fromList [ ("Content-Type", "application/json") ]; body }
  |> Js.Promise.then_ (fun r ->
      Js.Promise.then_ (fun t -> Js.Promise.resolve (status r, t)) (response_text r))
  |> Js.Promise.catch (fun _ -> Js.Promise.resolve (0, ""))

(* ── Clipboard & downloads ───────────────────────────────────────────── *)

external clipboard_write : string -> unit Js.Promise.t = "writeText"
[@@mel.scope "navigator", "clipboard"]

type blob
type blob_options = { type_ : string [@mel.as "type"] }

external make_blob : string array -> blob_options -> blob = "Blob" [@@mel.new]
external create_object_url : blob -> string = "createObjectURL" [@@mel.scope "URL"]
external revoke_object_url : string -> unit = "revokeObjectURL" [@@mel.scope "URL"]

(** Offer [contents] as a file download named [filename]. *)
let download ~filename ~mime contents =
  let url = create_object_url (make_blob [| contents |] { type_ = mime }) in
  let anchor = create_element document "a" in
  set_href anchor url;
  set_download anchor filename;
  Option.iter (fun b -> append_child b anchor) (Js.Nullable.toOption (body document));
  click anchor;
  remove anchor;
  ignore (Js.Global.setTimeout ~f:(fun () -> revoke_object_url url) 1000)

(* ── Media ────────────────────────────────────────────────────────────── *)

type media_query

external match_media : window -> string -> media_query = "matchMedia" [@@mel.send]
external matches : media_query -> bool = "matches" [@@mel.get]

let reduced_motion () = matches (match_media window "(prefers-reduced-motion: reduce)")
