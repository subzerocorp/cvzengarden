(** The Bun runtime surface the server needs: files, env, serve. *)

type file

external file : string -> file = "file" [@@mel.scope "Bun"]
external exists : file -> bool Js.Promise.t = "exists" [@@mel.send]
external text : file -> string Js.Promise.t = "text" [@@mel.send]
external env : string Js.Dict.t = "env" [@@mel.scope "process"]
external cwd : unit -> string = "cwd" [@@mel.scope "process"]
external log : string -> unit = "log" [@@mel.scope "console"]
external error : string -> unit = "error" [@@mel.scope "console"]
external exit : int -> unit = "exit" [@@mel.scope "process"]

type request
type response

type fetch_fn
(** A bound [(request) => Promise<Response>], e.g. Hono's [app.fetch]. *)

type serve_options = { port : int; hostname : string; fetch : fetch_fn }
type server

external serve : serve_options -> server = "serve" [@@mel.scope "Bun"]
external server_port : server -> int = "port" [@@mel.get]

let env_or key default = Option.value (Js.Dict.get env key) ~default

let read_text path =
  let f = file path in
  Js.Promise.then_
    (fun present ->
      if present then Js.Promise.then_ (fun t -> Js.Promise.resolve (Some t)) (text f)
      else Js.Promise.resolve None)
    (exists f)
