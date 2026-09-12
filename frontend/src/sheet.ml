(** The sandboxed résumé preview. One iframe document is created up front; Theme, view and Skeleton
    changes are applied in place so a swap cross-fades instead of reloading. Theme CSS never reaches
    the chrome. *)

open Rz_shared
open Solid

let base_css, set_base_css = signal ""
let paper_css, set_paper_css = signal ""
let ( let> ) = Web.( let> )

let load_overlays () =
  let> base = Web.get_text "/assets/sandbox.css" in
  Option.iter set_base_css base;
  let> paper = Web.get_text "/assets/paper.css" in
  Option.iter set_paper_css paper;
  Js.Promise.resolve ()

(** Letter is 11in tall; the frame lays out at 96 CSS px per inch. *)
let letter_height_px = 1056

let page_count height = max 1 ((height + letter_height_px - 1) / letter_height_px)

(** The sheet is the article itself (min-height one Letter page in paper view). *)
let sheet_height doc =
  match Js.Nullable.toOption (Web.query_selector doc ".rz-resume") with
  | Some article -> Web.scroll_height article
  | None -> Web.scroll_height (Web.document_element doc)

type props = {
  css : unit -> string;  (** the Theme stylesheet to apply *)
  view : unit -> View_mode.t;
  article : unit -> string;
  primary : bool;  (** register as the print target for "Save as PDF" *)
  on_pages : (int -> unit) option;
  class_ : string;
}

let set_style doc id css =
  Option.iter
    (fun el -> Web.set_text_content el css)
    (Js.Nullable.toOption (Web.get_element_by_id doc id))

let make p : H.node =
  let frame, set_frame = signal (None : Web.element option) in
  let ready, set_ready = signal false in
  let doc () = Option.bind (frame ()) (fun f -> Js.Nullable.toOption (Web.content_document f)) in
  let initial =
    untrack (fun () ->
        Sandbox_doc.frame ~base_css:(base_css ()) ~paper_css:(paper_css ()) ~theme_css:(p.css ())
          ~view:(p.view ()) ~article:(p.article ()))
  in
  let measure () =
    match (p.on_pages, doc ()) with
    | Some report, Some d ->
        Web.request_animation_frame Web.window (fun _ -> report (page_count (sheet_height d)))
    | _ -> ()
  in
  (* Each effect tracks exactly the signals it applies. *)
  create_effect (fun () ->
      if ready () then
        Option.iter (fun d -> set_style d Sandbox_doc.style_id_base (base_css ())) (doc ()));
  create_effect (fun () ->
      if ready () then
        Option.iter (fun d -> set_style d Sandbox_doc.style_id_paper (paper_css ())) (doc ()));
  create_effect (fun () ->
      let css = p.css () in
      if ready () then
        Option.iter
          (fun d ->
            set_style d Sandbox_doc.style_id_theme css;
            measure ())
          (doc ()));
  create_effect (fun () ->
      let view = p.view () in
      if ready () then
        Option.iter
          (fun d ->
            Web.set_attribute (Web.document_element d) "data-view" (View_mode.to_key view);
            measure ())
          (doc ()));
  let last_article = ref (untrack p.article) in
  create_effect (fun () ->
      let article = p.article () in
      if ready () && article <> !last_article then (
        last_article := article;
        Option.iter
          (fun d ->
            Option.iter (fun b -> Web.set_inner_html b article) (Js.Nullable.toOption (Web.body d));
            measure ())
          (doc ())));
  if p.primary then
    create_effect (fun () ->
        if ready () then
          Option.iter
            (fun f -> Store.set_print_target (Js.Nullable.toOption (Web.content_window f)))
            (frame ()));
  let on_load _ =
    set_ready true;
    measure ()
  in
  H.h "iframe"
    (H.props
       [
         ("class", H.str p.class_);
         ("title", H.str {js|Résumé preview|js});
         ("sandbox", H.str "allow-same-origin allow-modals");
         ("srcdoc", H.str initial);
         ("onLoad", H.handler on_load);
         ("ref", H.handler (fun el -> set_frame (Some el)));
       ])
    [||]
