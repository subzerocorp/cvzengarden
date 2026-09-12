(** A tiny assertion harness: named cases, counted failures, non-zero exit. *)

external exit : int -> unit = "exit" [@@mel.scope "process"]
external log : string -> unit = "log" [@@mel.scope "console"]
external error : string -> unit = "error" [@@mel.scope "console"]
external read_file : string -> string -> string = "readFileSync" [@@mel.module "node:fs"]

let read path = read_file path "utf8"
let failures = ref 0
let passes = ref 0

let fail name detail =
  incr failures;
  error ({js|  ✗ |js} ^ name);
  error ("    " ^ detail)

let ok _name = incr passes

let equal ?(show = fun _ -> "<value>") name expected actual =
  if expected = actual then ok name
  else fail name (Printf.sprintf "expected %s\n    actual   %s" (show expected) (show actual))

let string name expected actual = equal ~show:(fun s -> "\"" ^ s ^ "\"") name expected actual
let int name expected actual = equal ~show:string_of_int name expected actual
let bool name expected actual = equal ~show:string_of_bool name expected actual

let string_option name expected actual =
  equal ~show:(function None -> "None" | Some s -> "Some \"" ^ s ^ "\"") name expected actual

let is_true name cond = bool name true cond
let is_false name cond = bool name false cond

let first_difference a b =
  let la = Js.String.split ~sep:"\n" a and lb = Js.String.split ~sep:"\n" b in
  let n = min (Array.length la) (Array.length lb) in
  let rec go i =
    if i >= n then
      if Array.length la <> Array.length lb then
        Some
          (Printf.sprintf "line %d: lengths differ (%d vs %d lines)" (n + 1) (Array.length la)
             (Array.length lb))
      else None
    else if la.(i) <> lb.(i) then
      Some (Printf.sprintf "line %d:\n    expected %s\n    actual   %s" (i + 1) la.(i) lb.(i))
    else go (i + 1)
  in
  go 0

(** Whole-document equality with a line-oriented diff on failure. *)
let document name expected actual =
  if expected = actual then ok name
  else fail name (Option.value (first_difference expected actual) ~default:"documents differ")

let suite name run =
  log name;
  run ()

let report () =
  log (Printf.sprintf "\n%d passed, %d failed" !passes !failures);
  if !failures > 0 then exit 1
