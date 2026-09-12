(** The two render views: a Theme as a web page, or ink on a Letter sheet. *)

type t = Screen | Paper

let to_key = function Screen -> "screen" | Paper -> "paper"

let of_key = function
  | "screen" | "web" -> Some Screen
  | "paper" | "print" -> Some Paper
  | _ -> None

let label = function Screen -> "Screen" | Paper -> "Paper"
let toggle = function Screen -> Paper | Paper -> Screen
