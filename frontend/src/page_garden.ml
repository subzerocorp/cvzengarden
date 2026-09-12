(** [/] — the Desk: hero, live sheet, floating Theme picker. Fixed height. *)

open H
open Ui

let make () =
  section
    ~a:[ ("class", str "page garden"); ("aria-label", str "Garden") ]
    [
      div ~a:[ ("class", str "garden-glow") ] [];
      div
        ~a:[ ("class", str "garden-hero") ]
        [
          h1 [ text "One skeleton. Infinite themes." ];
          tag ~kind:"tag-accent-2" "Free during the preview";
          span
            ~a:[ ("class", str "hint") ]
            [ text {js|Pick a theme — the same résumé is redrawn.|js} ];
        ];
      primary_sheet ~class_:"garden-sheet";
      div
        ~a:[ ("class", str "pillbar") ]
        [
          theme_pills ~swatch:Disc ();
          span ~a:[ ("class", str "pillbar-divider") ] [];
          view_seg ();
          pages_label ();
          pdf_button ();
        ];
    ]
