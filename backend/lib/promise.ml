(** Binding operators over [Js.Promise], so async Actions read top to bottom. *)

let ( let> ) promise f = Js.Promise.then_ f promise
let return = Js.Promise.resolve

external flatten : 'a -> 'a Js.Promise.t = "resolve"
[@@mel.scope "Promise"]
(** Wrap a value that may or may not already be a promise. *)

let map f promise = Js.Promise.then_ (fun x -> return (f x)) promise

let rec sequence = function
  | [] -> return ()
  | action :: rest ->
      let> () = action () in
      sequence rest
