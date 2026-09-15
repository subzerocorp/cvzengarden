(** Theme stylesheets, fetched once and shared by every preview frame. A failed fetch is forgotten
    after a short pause so a bad id retries; a frame never paints until the CSS is in hand (BAR-U1).
*)

open Solid

let cache : string Js.Dict.t = Js.Dict.empty ()
let in_flight : string Js.Dict.t = Js.Dict.empty ()
let version, bump = signal 0
let retry_after_ms = 5000
let ( let> ) = Web.( let> )

let headers () =
  match Store.admin_token () with "" -> [] | token -> [ ("Authorization", "Bearer " ^ token) ]

let ensure id =
  if Option.is_none (Js.Dict.get cache id) && Option.is_none (Js.Dict.get in_flight id) then (
    Js.Dict.set in_flight id "fetching";
    (let> status, body =
       Web.request ~method_:"GET" ~headers:(untrack headers) ("/themes/" ^ id ^ ".css")
     in
     if status = 200 then (
       Js.Dict.set cache id body;
       Js.Dict.unsafeDeleteKey in_flight id [@u];
       bump (version () + 1))
     else
       ignore
         (Js.Global.setTimeout
            ~f:(fun () -> (Js.Dict.unsafeDeleteKey in_flight id [@u]))
            retry_after_ms
           : Js.Global.timeoutId);
     Js.Promise.resolve ())
    |> fun p -> ignore (p : unit Js.Promise.t))

(** Reactive: [None] until the stylesheet arrives, then the CSS. *)
let get id =
  ignore (version () : int);
  ensure id;
  Js.Dict.get cache id

(** Forget a cached stylesheet (after a decision changes who may see it). *)
let forget id = Js.Dict.unsafeDeleteKey cache id [@u]
