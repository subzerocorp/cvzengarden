(** Global chrome: the 68px top bar and the GPUI-style drawer. *)

open Rz_shared
open H
open Ui

let github = "https://github.com/subzerocorp/cvzengarden"

let top_bar () =
  header
    ~a:[ ("class", str "top") ]
    [
      button
        ~a:
          [
            ("class", str "btn btn-secondary top-menu");
            ("type", str "button");
            ("aria-label", str "Menu");
            ("aria-expanded", dyn (fun () -> if Store.menu_open () then "true" else "false"));
            on_click Store.toggle_menu;
          ]
        [ Icons.menu () ];
      link ~class_:"brand" Route.Garden [ text "ResumeZen" ];
      nav
        ~a:[ ("class", str "top-links"); ("aria-label", str "Primary") ]
        (List.map
           (fun page -> link page [ text (Route.label page) ])
           [ Route.Gallery; Route.About; Route.Studio; Route.Workbench ]);
      show (fun () ->
          if Route.is_authoring (Store.page ()) then
            a
              ~a:
                [
                  ("class", str "btn btn-secondary top-cta");
                  ("href", str github);
                  ("target", str "_blank");
                  ("rel", str "noreferrer");
                ]
              [ Icons.star (); text "Star on GitHub" ]
          else
            button
              ~a:
                [
                  ("class", str "btn btn-primary top-cta");
                  ("type", str "button");
                  on_click (fun () -> Store.navigate Route.Studio);
                ]
              [ text {js|Use my résumé|js} ]);
    ]

let gp_button ?(primary = false) ?(small = false) ?(extra = []) label f =
  button
    ~a:
      ([
         ( "class",
           str
             (String.concat " "
                ([ "gp-btn" ]
                @ (if primary then [ "primary" ] else [])
                @ if small then [ "small" ] else [])) );
         ("type", str "button");
         on_click f;
       ]
      @ extra)
    [ text label ]

let drawer () =
  let paste_open, set_paste_open = Solid.signal false in
  let heading label = p ~a:[ ("class", str "gp-h") ] [ text label ] in
  list
    [
      div ~a:[ ("class", str "scrim"); on_click Store.toggle_menu ] [];
      aside
        ~a:[ ("class", str "gp drawer"); ("role", str "dialog"); ("aria-label", str "Menu") ]
        [
          div
            ~a:[ ("class", str "drawer-head") ]
            [
              div
                [
                  p ~a:[ ("class", str "gp-h gp-kicker") ] [ text "Garden" ];
                  h2 ~a:[ ("class", str "drawer-title") ] [ text "ResumeZen" ];
                  p ~a:[ ("class", str "drawer-sub") ] [ text "One skeleton. Infinite themes." ];
                ];
              gp_button ~small:true ~extra:[ ("aria-label", str "Close") ] "Esc" Store.toggle_menu;
            ];
          nav
            ~a:[ ("class", str "drawer-group") ]
            [
              heading "Go to";
              div
                ~a:[ ("class", str "drawer-rows") ]
                (List.map
                   (fun page ->
                     button
                       ~a:
                         [
                           ("class", str "gp-row");
                           ("type", str "button");
                           data_on (fun () -> Store.page () = page);
                           on_click (fun () -> Store.navigate page);
                         ]
                       [
                         span ~a:[ ("class", str "gp-row-label") ] [ text (Route.label page) ];
                         span ~a:[ ("class", str "mono gp-row-path") ] [ text (Route.path page) ];
                       ])
                   Route.all);
            ];
          div
            ~a:[ ("class", str "drawer-group") ]
            [
              heading {js|Use my résumé|js};
              gp_button "Paste JSON Resume" (fun () -> set_paste_open (not (paste_open ())));
              show (fun () ->
                  if paste_open () then
                    list
                      [
                        textarea
                          ~a:
                            [
                              ("class", str "mono gp-paste");
                              ("spellcheck", str "false");
                              ("placeholder", str {|{ "basics": { … } }|});
                              ("value", dyn Store.resume_text);
                              ( "onInput",
                                handler (fun (e : Web.event) ->
                                    Store.set_resume_text (Web.value (Web.target e))) );
                            ]
                          [];
                        p ~a:[ ("class", str "gp-ok") ] [ text "Stored in this browser only." ];
                        gp_button ~small:true "Open the Studio" (fun () ->
                            Store.navigate Route.Studio);
                      ]
                  else nothing);
            ];
          div
            ~a:[ ("class", str "drawer-group") ]
            [
              heading "Themes";
              div
                ~a:[ ("class", str "drawer-rows") ]
                [
                  show (fun () ->
                      list
                        (List.map
                           (fun (t : Theme_meta.t) ->
                             button
                               ~a:
                                 [
                                   ("class", str "gp-row gp-row-between");
                                   ("type", str "button");
                                   data_on (fun () -> Store.theme_id () = t.id);
                                   on_click (fun () -> Store.pick_theme t.id);
                                 ]
                               [
                                 span ~a:[ ("class", str "gp-row-label") ] [ text t.name ];
                                 span
                                   ~a:
                                     [
                                       ("class", str "gp-badge");
                                       ( "style",
                                         str
                                           ("color:" ^ t.badge ^ ";border-color:color-mix(in srgb,"
                                          ^ t.badge ^ " 40%, #e4e4e7)") );
                                     ]
                                   [ text (Theme_meta.target_label t.target) ];
                               ])
                           (Store.officials ())));
                ];
            ];
          div
            ~a:[ ("class", str "drawer-group") ]
            [
              heading "View";
              div
                ~a:[ ("class", str "gp-inline") ]
                [
                  gp_button ~small:true
                    ~extra:[ data_on (fun () -> not (Store.is_paper ())) ]
                    "Screen"
                    (fun () -> Store.choose_view View_mode.Screen);
                  gp_button ~small:true
                    ~extra:[ data_on Store.is_paper ]
                    "Print preview"
                    (fun () -> Store.choose_view View_mode.Paper);
                ];
              p ~a:[ ("class", str "gp-muted") ] [ show_text Store.pages_label ];
              gp_button ~primary:true "Print / Save as PDF" Store.print_sheet;
              gp_button "Copy link" Store.copy_link;
            ];
          div
            ~a:[ ("class", str "drawer-group") ]
            [
              heading "Appearance";
              div
                ~a:
                  [
                    ("class", str "gp-inline");
                    ("title", str "The Organic chrome ships light-only in this preview");
                  ]
                [
                  span ~a:[ ("class", str "gp-btn primary small") ] [ text "System" ];
                  span
                    ~a:[ ("class", str "gp-btn small"); ("aria-disabled", str "true") ]
                    [ text "Light" ];
                  span
                    ~a:[ ("class", str "gp-btn small"); ("aria-disabled", str "true") ]
                    [ text "Dark" ];
                ];
            ];
          div
            ~a:[ ("class", str "drawer-foot") ]
            [ link ~class_:"gp-link" Route.About [ text {js|About · Free during the preview|js} ] ];
        ];
    ]
