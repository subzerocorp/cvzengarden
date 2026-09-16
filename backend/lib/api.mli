(** The HTTP surface. Handlers decode, then calculate, then respond. *)

type mount = Hono.t -> prefix:string -> dir:string -> unit
(** [mount] serves a directory under a URL prefix. *)

(** [files] is where the app finds its files: disk on Bun, the assets binding on Workers. *)
type files =
  | Disk of mount
      (** repository paths read from disk; static directories mounted with the given [mount] *)
  | Assets of (string -> Bun.response Js.Promise.t)
      (** repository paths fetched through a static-assets binding by URL; unmatched routes fall
          through to it *)

type config = {
  themes_dir : string;
  skeleton_dir : string;
  static_dir : string;
  admin_token : string option;
  files : files;
}
(** [config] is the repository layout, the reviewer token and the file source. *)

val default_config : config
(** [default_config] is the repository-relative layout with moderation off and no static mounts. *)

val spa_routes : string list
(** [spa_routes] are the chrome's paths, each answered with the built [index.html]. *)

val build : ?config:config -> Db.t -> Hono.t
(** [build ?config db] is the Hono app bound to [db]. *)
