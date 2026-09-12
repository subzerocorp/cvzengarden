(** Probe bookkeeping: named expectations, a failure count, an exit code. *)

external exit : int -> unit = "exit" [@@mel.scope "process"]
external log : string -> unit = "log" [@@mel.scope "console"]
external error : string -> unit = "error" [@@mel.scope "console"]

let failures = ref 0
let passes = ref 0

let fail name detail =
  incr failures;
  error ({js|  ✗ |js} ^ name);
  error ("    " ^ detail)

let pass name =
  incr passes;
  log ({js|  ✓ |js} ^ name)

let expect name cond detail = if cond then pass name else fail name detail

let equal_int name expected actual =
  expect name (expected = actual) (Printf.sprintf "expected %d, got %d" expected actual)

let equal_string name expected actual =
  expect name (expected = actual) (Printf.sprintf "expected %S, got %S" expected actual)

let contains name needle haystack =
  expect name
    (Js.String.includes ~search:needle haystack)
    (Printf.sprintf "%S not in %S" needle haystack)

let suite name = log name

let finish () =
  log (Printf.sprintf "\n%d probes passed, %d failed" !passes !failures);
  exit (if !failures > 0 then 1 else 0)
