(** Hono's Bun adapter: static directories served from disk. Kept apart from [Hono] so the Worker
    bundle never imports [hono/bun], whose module body touches the [Bun] global. *)

val mount_static : Api.mount
(** [mount_static app ~prefix ~dir] serves [dir] under the URL [prefix]: [/assets/*] is answered
    from [frontend/dist/assets/*]. *)
