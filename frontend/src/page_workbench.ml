(** [/workbench] — Theme authoring: metadata, live preview, contract checks. The draft lives in a
    record of signals; each piece of the page is a small function over it. *)

open Rz_shared
open H
open Ui

let ( let> ) = Web.( let> )

type outcome = Idle | Sending | Accepted of string | Rejected of string

type draft = {
  name : string Solid.signal;
  author : string Solid.signal;
  target : Theme_meta.target Solid.signal;
  fonts : Theme_meta.fonts Solid.signal;
  outcome : outcome Solid.signal;
  measured : int option Solid.signal;  (** Letter pages of the long fixture *)
  picker : Web.element option Solid.signal;  (** the hidden file input *)
}
(** The submission being prepared. *)

let new_draft () =
  {
    name = Solid.signal "";
    author = Solid.signal "";
    target = Solid.signal Theme_meta.Screen;
    fonts = Solid.signal Theme_meta.Library;
    outcome = Solid.signal Idle;
    measured = Solid.signal None;
    picker = Solid.signal None;
  }

(** The stylesheet under test: the dropped file, or the staged first-party Theme. *)
let css_under_test () =
  match Store.custom_css () with
  | Some css -> css
  | None -> Option.value (Theme_css.get (Store.theme_id ())) ~default:""

let checks_of draft =
  Solid.create_memo (fun () ->
      let base = Theme_lint.run (css_under_test ()) in
      match fst draft.measured () with Some n -> Theme_lint.with_pages n base | None -> base)

(* ── Actions ─────────────────────────────────────────────────────────── *)

let adopt_css draft text =
  Store.set_custom_css (Some text);
  Option.iter
    (fun t -> Option.iter (snd draft.target) (Theme_meta.target_of_key t))
    (Theme_lint.declared_target text);
  snd draft.outcome Idle

let strip_css_suffix = Js.String.replaceByRe ~regexp:(Js.Re.fromString "\\.css$") ~replacement:""

let read_file draft (file : Js.File.t) =
  (let> text = Js.File.text file in
   adopt_css draft text;
   if fst draft.name () = "" then snd draft.name (strip_css_suffix (Js.File.name file));
   Js.Promise.resolve ())
  |> fun p -> ignore (p : unit Js.Promise.t)

let submission_body draft ~css ~pages =
  Js.Json.stringify
    (Js.Json.object_
       (Js.Dict.fromList
          [
            ("name", Js.Json.string (fst draft.name ()));
            ("author", Js.Json.string (fst draft.author ()));
            ("target", Js.Json.string (Theme_meta.target_key (fst draft.target ())));
            ("fonts", Js.Json.string (Theme_meta.fonts_key (fst draft.fonts ())));
            ("css", Js.Json.string css);
            ("measuredPages", Js.Json.number (float_of_int pages));
          ]))

let json_field o key = Option.bind (Js.Dict.get o key) Js.Json.decodeString

(** What the Garden answered, as an outcome. *)
let outcome_of_response (status, text) =
  let body = Option.bind (Result.to_option (Decode.parse_json text)) Js.Json.decodeObject in
  match status with
  | 201 ->
      let theme =
        Option.bind body (fun o -> Option.bind (Js.Dict.get o "theme") Js.Json.decodeObject)
      in
      Accepted (Option.value (Option.bind theme (fun t -> json_field t "id")) ~default:"")
  | 0 -> Rejected "The Garden did not answer. Try again in a moment."
  | _ -> (
      let error =
        Option.bind body (fun o -> Option.bind (Js.Dict.get o "error") Js.Json.decodeObject)
      in
      match error with
      | Some e ->
          let message = Option.value (json_field e "message") ~default:"Rejected" in
          Rejected
            (Option.fold ~none:message ~some:(fun p -> p ^ " " ^ message) (json_field e "path"))
      | None -> Rejected "Rejected")

