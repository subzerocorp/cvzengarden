(** [/gallery] — every Theme on the same Skeleton. *)

open Rz_shared
open H
open Ui

type filter = All | Only of Theme_meta.target

let matches filter (t : Theme_meta.t) =
  match filter with All -> true | Only target -> t.target = target

let download_bundle () =
  match Store.resume () with
  | Ok resume ->
      let id = Store.theme_id () in
      Web.download ~filename:(id ^ "-resume.html") ~mime:"text/html"
        (Sandbox_doc.standalone ~theme_css:(Theme_css.get id) resume)
  | Error _ -> ()

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

let official_card (t : Theme_meta.t) =
  button
    ~a:
      [
        ("class", str "card-theme");
        ("type", str "button");
        ("aria-pressed", dyn (fun () -> if Store.theme_id () = t.id then "true" else "false"));
        on_click (fun () -> Store.pick_theme t.id);
      ]
    [
      thumbnail t;
      div
        ~a:[ ("class", str "card-theme-foot") ]
        [
          span ~a:[ ("class", str "card-theme-name") ] [ text t.name ];
          tag ~kind:"tag-accent-2" (Theme_meta.target_label t.target);
        ];
    ]

let community_card (c : Theme_meta.t) =
  let g, i, a = c.swatches in
  div
    ~a:[ ("class", str "card-review") ]
    [
      div
        ~a:
          [
            ("class", str "card-review-art");
            ( "style",
              str
                (Printf.sprintf
                   "background:radial-gradient(circle at 30%% 30%%,%s,transparent \
                    45%%),radial-gradient(circle at 70%% 65%%,%s,transparent 40%%),%s"
                   i a g) );
          ]
        [];
      div
        ~a:[ ("class", str "card-theme-foot") ]
        [
          span ~a:[ ("class", str "card-theme-name") ] [ text c.name ];
          span
            ~a:[ ("class", str "small") ]
            [
              text
                (c.author
                ^ match c.status with Theme_meta.In_review -> {js| · in review|js} | _ -> "");
            ];
        ];
    ]

let make () =
  let filter, set_filter = Solid.signal All in
  let chip label f =
    button
      ~a:
        [
          ("type", str "button");
          ( "class",
            dyn (fun () -> if filter () = f then "tag tag-accent chip" else "tag tag-neutral chip")
          );
          on_click (fun () -> set_filter f);
        ]
      [ text label ]
  in
  section
    ~a:[ ("class", str "page gallery"); ("aria-label", str "Gallery") ]
    [
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
              chip "All" All;
              chip "Screen" (Only Theme_meta.Screen);
              chip "Paper" (Only Theme_meta.Paper);
              chip "Both" (Only Theme_meta.Both);
            ];
        ];
      div
        ~a:[ ("class", str "gallery-grid") ]
        [
          show (fun () ->
              list (List.map official_card (List.filter (matches (filter ())) (Store.officials ()))));
          show (fun () ->
              list
                (List.map community_card (List.filter (matches (filter ())) (Store.community ()))));
        ];
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
                      match Store.resume () with
                      | Ok r -> (
                          match Option.bind r.basics (fun (b : Resume.Basics.t) -> b.name) with
                          | Some n -> "on " ^ n ^ {js|'s résumé|js}
                          | None -> {js|on your résumé|js})
                      | Error _ -> {js|on your résumé|js});
                ];
            ];
          view_seg ();
          button
            ~a:
              [
                ("class", str "btn btn-secondary"); ("type", str "button"); on_click download_bundle;
              ]
            [ text "Download HTML + CSS" ];
          pdf_button ~icon:false ();
        ];
      primary_sheet ~class_:"gallery-sheet";
    ]
