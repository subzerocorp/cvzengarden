(** [/studio] — résumé authoring: paste or import JSON Resume, live preview. *)

open Rz_shared
open H
open Ui

let ( let> ) = Web.( let> )

let read_file (file : Js.File.t) =
  (let> text = Js.File.text file in
   Store.set_resume_text text;
   Js.Promise.resolve ())
  |> ignore

let import_url () =
  match
    Js.Nullable.toOption (Web.prompt Web.window "URL of a JSON Resume (a raw gist works)" "")
  with
  | None | Some "" -> ()
  | Some url ->
      (let> body = Web.get_text url in
       Option.iter Store.set_resume_text body;
       Js.Promise.resolve ())
      |> ignore

let validity () =
  show (fun () ->
      match Store.resume () with
      | Ok _ -> tag ~kind:"tag-accent-2" "Valid JSON Resume"
      | Error _ -> tag ~kind:"tag-accent" "Not valid yet")

let problem () =
  show (fun () ->
      match Store.resume () with
      | Ok _ -> nothing
      | Error e ->
          div
            ~a:[ ("class", str "problem"); ("role", str "alert") ]
            [
              (if e.path = "" then nothing else span ~a:[ ("class", str "mono") ] [ text e.path ]);
              text (if e.path = "" then e.message else {js| — |js} ^ e.message);
            ])

let counts () =
  show (fun () ->
      match Store.resume () with
      | Error _ -> nothing
      | Ok r ->
          list
            ((if Option.is_some r.basics then [ tag "basics" ] else [])
            @ List.map
                (fun (name, n) -> tag (Printf.sprintf "%s %s %d" name {js|·|js} n))
                (Resume.section_counts r)))

let file_input ~accept on_file =
  input
    ~a:
      [
        ("type", str "file");
        ("accept", str accept);
        ("class", str "visually-hidden");
        ("tabindex", str "-1");
        ( "onChange",
          handler (fun (e : Web.event) ->
              Option.iter on_file (Web.first_file (Web.files (Web.target e)))) );
      ]
    []

let make () =
  let picker, set_picker = Solid.signal (None : Web.element option) in
  section
    ~a:[ ("class", str "page studio"); ("aria-label", str "Studio") ]
    [
      div
        ~a:[ ("class", str "studio-bar") ]
        [
          h1 [ text "Studio" ];
          theme_pills ~with_target:true ();
          span ~a:[ ("class", str "spacer") ] [];
          view_seg ();
          pdf_button ~icon:false ();
        ];
      div
        ~a:[ ("class", str "studio-body") ]
        [
          div
            ~a:[ ("class", str "studio-panel") ]
            [
              div
                ~a:[ ("class", str "row gap-8") ]
                [ h2 ~a:[ ("class", str "grow") ] [ text {js|Your résumé|js} ]; validity () ];
              div
                ~a:[ ("class", str "row wrap gap-6") ]
                [
                  H.h "input"
                    (props
                       [
                         ("type", str "file");
                         ("accept", str ".json,application/json");
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
                        ("class", str "btn btn-secondary btn-sm");
                        ("type", str "button");
                        on_click (fun () -> Option.iter Web.click (picker ()));
                      ]
                    [ text "Upload .json" ];
                  button
                    ~a:
                      [
                        ("class", str "btn btn-secondary btn-sm");
                        ("type", str "button");
                        on_click (fun () -> Store.set_resume_text (Store.sample_long ()));
                      ]
                    [ text "Load sample" ];
                  button
                    ~a:
                      [
                        ("class", str "btn btn-secondary btn-sm");
                        ("type", str "button");
                        on_click import_url;
                      ]
                    [ text {js|From URL…|js} ];
                  button
                    ~a:
                      [
                        ("class", str "btn btn-ghost btn-sm");
                        ("type", str "button");
                        on_click Store.forget_resume;
                      ]
                    [ text "Forget" ];
                ];
              textarea
                ~a:
                  [
                    ("class", str "input mono studio-editor");
                    ("spellcheck", str "false");
                    ("aria-label", str "JSON Resume");
                    ("placeholder", str {|{ "basics": { "name": "…" } }|});
                    ("value", dyn Store.resume_source);
                    ( "onInput",
                      handler (fun (e : Web.event) ->
                          Store.set_resume_text (Web.value (Web.target e))) );
                  ]
                [];
              problem ();
              div ~a:[ ("class", str "row wrap gap-6") ] [ counts () ];
              p
                ~a:[ ("class", str "note") ]
                [ text "Stored only in this browser. Nothing leaves the page unless you export." ];
            ];
          div ~a:[ ("class", str "studio-preview") ] [ primary_sheet ~class_:"studio-sheet" ];
        ];
    ]
