(** The libSQL client built for edge runtimes ([@libsql/client/web]): Turso over HTTP, no native
    binding. Same client type as [Libsql]. *)

external create_client : string Js.Dict.t -> Libsql.client = "createClient"
[@@mel.module "@libsql/client/web"]

let connect ~url ~auth_token =
  let config = Js.Dict.empty () in
  Js.Dict.set config "url" url;
  Js.Dict.set config "authToken" auth_token;
  create_client config
