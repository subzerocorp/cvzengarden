(** SolidJS reactive primitives. A signal is the [[get, set]] pair Solid returns, typed as a tuple
    (Melange tuples are JS arrays). *)

type 'a signal = (unit -> 'a) * ('a -> unit)

external create_signal : 'a -> 'a signal = "createSignal" [@@mel.module "solid-js"]
external create_effect : (unit -> unit) -> unit = "createEffect" [@@mel.module "solid-js"]

(* A memo's getter is a zero-arity JS function; an OCaml [unit -> 'a] type
   would make the external look like a two-argument call, so the getter is
   kept opaque and read through Function.prototype.call. *)
type 'a accessor

external create_memo_raw : (unit -> 'a) -> 'a accessor = "createMemo" [@@mel.module "solid-js"]
external read : 'a accessor -> 'a = "call" [@@mel.send]

let create_memo f =
  let memo = create_memo_raw f in
  fun () -> read memo

external on_cleanup : (unit -> unit) -> unit = "onCleanup" [@@mel.module "solid-js"]
external on_mount : (unit -> unit) -> unit = "onMount" [@@mel.module "solid-js"]
external batch : (unit -> 'a) -> 'a = "batch" [@@mel.module "solid-js"]
external untrack : (unit -> 'a) -> 'a = "untrack" [@@mel.module "solid-js"]
external create_root : ((unit -> unit) -> 'a) -> 'a = "createRoot" [@@mel.module "solid-js"]

(** A memo that lives as long as the page: module-level derived state. *)
let global_memo f = create_root (fun _dispose -> create_memo f)

(** Signals whose value is a function would be mistaken for updaters by Solid's setter; every store
    value here is data, never a closure. *)
let signal initial = create_signal initial
