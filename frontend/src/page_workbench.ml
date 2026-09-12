(** [/workbench] — Theme authoring: metadata, live preview, contract checks. *)

open Rz_shared
open H
open Ui

let ( let> ) = Web.( let> )

type outcome = Idle | Sending | Accepted of string | Rejected of string

let make () =
  let name, set_name = Solid.signal "" in
  let author, set_author = Solid.signal "" in
  let target, set_target = Solid.signal Theme_meta.Screen in
  let fonts, set_fonts = Solid.signal Theme_meta.Library in
  let outcome, set_outcome = Solid.signal Idle in
  let measured, set_measured = Solid.signal (None : int option) in
  let picker, set_picker = Solid.signal (None : Web.element option) in
  (* The stylesheet under test: the dropped file, or the staged first-party Theme. *)
  let css () =
    match Store.custom_css () with
    | Some css -> css
    | None -> Option.value (Theme_css.get (Store.theme_id ())) ~default:""
  in
  let checks =
    Solid.create_memo (fun () ->
        let base = Theme_lint.run (css ()) in
        match measured () with Some n -> Theme_lint.with_pages n base | None -> base)
  in
  let adopt_css text =
    Store.set_custom_css (Some text);
    Option.iter
      (fun t -> Option.iter set_target (Theme_meta.target_of_key t))
      (Theme_lint.declared_target text);
    set_outcome Idle
  in
  let read_file (file : Js.File.t) =
    (let> text = Js.File.text file in
     adopt_css text;
     if name () = "" then
       set_name
         (Js.String.replaceByRe ~regexp:(Js.Re.fromString "\\.css$") ~replacement:""
            (Js.File.name file));
     Js.Promise.resolve ())
    |> ignore
  in
  let submit () =
    match Store.custom_css () with
    | None -> set_outcome (Rejected "Drop or paste a stylesheet first.")
    | Some css ->
        if Js.String.trim (name ()) = "" then set_outcome (Rejected "Give the theme a name.")
        else if Js.String.trim (author ()) = "" then
          set_outcome (Rejected "Add your name so the theme is credited.")
        else if Theme_lint.blocking (checks ()) then
          set_outcome (Rejected "Fix the failing contract checks first.")
        else (
          set_outcome Sending;
          let body =
            Js.Json.stringify
              (Js.Json.object_
                 (Js.Dict.fromList
                    [
                      ("name", Js.Json.string (name ()));
                      ("author", Js.Json.string (author ()));
                      ("target", Js.Json.string (Theme_meta.target_key (target ())));
                      ("fonts", Js.Json.string (Theme_meta.fonts_key (fonts ())));
                      ("css", Js.Json.string css);
                      ( "measuredPages",
                        Option.fold ~none:Js.Json.null
                          ~some:(fun n -> Js.Json.number (float_of_int n))
                          (measured ()) );
                    ]))
          in
          (let> status, text = Web.post_json "/api/submissions" body in
           (match status with
           | 201 ->
               let id =
                 match Decode.parse_json text with
                 | Ok json -> (
                     match Js.Json.decodeObject json with
                     | Some o -> (
                         match Option.bind (Js.Dict.get o "theme") Js.Json.decodeObject with
                         | Some t ->
                             Option.value
                               (Option.bind (Js.Dict.get t "id") Js.Json.decodeString)
                               ~default:""
                         | None -> "")
                     | None -> "")
                 | Error _ -> ""
               in
               set_outcome (Accepted id);
               Store.load_themes () |> ignore
           | 0 -> set_outcome (Rejected "The Garden did not answer. Try again in a moment.")
           | _ ->
               let message =
                 match Decode.parse_json text with
                 | Ok json -> (
                     match
                       Option.bind (Js.Json.decodeObject json) (fun o ->
                           Option.bind (Js.Dict.get o "error") Js.Json.decodeObject)
                     with
                     | Some err ->
                         let path = Option.bind (Js.Dict.get err "path") Js.Json.decodeString in
                         let msg =
                           Option.value
                             (Option.bind (Js.Dict.get err "message") Js.Json.decodeString)
                             ~default:"Rejected"
                         in
                         Option.fold ~none:msg ~some:(fun p -> p ^ " " ^ msg) path
                     | None -> "Rejected")
                 | Error _ -> "Rejected"
               in
               set_outcome (Rejected message));
           Js.Promise.resolve ())
          |> ignore)
  in
  let status_icon = function
    | Theme_lint.Pass -> span ~a:[ ("class", str "check-icon ok") ] [ Icons.check () ]
    | Theme_lint.Warn -> span ~a:[ ("class", str "check-icon warn") ] [ Icons.warn () ]
    | Theme_lint.Fail -> span ~a:[ ("class", str "check-icon fail") ] [ Icons.cross () ]
    | Theme_lint.Pending -> span ~a:[ ("class", str "check-icon pending") ] [ Icons.clock () ]
  in
  let check_row (c : Theme_lint.check) =
    div
      ~a:[ ("class", str "check") ]
      [
        status_icon c.status;
        div
          [
            div ~a:[ ("class", str "check-title") ] [ text c.title ];
            div ~a:[ ("class", str "check-note") ] [ text c.note ];
          ];
      ]
  in
  let field label control = div ~a:[ ("class", str "field") ] [ H.label [ text label ]; control ] in
  let radio_seg =
    div
      ~a:[ ("class", str "seg") ]
      (List.map
         (fun (t, label) ->
           H.label
             ~a:[ ("class", str "seg-opt") ]
             [
               input
                 ~a:
                   [
                     ("type", str "radio");
                     ("name", str "tgt");
                     ("checked", dyn (fun () -> target () = t));
                     on_click (fun () -> set_target t);
                   ]
                 [];
               text label;
             ])
         [ (Theme_meta.Screen, "Screen"); (Theme_meta.Paper, "Paper"); (Theme_meta.Both, "Both") ])
  in
  let font_radio f label =
    H.label
      ~a:[ ("class", str "radio") ]
      [
        input
          ~a:
            [
              ("type", str "radio");
              ("name", str "font");
              ("checked", dyn (fun () -> fonts () = f));
              on_click (fun () -> set_fonts f);
            ]
          [];
        span ~a:[ ("class", str "dot") ] [];
        text label;
      ]
  in
  let preview_css () = Some (css ()) in
  section
    ~a:[ ("class", str "page workbench"); ("aria-label", str "Workbench") ]
    [
      aside
        ~a:[ ("class", str "wb-meta") ]
        [
          div
            [
              div ~a:[ ("class", str "kicker") ] [ text "Workbench" ];
              h1 [ text "Your CSS, our skeleton" ];
            ];
          H.h "input"
            (props
               [
                 ("type", str "file");
                 ("accept", str ".css,text/css");
                 ("class", str "visually-hidden");
                 ("tabindex", str "-1");
                 ("ref", handler (fun el -> set_picker (Some el)));
                 ( "onChange",
                   handler (fun (e : Web.event) ->
                       Option.iter read_file (Web.first_file (Web.files (Web.target e)))) );
               ])
            [||];
          button
            ~a:
              [
                ("class", str "dropzone");
                ("type", str "button");
                on_click (fun () -> Option.iter Web.click (picker ()));
                ("onDragOver", handler (fun (e : Web.event) -> Web.prevent_default e));
                ( "onDrop",
                  handler (fun (e : Web.event) ->
                      Web.prevent_default e;
                      Option.iter read_file (Web.first_file (Web.data_transfer_files e))) );
              ]
            [
              Icons.upload ~size:26 ();
              span
                ~a:[ ("class", str "dropzone-title") ]
                [
                  show_text (fun () ->
                      if Option.is_some (Store.custom_css ()) then "Replace theme.css"
                      else "Drop theme.css");
                ];
              span
                ~a:[ ("class", str "small muted") ]
                [
                  text "One file. Pure CSS. Targets ";
                  span ~a:[ ("class", str "mono") ] [ text "rz-*" ];
                  text " only.";
                ];
            ];
          field "Theme name"
            (input
               ~a:
                 [
                   ("class", str "input");
                   ("placeholder", str "Tidepool");
                   ("value", dyn name);
                   ("onInput", handler (fun (e : Web.event) -> set_name (Web.value (Web.target e))));
                 ]
               []);
          field "Target" radio_seg;
          field "Fonts"
            (div
               ~a:[ ("class", str "col gap-4 small") ]
               [
                 font_radio Theme_meta.Library "Font Library (CC BY 4.0)";
                 font_radio Theme_meta.Https_cdn "HTTPS CDN @font-face";
               ]);
          field "Author"
            (input
               ~a:
                 [
                   ("class", str "input");
                   ("placeholder", str "Your name");
                   ("value", dyn author);
                   ( "onInput",
                     handler (fun (e : Web.event) -> set_author (Web.value (Web.target e))) );
                 ]
               []);
          div
            ~a:[ ("class", str "wb-submit") ]
            [
              button
                ~a:
                  [
                    ("class", str "btn btn-primary btn-block");
                    ("type", str "button");
                    ("disabled", dyn (fun () -> outcome () = Sending));
                    on_click submit;
                  ]
                [
                  show_text (fun () ->
                      match outcome () with
                      | Sending -> {js|Submitting…|js}
                      | _ -> "Submit to the Garden");
                ];
              show (fun () ->
                  match outcome () with
                  | Accepted id ->
                      p
                        ~a:[ ("class", str "small ok center") ]
                        [
                          text "Submitted as ";
                          span ~a:[ ("class", str "mono") ] [ text id ];
                          text {js| · now in review|js};
                        ]
                  | Rejected why ->
                      p
                        ~a:[ ("class", str "small fail center"); ("role", str "alert") ]
                        [ text why ]
                  | Idle | Sending ->
                      span
                        ~a:[ ("class", str "small muted center") ]
                        [ text {js|MIT licence · reviewed within a week|js} ]);
            ];
        ];
      main
        ~a:[ ("class", str "wb-stage") ]
        [
          div
            ~a:[ ("class", str "row wrap gap-8") ]
            [
              span ~a:[ ("class", str "small muted") ] [ text "Previewing on" ];
              theme_pills ~swatch:No_swatch ~small:true ();
              show (fun () ->
                  match Store.custom_css () with
                  | Some _ ->
                      button
                        ~a:
                          [
                            ("class", str "pill pill-small");
                            ("type", str "button");
                            ("data-on", str "true");
                            on_click (fun () -> Store.set_custom_css None);
                          ]
                        [ text {js|Your theme ×|js} ]
                  | None -> nothing);
              span ~a:[ ("class", str "spacer") ] [];
              view_seg ~small:true ();
              tag "Fixture: Jordan Hale";
            ];
          div
            ~a:[ ("class", str "sheet wb-sheet"); ("style", dyn sheet_style) ]
            [
              Sheet.make
                {
                  css = preview_css;
                  view = Store.view;
                  article = Store.article;
                  primary = true;
                  on_pages = Some Store.set_pages;
                  class_ = "sheet-frame";
                };
            ];
          textarea
            ~a:
              [
                ("class", str "input mono wb-editor");
                ("spellcheck", str "false");
                ("aria-label", str "Theme stylesheet");
                ( "placeholder",
                  str
                    {js|/* rz-target: web */\n.rz-resume { … }  — drop a file above, or start typing to build a theme here|js}
                );
                ("value", dyn (fun () -> Option.value (Store.custom_css ()) ~default:""));
                ("onInput", handler (fun (e : Web.event) -> adopt_css (Web.value (Web.target e))));
              ]
            [];
          (* Off-screen: the long fixture on a Letter sheet, for the page-count check. *)
          div
            ~a:[ ("class", str "measure"); ("aria-hidden", str "true") ]
            [
              Sheet.make
                {
                  css = preview_css;
                  view = (fun () -> View_mode.Paper);
                  article = Store.long_article;
                  primary = false;
                  on_pages = Some (fun n -> set_measured (Some n));
                  class_ = "sheet-frame";
                };
            ];
        ];
      aside
        ~a:[ ("class", str "wb-checks") ]
        [
          div
            ~a:[ ("class", str "row gap-10") ]
            [
              h2 ~a:[ ("class", str "grow") ] [ text "Contract" ];
              show (fun () ->
                  let cs = checks () in
                  tag
                    ~kind:(if Theme_lint.blocking cs then "tag-accent" else "tag-accent-2")
                    (Printf.sprintf "%d / %d" (Theme_lint.passing cs) (List.length cs)));
            ];
          show (fun () -> list (List.map check_row (checks ())));
          div
            ~a:[ ("class", str "contract-card") ]
            [
              div ~a:[ ("class", str "contract-card-title") ] [ text "Class contract v1.0" ];
              text "Real headings, lists, ";
              span ~a:[ ("class", str "mono") ] [ text "<time datetime>" ];
              text ". Read ";
              a
                ~a:
                  [
                    ("href", str Page_about.contract_url);
                    ("target", str "_blank");
                    ("rel", str "noreferrer");
                  ]
                [ text "CLASS-CONTRACT.md" ];
              text {js| · open |js};
              a
                ~a:
                  [
                    ("href", str Page_about.example_url);
                    ("target", str "_blank");
                    ("rel", str "noreferrer");
                  ]
                [ text "example.html" ];
              text ".";
            ];
        ];
    ]
