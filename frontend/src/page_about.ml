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
let selected f = show_text (fun () -> Option.fold ~none:"" ~some:f (Store.selected_theme ()))

let author_line (t : Theme_meta.t) =
  match t.status with Theme_meta.Official -> {js|ResumeZen · first-party|js} | _ -> t.author

let staged_facts () =
  let cell label value = list [ span ~a:[ ("class", str "muted") ] [ text label ]; value ] in
  div
    ~a:[ ("class", str "staged-grid") ]
    [
      cell "Title" (span ~a:[ ("class", str "staged-title") ] [ selected (fun t -> t.name) ]);
      cell "Author" (span [ selected author_line ]);
      cell "Target" (span [ selected (fun t -> Theme_meta.target_label t.target) ]);
      cell "File"
        (span ~a:[ ("class", str "mono") ] [ show_text (fun () -> Store.theme_id () ^ ".css") ]);
    ]

let staged_card () =
  div
    ~a:[ ("class", str "staged") ]
    [
      span ~a:[ ("class", str "kicker") ] [ text "Currently staged theme" ];
      staged_facts ();
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

let ext href label = a ~a:[ ("href", str href); ("target", str "_blank") ] [ text label ]
let mono t = span ~a:[ ("class", str "mono") ] [ text t ]

let first_steps () =
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
        mono ".css";
        text " file. Declare ";
        mono "/* rz-target: web | print | both */";
        text " on line one. Fonts from the Library or an HTTPS CDN.";
      ];
  ]

let last_steps () =
  [
    step 3 "accent"
      [
        text "Drop it on the ";
        link Route.Workbench [ text "Workbench" ];
        text {js| and pass the checks: contract scope, reduced motion, prints in ≤ 3 pages.|js};
      ];
    step 4 "accent-2"
      [
        text
          "Submit. Your theme is credited with your name and link for as long as the garden is \
           online.";
      ];
  ]

let steps () = ol ~a:[ ("class", str "steps") ] (first_steps () @ last_steps ())

let featured_row (c : Theme_meta.t) =
  li
    ~a:[ ("class", str "featured") ]
    [
      span ~a:[ ("class", str "featured-disc"); ("style", str (conic c.swatches)) ] [];
      span ~a:[ ("class", str "featured-name") ] [ text c.name ];
      span ~a:[ ("class", str "muted") ] [ text ("by " ^ c.author) ];
      tag ~kind:"tag-accent-2 ml-auto" (Theme_meta.target_label c.target);
    ]

let hero () =
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
    ]

let columns () =
  div
    ~a:[ ("class", str "about-columns") ]
    [
      div [ h2 [ text "Steps to contribute" ]; steps () ];
      div
        [
          h2 [ text "Featured themes" ];
          ul
            ~a:[ ("class", str "featured-list") ]
            [ show (fun () -> list (List.map featured_row (Store.community ()))) ];
          link ~class_:"more" Route.Gallery [ text {js|View all themes →|js} ];
        ];
    ]

let make () =
  section
    ~a:[ ("class", str "page about"); ("aria-label", str "About") ]
    [
      hero ();
      div
        ~a:[ ("class", str "stage-row") ]
        [
          span ~a:[ ("class", str "muted small") ] [ text "Stage:" ];
          theme_pills ();
          span ~a:[ ("class", str "spacer") ] [];
          view_seg ();
        ];
      primary_sheet ~class_:"about-sheet";
      columns ();
    ]
