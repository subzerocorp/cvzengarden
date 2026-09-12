(** The sandboxed résumé preview. The frame is not mounted until the overlays and the Theme CSS are
    in hand, so the first paint is styled (BAR-U1); afterwards Theme, view and Skeleton changes are
    applied in place so a swap cross-fades instead of reloading. Paper view applies the Theme's own
    print media (unwrapped by [Print_media]) and draws the sheet the Theme's [@page] box describes.
*)

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

let page_count ~page_px height = max 1 ((height + page_px - 1) / page_px)

(** The sheet is the article itself. *)
let sheet_height doc =
  match Js.Nullable.toOption (Web.query_selector doc ".rz-resume") with
  | Some article -> Web.scroll_height article
  | None -> Web.scroll_height (Web.document_element doc)

type props = {
  css : unit -> string option;  (** the Theme stylesheet, once fetched *)
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

(** What the frame applies for a view: raw CSS on screen, print media on paper. *)
let css_for_view css (view : View_mode.t) =
  match view with View_mode.Screen -> css | View_mode.Paper -> Print_media.emulate css

let make p : H.node =
  let frame, set_frame = signal (None : Web.element option) in
  let ready, set_ready = signal false in
  let doc () = Option.bind (frame ()) (fun f -> Js.Nullable.toOption (Web.content_document f)) in
  (* The first document, built once everything it needs has arrived. *)
  let initial =
    create_memo (fun () ->
        match (base_css (), paper_css (), p.css ()) with
        | "", _, _ | _, "", _ | _, _, None -> None
        | base, paper, Some css ->
            Some
              (Sandbox_doc.frame ~base_css:base ~paper_css:paper
                 ~theme_css:(css_for_view css (untrack p.view))
                 ~view:(untrack p.view) ~article:(untrack p.article)))
  in
  let latched = ref None in
  let srcdoc () =
    match !latched with
    | Some doc -> doc
    | None -> (
        match initial () with
        | Some doc ->
            latched := Some doc;
            doc
        | None -> "")
  in
  let page_px () =
    Option.fold
      ~none:Print_media.(sheet_height_px Letter)
      ~some:(fun css -> Print_media.(sheet_height_px (page_box css).size))
      (untrack p.css)
  in
  let measure () =
    match (p.on_pages, doc ()) with
    | Some report, Some d ->
        Web.request_animation_frame Web.window (fun _ ->
            report (page_count ~page_px:(page_px ()) (sheet_height d)))
    | _ -> ()
  in
  create_effect (fun () ->
      if ready () then
        Option.iter (fun d -> set_style d Sandbox_doc.style_id_base (base_css ())) (doc ()));
  create_effect (fun () ->
      if ready () then
        Option.iter (fun d -> set_style d Sandbox_doc.style_id_paper (paper_css ())) (doc ()));
  create_effect (fun () ->
      let css = p.css () in
      let view = p.view () in
      if ready () then
        match (css, doc ()) with
        | Some css, Some d ->
            set_style d Sandbox_doc.style_id_theme (css_for_view css view);
            Web.set_attribute (Web.document_element d) "style"
              (Sandbox_doc.page_style (Print_media.page_box css));
            Web.set_attribute (Web.document_element d) "data-view" (View_mode.to_key view);
            measure ()
        | _ -> ());
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
    if !latched <> None then (
      set_ready true;
      measure ())
  in
  H.h "iframe"
    (H.props
       [
         ("class", H.str p.class_);
         ("title", H.str {js|Résumé preview|js});
         ("sandbox", H.str "allow-same-origin allow-modals");
         ("srcdoc", H.dyn srcdoc);
         ("data-ready", H.dyn (fun () -> if ready () then "true" else "false"));
         ("onLoad", H.handler on_load);
         ("ref", H.handler (fun el -> set_frame (Some el)));
       ])
    [||]
