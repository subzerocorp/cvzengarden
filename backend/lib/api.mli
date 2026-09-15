(** The HTTP surface. Handlers decode, then calculate, then respond. *)

type config = {
  themes_dir : string;
  skeleton_dir : string;
  static_dir : string;
  admin_token : string option;
}
(** [config] is the on-disk layout and the reviewer token. *)

val default_config : config
(** [default_config] is the repository-relative layout with moderation off. *)

val build : ?config:config -> Db.t -> Hono.t
(** [build ?config db] is the Hono app bound to [db]. *)
