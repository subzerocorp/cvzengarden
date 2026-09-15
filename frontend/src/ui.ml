(** Shared chrome pieces: pills, the view toggle, the sheet shell. Every reactive read happens
    inside a getter so only the affected node updates. *)

open Rz_shared
open H

let on_click f = ("onClick", handler (fun (_ : Web.event) -> f ()))
let data_on getter = ("data-on", dyn (fun () -> if getter () then "true" else "false"))

(** An in-app link: a real [href] for the URL bar and middle-click, and a client-side navigation on
    a plain click. *)
let link ?(class_ = "") page children =
  a
    ~a:
      [
        ("href", str (Route.path page));
        ("class", str class_);
        ("aria-current", dyn (fun () -> if Store.page () = page then "page" else ""));
        ( "onClick",
          handler (fun (e : Web.event) ->
              Web.prevent_default e;
              Store.navigate page) );
      ]
    children

let swatch_dot colour = span ~a:[ ("class", str "sw"); ("style", str ("background:" ^ colour)) ] []

let conic (ground, ink, accent) =
  Printf.sprintf "background:conic-gradient(%s 0 33%%,%s 0 66%%,%s 0)" ink accent ground

type swatch = Dot | Disc | No_swatch

let theme_pill ?(swatch = Dot) ?(extra = []) ?(small = false) (t : Theme_meta.t) =
  let _, ink, _ = t.swatches in
  button
    ~a:
      ([
         ("class", str (if small then "pill pill-small" else "pill"));
         ("type", str "button");
         data_on (fun () -> Store.theme_id () = t.id);
         on_click (fun () -> Store.pick_theme t.id);
       ]
      @ extra)
    ((match swatch with
       | Dot -> [ swatch_dot ink ]
       | Disc -> [ span ~a:[ ("class", str "disc"); ("style", str (conic t.swatches)) ] [] ]
       | No_swatch -> [])
    @ [ text t.name ])

let theme_pills ?swatch ?small ?(with_target = false) () =
  show (fun () ->
      list
        (List.map
           (fun (t : Theme_meta.t) ->
             let extra = [] in
             if with_target then
               button
                 ~a:
                   [
                     ("class", str "pill");
                     ("type", str "button");
                     data_on (fun () -> Store.theme_id () = t.id);
                     on_click (fun () -> Store.pick_theme t.id);
                   ]
                 [
                   swatch_dot
                     (let _, ink, _ = t.swatches in
                      ink);
                   text t.name;
                   span
                     ~a:[ ("class", str "pill-target") ]
                     [ text (Theme_meta.target_label t.target) ];
                 ]
             else theme_pill ?swatch ?small ~extra t)
           (Store.public_themes ())))

let view_seg ?(small = false) () =
  let opt v label =
    button
      ~a:
        [
          ("type", str "button");
          data_on (fun () -> Store.view () = v);
          ("class", str (if small then "seg-small" else ""));
          on_click (fun () -> Store.choose_view v);
        ]
      [ text label ]
  in
  div
    ~a:[ ("class", str "seg2"); ("role", str "group"); ("aria-label", str "View") ]
    [ opt View_mode.Screen "Screen"; opt View_mode.Paper "Paper" ]

let pages_label () = span ~a:[ ("class", str "pages") ] [ show_text Store.pages_label ]

let pdf_button ?(icon = true) () =
  button
    ~a:[ ("class", str "btn btn-primary"); ("type", str "button"); on_click Store.print_sheet ]
    ((if icon then [ Icons.download () ] else []) @ [ text "Save as PDF" ])

(** The frame's shell: paper is a bare Letter sheet on the ground, screen is a rounded canvas
    painted in the Theme's own background. *)
let sheet_style () =
  let paper = Store.is_paper () in
  let bg =
    match Store.selected_theme () with Some t when not paper -> t.bg | _ -> "transparent"
  in
  String.concat ";"
    [
      ("--sheet-w:" ^ if paper then "900px" else "1040px");
      "--sheet-bg:" ^ bg;
      ("--sheet-shadow:" ^ if paper then "none" else "var(--shadow-lg)");
      ("--sheet-r:" ^ if paper then "0px" else "24px");
    ]

(** The page's main preview: the staged Theme on the Author's résumé. *)
let primary_sheet ~class_ =
  div
    ~a:[ ("class", str ("sheet " ^ class_)); ("style", dyn sheet_style) ]
    [
      Sheet.make
        {
          css = (fun () -> Theme_css.get (Store.theme_id ()));
          view = Store.view;
          article = Store.article;
          primary = true;
          on_pages = Some Store.set_pages;
          class_ = "sheet-frame";
        };
    ]

let tag ?(kind = "tag-neutral") label = span ~a:[ ("class", str ("tag " ^ kind)) ] [ text label ]