(** Why the draft cannot be sent yet, if anything. *)
let blocker draft checks =
  match (Store.custom_css (), fst draft.measured ()) with
  | None, _ -> Some "Drop or paste a stylesheet first."
  | _, None -> Some "Wait for the page count to be measured."
  | Some _, Some _ when Js.String.trim (fst draft.name ()) = "" -> Some "Give the theme a name."
  | Some _, Some _ when Js.String.trim (fst draft.author ()) = "" ->
      Some "Add your name so the theme is credited."
  | Some _, Some _ when Theme_lint.blocking (checks ()) ->
      Some "Fix the failing contract checks first."
  | _ -> None

let submit draft checks () =
  match (blocker draft checks, Store.custom_css (), fst draft.measured ()) with
  | Some why, _, _ -> snd draft.outcome (Rejected why)
  | None, Some css, Some pages ->
      snd draft.outcome Sending;
      (let> response = Web.post_json "/api/submissions" (submission_body draft ~css ~pages) in
       let outcome = outcome_of_response response in
       snd draft.outcome outcome;
       (match outcome with
       | Accepted _ -> ignore (Store.load_themes () : unit Js.Promise.t)
       | _ -> ());
       Js.Promise.resolve ())
      |> fun p -> ignore (p : unit Js.Promise.t)
  | None, _, _ -> ()

(* ── Views ───────────────────────────────────────────────────────────── *)

let status_icon = function
  | Theme_lint.Pass -> span ~a:[ ("class", str "check-icon ok") ] [ Icons.check () ]
  | Theme_lint.Warn -> span ~a:[ ("class", str "check-icon warn") ] [ Icons.warn () ]
  | Theme_lint.Fail -> span ~a:[ ("class", str "check-icon fail") ] [ Icons.cross () ]
  | Theme_lint.Pending -> span ~a:[ ("class", str "check-icon pending") ] [ Icons.clock () ]

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

let field label control = div ~a:[ ("class", str "field") ] [ H.label [ text label ]; control ]

let text_input ~placeholder (value, set) =
  input
    ~a:
      [
        ("class", str "input");
        ("placeholder", str placeholder);
        ("value", dyn value);
        ("onInput", handler (fun (e : Web.event) -> set (Web.value (Web.target e))));
      ]
    []

let target_seg (target, set_target) =
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

let font_radio (fonts, set_fonts) f label =
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

let file_picker draft =
  H.h "input"
    (props
       [
         ("type", str "file");
         ("accept", str ".css,text/css");
         ("class", str "visually-hidden");
         ("tabindex", str "-1");
         ("ref", handler (fun el -> snd draft.picker (Some el)));
         ( "onChange",
           handler (fun (e : Web.event) ->
               Option.iter (read_file draft) (Web.first_file (Web.files (Web.target e)))) );
       ])
    [||]

let dropzone draft =
  button
    ~a:
      [
        ("class", str "dropzone");
        ("type", str "button");
        on_click (fun () -> Option.iter Web.click (fst draft.picker ()));
        ("onDragOver", handler (fun (e : Web.event) -> Web.prevent_default e));
        ( "onDrop",
          handler (fun (e : Web.event) ->
              Web.prevent_default e;
              Option.iter (read_file draft) (Web.first_file (Web.data_transfer_files e))) );
      ]
    [
      Icons.upload ~size:26 ();
      span
        ~a:[ ("class", str "dropzone-title") ]
        [
          show_text (fun () ->
              if Option.is_some (Store.custom_css ()) then "Replace theme.css" else "Drop theme.css");
        ];
      span
        ~a:[ ("class", str "small muted") ]
        [
          text "One file. Pure CSS. Targets ";
          span ~a:[ ("class", str "mono") ] [ text "rz-*" ];
          text " only.";
        ];
    ]

let outcome_line draft =
  show (fun () ->
      match fst draft.outcome () with
      | Accepted id ->
          p
            ~a:[ ("class", str "small ok center") ]
            [
              text "Submitted as ";
              span ~a:[ ("class", str "mono") ] [ text id ];
              text {js| · now in review|js};
            ]
      | Rejected why ->
          p ~a:[ ("class", str "small fail center"); ("role", str "alert") ] [ text why ]
      | Idle | Sending ->
          span
            ~a:[ ("class", str "small muted center") ]
            [ text {js|MIT licence · reviewed within a week|js} ])

