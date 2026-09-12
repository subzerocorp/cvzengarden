(** Server entry: environment → store → app → Bun.serve. *)

open Rz_backend
open Promise

let () =
  let port = int_of_string_opt (Bun.env_or "PORT" "4310") |> Option.value ~default:4310 in
  let url = Bun.env_or "DATABASE_URL" "file:data/cvzengarden.sqlite" in
  let auth_token = Js.Dict.get Bun.env "DATABASE_AUTH_TOKEN" in
  let demo = Bun.env_or "RZ_SEED_DEMO" "1" <> "0" in
  let db = Db.connect ~url ?auth_token () in
  let start =
    let> () = Db.migrate db in
    let> () = Seed.run ~demo db in
    let app = Api.build db in
    let server = Bun.serve { port; hostname = "0.0.0.0"; fetch = Hono.fetch app } in
    Bun.log
      (Printf.sprintf "ResumeZen listening on http://localhost:%d (store: %s)"
         (Bun.server_port server) url);
    return ()
  in
  start
  |> Js.Promise.catch (fun err ->
      Bun.error
        ("failed to start: " ^ Option.value (Js.Json.stringifyAny err) ~default:"unknown error");
      Bun.exit 1;
      return ())
  |> ignore
