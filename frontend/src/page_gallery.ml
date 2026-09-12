(** [/gallery] — every Theme on the same Skeleton. *)

open Rz_shared
open H
open Ui

type filter = All | Only of Theme_meta.target

let matches filter (t : Theme_meta.t) =
  match filter with All -> true | Only target -> t.target = target

(** Whose résumé is on the sheet, when the document names someone. *)
let owner_name () =
  Option.bind
    (Result.to_option (Store.resume ()))
    (fun (r : Resume.t) -> Option.bind r.basics (fun (b : Resume.Basics.t) -> b.name))

let thumbnail (t : Theme_meta.t) =
  div
    ~a:[ ("class", str "thumb") ]
    [
      div
        ~a:[ ("class", str "thumb-scale") ]
        [
          Sheet.make
            {
              css = (fun () -> Theme_css.get t.id);
              view = (fun () -> View_mode.Screen);
              article = Store.article;
              primary = false;
              on_pages = None;
              class_ = "sheet-frame";
            };
        ];
    ]

let card_foot (t : Theme_meta.t) trailing =
  div
    ~a:[ ("class", str "card-theme-foot") ]
    [ span ~a:[ ("class", str "card-theme-name") ] [ text t.name ]; trailing ]

let public_card (t : Theme_meta.t) =
  button
    ~a:
      [
        ("class", str "card-theme");
        ("type", str "button");
        ("aria-pressed", dyn (fun () -> if Store.theme_id () = t.id then "true" else "false"));
        on_click (fun () -> Store.pick_theme t.id);
      ]
    [ thumbnail t; card_foot t (tag ~kind:"tag-accent-2" (Theme_meta.target_label t.target)) ]

let queue_card (c : Theme_meta.t) =
  let g, i, a = c.swatches in
  let art =
    Printf.sprintf
      "background:radial-gradient(circle at 30%% 30%%,%s,transparent 45%%),radial-gradient(circle \
       at 70%% 65%%,%s,transparent 40%%),%s"
      i a g
  in
  div
    ~a:[ ("class", str "card-review") ]
    [
      div ~a:[ ("class", str "card-review-art"); ("style", str art) ] [];
      card_foot c (span ~a:[ ("class", str "small") ] [ text (c.author ^ {js| · in review|js}) ]);
    ]

let filter_chip (filter, set_filter) label f =
  button
    ~a:
      [
        ("type", str "button");
        ( "class",
          dyn (fun () -> if filter () = f then "tag tag-accent chip" else "tag tag-neutral chip") );
        on_click (fun () -> set_filter f);
      ]
    [ text label ]

let head filter =
  div
    ~a:[ ("class", str "gallery-head") ]
    [
      div
        [
          h1 [ text "The Garden" ];
          p
            ~a:[ ("class", str "lede") ]
            [
              text
                {js|Every theme below is pure CSS on the same HTML. Pick one; your résumé still parses as a document.|js};
            ];
        ];
      div
        ~a:[ ("class", str "row gap-6") ]
        [
          filter_chip filter "All" All;
          filter_chip filter "Screen" (Only Theme_meta.Screen);
          filter_chip filter "Paper" (Only Theme_meta.Paper);
          filter_chip filter "Both" (Only Theme_meta.Both);
        ];
    ]

let grid (filter, _) =
  div
    ~a:[ ("class", str "gallery-grid") ]
    [
      show (fun () ->
          list (List.map public_card (List.filter (matches (filter ())) (Store.public_themes ()))));
      show (fun () ->
          list (List.map queue_card (List.filter (matches (filter ())) (Store.queue ()))));
    ]

let selected_bar () =
  div
    ~a:[ ("class", str "gallery-selected") ]
    [
      h2
        ~a:[ ("class", str "gallery-selected-title") ]
        [
          show_text (fun () ->
              Option.fold ~none:""
                ~some:(fun (t : Theme_meta.t) -> t.name)
                (Store.selected_theme ()));
          text " ";
          span
            ~a:[ ("class", str "on-resume") ]
            [
              show_text (fun () ->
                  match owner_name () with
                  | Some n -> "on " ^ n ^ {js|'s résumé|js}
                  | None -> {js|on your résumé|js});
            ];
        ];
      view_seg ();
      pdf_button ~icon:false ();
    ]

let make () =
  let filter = Solid.signal All in
  section
    ~a:[ ("class", str "page gallery"); ("aria-label", str "Gallery") ]
    [ head filter; grid filter; selected_bar (); primary_sheet ~class_:"gallery-sheet" ]
