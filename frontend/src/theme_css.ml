(** Theme stylesheets, fetched once and shared by every preview frame. *)

open Solid

let cache : string Js.Dict.t = Js.Dict.empty ()
let in_flight : bool Js.Dict.t = Js.Dict.empty ()
let version, bump = signal 0
let ( let> ) = Web.( let> )

let ensure id =
  if Option.is_none (Js.Dict.get cache id) && Option.is_none (Js.Dict.get in_flight id) then (
    Js.Dict.set in_flight id true;
    (let> css = Web.get_text ("/themes/" ^ id ^ ".css") in
     Option.iter
       (fun css ->
         Js.Dict.set cache id css;
         bump (version () + 1))
       css;
     Js.Promise.resolve ())
    |> ignore)

(** Reactive: [""] until the stylesheet arrives, then the CSS. *)
let get id =
  ignore (version ());
  ensure id;
  Option.value (Js.Dict.get cache id) ~default:""
