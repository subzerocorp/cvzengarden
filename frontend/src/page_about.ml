(** [/about] — the Stage: manifesto, staged Theme, how to contribute. *)

open Rz_shared
open H
open Ui

(* The designer path stays on the Garden (BAR-D1): sample HTML, the starter
   stylesheet and the contract are served by this origin. *)
let contract_url = "/skeleton/CLASS-CONTRACT.md"
let example_url = "/skeleton/example.html"
let blank_url = "/themes/_blank.css"
let view_stylesheet () = Web.open_ Web.window ("/themes/" ^ Store.theme_id () ^ ".css") "_blank"

let staged_card () =
  let cell label value = list [ span ~a:[ ("class", str "muted") ] [ text label ]; value ] in
  div
    ~a:[ ("class", str "staged") ]
    [
      span ~a:[ ("class", str "kicker") ] [ text "Currently staged theme" ];
      div
        ~a:[ ("class", str "staged-grid") ]
        [
          cell "Title"
            (span
               ~a:[ ("class", str "staged-title") ]
               [
                 show_text (fun () ->
                     Option.fold ~none:""
                       ~some:(fun (t : Theme_meta.t) -> t.name)
                       (Store.selected_theme ()));
               ]);
          cell "Author"
            (span
               [
                 show_text (fun () ->
                     match Store.selected_theme () with
                     | Some t when t.status = Theme_meta.Official -> {js|ResumeZen · first-party|js}
                     | Some t -> t.author
                     | None -> "");
               ]);
          cell "Target"
            (span
               [
                 show_text (fun () ->
                     Option.fold ~none:""
                       ~some:(fun (t : Theme_meta.t) -> Theme_meta.target_label t.target)
                       (Store.selected_theme ()));
               ]);
          cell "File"
            (span ~a:[ ("class", str "mono") ] [ show_text (fun () -> Store.theme_id () ^ ".css") ]);
        ];
      div
        ~a:[ ("class", str "row wrap gap-6") ]
        [
          button
            ~a:
              [
                ("class", str "btn btn-secondary btn-sm");
                ("type", str "button");
                on_click view_stylesheet;
              ]
            [ text "View stylesheet" ];
        ];
    ]

let step n colour body =
  li
    ~a:[ ("class", str "step") ]
    [ span ~a:[ ("class", str ("step-num " ^ colour)) ] [ text (string_of_int n) ]; span body ]

let ext href label =
  a ~a:[ ("href", str href); ("target", str "_blank"); ("rel", str "noreferrer") ] [ text label ]

let featured () =
  show (fun () ->
      list
        (List.map
           (fun (c : Theme_meta.t) ->
             li
               ~a:[ ("class", str "featured") ]
               [
                 span ~a:[ ("class", str "featured-disc"); ("style", str (conic c.swatches)) ] [];
                 span ~a:[ ("class", str "featured-name") ] [ text c.name ];
                 span ~a:[ ("class", str "muted") ] [ text ("by " ^ c.author) ];
                 tag ~kind:"tag-accent-2 ml-auto" (Theme_meta.target_label c.target);
               ])
           (Store.community ())))

let make () =
  section
    ~a:[ ("class", str "page about"); ("aria-label", str "About") ]
    [
      div
        ~a:[ ("class", str "about-hero") ]
        [
          div
            [
              h1 [ text {js|A résumé showcase styled by community CSS|js} ];
              p
                ~a:[ ("class", str "lede") ]
                [
                  text "One semantic HTML skeleton. Every theme is a single stylesheet against the ";
                  span ~a:[ ("class", str "mono") ] [ text "rz-*" ];
                  text
                    {js| contract. Pick one below; the résumé you're reading is re-styled in place.|js};
                ];
            ];
          staged_card ();
        ];
      div
        ~a:[ ("class", str "stage-row") ]
        [
          span ~a:[ ("class", str "muted small") ] [ text "Stage:" ];
          theme_pills ();
          span ~a:[ ("class", str "spacer") ] [];
          view_seg ();
        ];
      primary_sheet ~class_:"about-sheet";
      div
        ~a:[ ("class", str "about-columns") ]
        [
          div
            [
              h2 [ text "Steps to contribute" ];
              ol
                ~a:[ ("class", str "steps") ]
                [
                  step 1 "accent"
                    [
                      text "Download the ";
                      ext example_url "example HTML";
                      text " and a ";
                      ext blank_url "blank theme";
                      text ". Read the ";
                      ext contract_url "class contract";
                      text {js| — it's the whole API.|js};
                    ];
                  step 2 "accent-2"
                    [
                      text "Write one ";
                      span ~a:[ ("class", str "mono") ] [ text ".css" ];
                      text " file. Declare ";
                      span
                        ~a:[ ("class", str "mono") ]
                        [ text "/* rz-target: web | print | both */" ];
                      text " on line one. Fonts from the Library or an HTTPS CDN.";
                    ];
                  step 3 "accent"
                    [
                      text "Drop it on the ";
                      link Route.Workbench [ text "Workbench" ];
                      text
                        {js| and pass the checks: contract scope, reduced motion, prints in ≤ 3 pages.|js};
                    ];
                  step 4 "accent-2"
                    [
                      text
                        "Submit. Your theme is credited with your name and link for as long as the \
                         garden is online.";
                    ];
                ];
            ];
          div
            [
              h2 [ text "Featured themes" ];
              ul ~a:[ ("class", str "featured-list") ] [ featured () ];
              link ~class_:"more" Route.Gallery [ text {js|View all themes →|js} ];
            ];
        ];
    ]