let submit_panel draft checks =
  div
    ~a:[ ("class", str "wb-submit") ]
    [
      button
        ~a:
          [
            ("class", str "btn btn-primary btn-block");
            ("type", str "button");
            ("disabled", dyn (fun () -> fst draft.outcome () = Sending));
            on_click (submit draft checks);
          ]
        [
          show_text (fun () ->
              match fst draft.outcome () with
              | Sending -> {js|Submitting…|js}
              | _ -> "Submit to the Garden");
        ];
      outcome_line draft;
    ]

let meta_form draft checks =
  aside
    ~a:[ ("class", str "wb-meta") ]
    [
      div
        [
          div ~a:[ ("class", str "kicker") ] [ text "Workbench" ];
          h1 [ text "Your CSS, our skeleton" ];
        ];
      file_picker draft;
      dropzone draft;
      field "Theme name" (text_input ~placeholder:"Tidepool" draft.name);
      field "Target" (target_seg draft.target);
      field "Fonts"
        (div
           ~a:[ ("class", str "col gap-4 small") ]
           [
             font_radio draft.fonts Theme_meta.Library "Font Library (CC BY 4.0)";
             font_radio draft.fonts Theme_meta.Https_cdn "HTTPS CDN @font-face";
           ]);
      field "Author" (text_input ~placeholder:"Your name" draft.author);
      submit_panel draft checks;
    ]

let preview_bar () =
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
    ]

let editor draft =
  textarea
    ~a:
      [
        ("class", str "input mono wb-editor");
        ("spellcheck", str "false");
        ("aria-label", str "Theme stylesheet");
        ( "placeholder",
          str
            {js|/* rz-target: web */ .rz-resume { … }  — drop a file above, or start typing to build a theme here|js}
        );
        ("value", dyn (fun () -> Option.value (Store.custom_css ()) ~default:""));
        ("onInput", handler (fun (e : Web.event) -> adopt_css draft (Web.value (Web.target e))));
      ]
    []

(** Off-screen: the long fixture on a sheet, for the page-count check. *)
let measure_frame draft css =
  div
    ~a:[ ("class", str "measure"); ("aria-hidden", str "true") ]
    [
      Sheet.make
        {
          css;
          view = (fun () -> View_mode.Paper);
          article = Store.long_article;
          primary = false;
          on_pages = Some (fun n -> snd draft.measured (Some n));
          class_ = "sheet-frame";
        };
    ]

let stage draft =
  let css () = Some (css_under_test ()) in
  main
    ~a:[ ("class", str "wb-stage") ]
    [
      preview_bar ();
      div
        ~a:[ ("class", str "sheet wb-sheet"); ("style", dyn sheet_style) ]
        [
          Sheet.make
            {
              css;
              view = Store.view;
              article = Store.article;
              primary = true;
              on_pages = Some Store.set_pages;
              class_ = "sheet-frame";
            };
        ];
      editor draft;
      measure_frame draft css;
    ]

let contract_card () =
  div
    ~a:[ ("class", str "contract-card") ]
    [
      div ~a:[ ("class", str "contract-card-title") ] [ text "Class contract v1.0" ];
      text "Real headings, lists, ";
      span ~a:[ ("class", str "mono") ] [ text "<time datetime>" ];
      text ". Read ";
      a ~a:[ ("href", str Page_about.contract_url) ] [ text "CLASS-CONTRACT.md" ];
      text {js| · open |js};
      a
        ~a:[ ("href", str Page_about.example_url); ("target", str "_blank") ]
        [ text "example.html" ];
      text ".";
    ]

let check_list checks =
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
      contract_card ();
    ]

let make () =
  let draft = new_draft () in
  let checks = checks_of draft in
  section
    ~a:[ ("class", str "page workbench"); ("aria-label", str "Workbench") ]
    [ meta_form draft checks; stage draft; check_list checks ]
