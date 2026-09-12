(** Seed rows: the three first-party Themes (always) and, when the store has no Submissions yet and
    demo seeding is on, the review-queue examples the Gallery mock shows. *)

open Rz_shared
open Promise

let demo_css ~name ~target ~ground ~ink ~accent ~font =
  String.concat "\n"
    [
      Printf.sprintf "/* rz-target: %s */" target;
      Printf.sprintf "/* %s — a community example seeded for the review queue demo. */" name;
      Printf.sprintf
        ".rz-resume { padding: 2.5rem 2rem; background: %s; color: %s; font-family: %s; \
         line-height: 1.45; }"
        ground ink font;
      Printf.sprintf
        ".rz-name { color: %s; font-size: 2.4rem; line-height: 1; margin: 0 0 .25rem; }" accent;
      ".rz-title { margin: 0 0 1rem; opacity: .8; }";
      ".rz-contact-list, .rz-link-list, .rz-bullets, .rz-tags, .rz-skill-list, .rz-skill-groups, \
       .rz-meta-list, .rz-entries { list-style: none; margin: 0; padding: 0; }";
      ".rz-contact-list, .rz-link-list, .rz-tags, .rz-skill-list { display: flex; flex-wrap: wrap; \
       gap: .3rem .9rem; }";
      ".rz-contact-label, .rz-link-label { font-size: .7rem; letter-spacing: .12em; \
       text-transform: uppercase; opacity: .7; margin-right: .35em; }";
      Printf.sprintf
        ".rz-section { margin: 1.4rem 0 0; } .rz-section-title { font-size: .8rem; letter-spacing: \
         .18em; text-transform: uppercase; color: %s; border-bottom: 1px solid %s; padding-bottom: \
         .25rem; margin: 0 0 .6rem; }"
        accent accent;
      ".rz-entry { margin: 0 0 .9rem; } .rz-entry-header { display: grid; grid-template-columns: \
       minmax(0,1fr) max-content; gap: .1rem .8rem; }";
      ".rz-entry-primary { grid-column: 1; margin: 0; font-size: 1.05rem; } .rz-entry-secondary { \
       grid-column: 1; margin: 0; font-style: italic; }";
      ".rz-dates { grid-column: 2; grid-row: 1; margin: 0; font-size: .85rem; opacity: .75; } \
       .rz-location, .rz-score { grid-column: 1; margin: 0; font-size: .85rem; }";
      Printf.sprintf
        ".rz-bullet { position: relative; padding-left: 1rem; margin: .25rem 0; } \
         .rz-bullet::before { content: ''; position: absolute; left: 0; top: .6em; width: .45rem; \
         height: 2px; background: %s; }"
        accent;
      Printf.sprintf
        ".rz-skill, .rz-tag { padding: .1rem .5rem; border: 1px solid %s; border-radius: 999px; \
         font-size: .8rem; }"
        accent;
      Printf.sprintf ".rz-resume a { color: %s; }" accent;
      "@media print { .rz-resume { padding: 0; background: #fff; color: #000; } }";
    ]

let community : (Theme_meta.t * string) list =
  let mk id name author target fonts ground ink accent badge font =
    ( {
        Theme_meta.id;
        name;
        author;
        author_url = None;
        target;
        fonts;
        swatches = (ground, ink, accent);
        badge;
        bg = ground;
        status = Theme_meta.In_review;
      },
      demo_css ~name ~target:(Theme_meta.target_key target) ~ground ~ink ~accent ~font )
  in
  [
    mk "tidepool" "Tidepool" "Mika Sato" Theme_meta.Screen Theme_meta.Https_cdn "#0f4c5c" "#e0fbfc"
      "#ee9b00" "#2563eb" "system-ui, sans-serif";
    mk "letterpress" "Letterpress" "Devon Hale" Theme_meta.Paper Theme_meta.Library "#fdf6e3"
      "#2b2b2b" "#b5651d" "#d97706" "Georgia, serif";
    mk "orchard" "Orchard" "Priya Nair" Theme_meta.Both Theme_meta.Library "#e9f5db" "#3a5a40"
      "#d4a373" "#16a34a" "system-ui, sans-serif";
  ]

let seed_officials db =
  Promise.sequence
    (List.map
       (fun (t : Theme_meta.t) () ->
         Promise.map ignore (Db.insert ~or_ignore:true db t ~css:None ~checks_json:None))
       Theme_meta.officials)

let seed_demo db =
  let> in_review = Db.count_where db "in_review" in
  let> approved = Db.count_where db "approved" in
  if in_review + approved > 0 then return ()
  else
    Promise.sequence
      (List.map
         (fun ((t : Theme_meta.t), css) () ->
           let checks = Theme_lint.run css |> Theme_lint.list_to_json |> Js.Json.stringify in
           Promise.map ignore
             (Db.insert ~or_ignore:true db t ~css:(Some css) ~checks_json:(Some checks)))
         community)

let run ~demo db =
  let> () = seed_officials db in
  if demo then seed_demo db else return ()
