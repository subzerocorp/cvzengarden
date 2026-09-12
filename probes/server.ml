(** The server under probe: a child Bun process on a free port with an in-memory store and a known
    reviewer token. *)

type subprocess
type spawn_options = { env : string Js.Dict.t; stdout : string; stderr : string }

external spawn : string array -> spawn_options -> subprocess = "spawn" [@@mel.scope "Bun"]
external kill : subprocess -> unit = "kill" [@@mel.send]
external process_env : string Js.Dict.t = "env" [@@mel.scope "process"]

external assign : 'a Js.Dict.t -> 'a Js.Dict.t -> 'a Js.Dict.t -> 'a Js.Dict.t = "assign"
[@@mel.scope "Object"]

external random : unit -> float = "random" [@@mel.scope "Math"]
external fetch : string -> 'response Js.Promise.t = "fetch"
external ok : 'response -> bool = "ok" [@@mel.get]
external log : string -> unit = "log" [@@mel.scope "console"]

let token = "probe-token"

type t = { port : int; base : string; child : subprocess }

let ( let> ) promise f = Js.Promise.then_ f promise

(* [resolve] is uncurried; a unit argument would read as a zero-argument
   call, so the timer resolves with a token that is dropped right after. *)
let sleep ms : unit Js.Promise.t =
  Js.Promise.make (fun ~resolve ~reject:_ ->
      ignore (Js.Global.setTimeout ~f:(fun () -> (resolve 0 [@u])) ms))
  |> Js.Promise.then_ (fun (_ : int) -> Js.Promise.resolve ())

let rec wait_ready base attempts =
  if attempts = 0 then Js.Promise.reject (Failure ("server did not answer at " ^ base))
  else
    fetch (base ^ "/api/health")
    |> Js.Promise.then_ (fun r ->
        if ok r then Js.Promise.resolve true else Js.Promise.resolve false)
    |> Js.Promise.catch (fun _ -> Js.Promise.resolve false)
    |> Js.Promise.then_ (fun ready ->
        if ready then Js.Promise.resolve ()
        else
          let> () = sleep 250 in
          wait_ready base (attempts - 1))

let start () =
  let port = 4500 + int_of_float (random () *. 1000.) in
  let base = Printf.sprintf "http://localhost:%d" port in
  let overrides =
    Js.Dict.fromList
      [
        ("PORT", string_of_int port);
        ("DATABASE_URL", ":memory:");
        ("RZ_ADMIN_TOKEN", token);
        ("RZ_SEED_DEMO", "1");
      ]
  in
  let child =
    spawn
      [| "bun"; "_build/default/backend/output/backend/main.mjs" |]
      {
        env = assign (Js.Dict.empty ()) process_env overrides;
        stdout = "ignore";
        stderr = "inherit";
      }
  in
  let> () = wait_ready base 60 in
  log ("probe server ready on " ^ base);
  Js.Promise.resolve { port; base; child }

let stop t = kill t.child
