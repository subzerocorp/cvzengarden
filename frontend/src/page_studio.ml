(** [/studio] — résumé authoring: paste or import JSON Resume, live preview. *)

open Rz_shared
open H
open Ui

let ( let> ) = Web.( let> )

(* ── Actions ─────────────────────────────────────────────────────────── *)

let read_file (file : Js.File.t) =
  (let> text = Js.File.text file in
   Store.set_resume_text text;
   Js.Promise.resolve ())
  |> fun p -> ignore (p : unit Js.Promise.t)

let import_url () =
  match
    Js.Nullable.toOption (Web.prompt Web.window "URL of a JSON Resume (a raw gist works)" "")
  with
  | None | Some "" -> ()
  | Some url ->
      (let> body = Web.get_text url in
       Option.iter Store.set_resume_text body;
       Js.Promise.resolve ())
      |> fun p -> ignore (p : unit Js.Promise.t)

(* ── Views ───────────────────────────────────────────────────────────── *)

let validity () =
  show (fun () ->
      match Store.resume () with
      | Ok _ -> tag ~kind:"tag-accent-2" "Valid JSON Resume"
      | Error _ -> tag ~kind:"tag-accent" "Not valid yet")

let problem () =
  show (fun () ->
      match Store.resume () with
      | Ok _ -> nothing
      | Error e when e.path = "" ->
          div ~a:[ ("class", str "problem"); ("role", str "alert") ] [ text e.message ]
      | Error e ->
          div
            ~a:[ ("class", str "problem"); ("role", str "alert") ]
            [ span ~a:[ ("class", str "mono") ] [ text e.path ]; text ({js| — |js} ^ e.message) ])

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

let file_picker (set_picker : Web.element option -> unit) =
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
    [||]

let tool ?(ghost = false) label action =
  button
    ~a:
      [
        ("class", str (if ghost then "btn btn-ghost btn-sm" else "btn btn-secondary btn-sm"));
        ("type", str "button");
        on_click action;
      ]
    [ text label ]

let toolbar picker =
  div
    ~a:[ ("class", str "row wrap gap-6") ]
    [
      tool "Upload .json" (fun () -> Option.iter Web.click (picker ()));
      tool "Load sample" (fun () -> Store.set_resume_text (Store.sample_long ()));
      tool {js|From URL…|js} import_url;
      tool ~ghost:true "Forget" Store.forget_resume;
    ]

let editor () =
  textarea
    ~a:
      [
        ("class", str "input mono studio-editor");
        ("spellcheck", str "false");
        ("aria-label", str "JSON Resume");
        ("placeholder", str {|{ "basics": { "name": "…" } }|});
        ("value", dyn Store.resume_source);
        ( "onInput",
          handler (fun (e : Web.event) -> Store.set_resume_text (Web.value (Web.target e))) );
      ]
    []

let panel () =
  let picker, set_picker = Solid.signal (None : Web.element option) in
  div
    ~a:[ ("class", str "studio-panel") ]
    [
      div
        ~a:[ ("class", str "row gap-8") ]
        [ h2 ~a:[ ("class", str "grow") ] [ text {js|Your résumé|js} ]; validity () ];
      file_picker set_picker;
      toolbar picker;
      editor ();
      problem ();
      div ~a:[ ("class", str "row wrap gap-6") ] [ counts () ];
      p
        ~a:[ ("class", str "note") ]
        [ text "Stored only in this browser. Nothing leaves the page unless you export." ];
    ]

let make () =
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
          panel ();
          div ~a:[ ("class", str "studio-preview") ] [ primary_sheet ~class_:"studio-sheet" ];
        ];
    ]
