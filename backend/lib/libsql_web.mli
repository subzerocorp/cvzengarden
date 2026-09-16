(** The libSQL client built for edge runtimes ([@libsql/client/web]): Turso over HTTP, no native
    binding. Same client type as [Libsql]. *)

val connect : url:string -> auth_token:string -> Libsql.client
(** [connect ~url ~auth_token] opens the Turso database at [url]. *)
