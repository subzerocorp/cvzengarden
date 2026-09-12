(** Solid hyperscript. [h tag props children] returns a lazy element thunk; strings become text
    nodes, closures become reactive children, arrays flatten. No JSX, no templates — plain function
    calls. *)

type node
type prop

external h : string -> prop Js.Dict.t -> node array -> node = "default"
[@@mel.module "solid-js/h"] [@@mel.variadic]

(* ── Props ─────────────────────────────────────────────────────────────── *)

external str : string -> prop = "%identity"
external bool : bool -> prop = "%identity"
external int : int -> prop = "%identity"

external handler : ('e -> unit) -> prop = "%identity"
(** Event handlers ([onClick], [onInput] …) and [ref] callbacks. *)

external dyn : (unit -> 'a) -> prop = "%identity"
(** A reactive attribute: Solid re-runs the getter when its signals change. *)

external classes : bool Js.Dict.t -> prop = "%identity"
external undefined : prop = "#undefined"

let props pairs : prop Js.Dict.t = Js.Dict.fromList pairs
let no_props : prop Js.Dict.t = Js.Dict.empty ()
let class_list (pairs : (string * bool) list) : bool Js.Dict.t = Js.Dict.fromList pairs

(* ── Children ─────────────────────────────────────────────────────────── *)

external text : string -> node = "%identity"

external show : (unit -> node) -> node = "%identity"
(** A reactive child: re-inserted when its dependencies change. *)

external show_text : (unit -> string) -> node = "%identity"
external many : node array -> node = "%identity"
external of_nullable : node Js.nullable -> node = "%identity"
external of_element : 'element -> node = "%identity"

let nothing : node = of_nullable Js.Nullable.null
let list nodes = many (Array.of_list nodes)
let when_ cond node = if cond then node else nothing
let opt = function Some node -> node | None -> nothing

(* ── Sugar ─────────────────────────────────────────────────────────────── *)

let el tag ?(a = []) children = h tag (props a) (Array.of_list children)
let div = el "div"
let span = el "span"
let p = el "p"
let button = el "button"
let a = el "a"
let ul = el "ul"
let li = el "li"
let ol = el "ol"
let h1 = el "h1"
let h2 = el "h2"
let h3 = el "h3"
let label = el "label"
let input = el "input"
let textarea = el "textarea"
let section = el "section"
let header = el "header"
let aside = el "aside"
let main = el "main"
let nav = el "nav"
let iframe = el "iframe"
