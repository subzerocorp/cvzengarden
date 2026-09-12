(** Mount: the chrome, the drawer, and whichever page the URL names. Only the page switch reads
    [Store.page], so Theme and view changes never rebuild a route. *)

open H

type dispose

external render : (unit -> node) -> Web.element -> dispose = "render" [@@mel.module "solid-js/web"]

let page () =
  match Store.page () with
  | Route.Garden -> Page_garden.make ()
  | Route.Gallery -> Page_gallery.make ()
  | Route.About -> Page_about.make ()
  | Route.Studio -> Page_studio.make ()
  | Route.Workbench -> Page_workbench.make ()
  | Route.Admin -> Page_admin.make ()

let app () =
  Store.start ();
  list
    [
      Chrome.top_bar ();
      show (fun () -> if Store.menu_open () then Chrome.drawer () else nothing);
      show page;
    ]

let () =
  Sheet.load_overlays () |> ignore;
  match Js.Nullable.toOption (Web.get_element_by_id Web.document "app") with
  | Some root -> ignore (render app root)
  | None -> ()
