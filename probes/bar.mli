(** Market-quality-bar probes. *)

val run : Playwright.page -> string -> unit Js.Promise.t
(** [run page base] walks the BAR-* checks against [base]. *)
