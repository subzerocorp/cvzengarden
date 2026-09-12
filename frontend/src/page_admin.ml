(** [/admin] — the review queue. A reviewer token unlocks the moderation API; every Submission is
    listed with its contract checks, can be staged on the sheet, and approved or rejected with a
    note. *)

open Rz_shared
open H
open Ui

let ( let> ) = Web.( let> )

type entry = {
  theme : Theme_meta.t;
  checks : Theme_lint.check list;
  note : string option;
  reviewed_at : string option;
}

type state =
  | Locked  (** no token entered yet *)
  | Loading
  | Ready of entry list
  | Refused of string

let auth_headers () = [ ("Authorization", "Bearer " ^ Store.admin_token ()) ]

let decode_entry json =
  let ( let* ) = Option.bind in
  let* o = Js.Json.decodeObject json in
  let* theme =
    Option.bind (Js.Dict.get o "theme") (fun t ->
        Result.to_option (Theme_meta.decode ~path:"theme" t))
  in
  let checks =
    match
      Option.bind (Js.Dict.get o "checks") (fun c ->
          Result.to_option (Decode.list Theme_lint.decode ~path:"checks" c))
    with
    | Some checks -> checks
    | None -> []
  in
  let text key = Option.bind (Js.Dict.get o key) Js.Json.decodeString in
  Some { theme; checks; note = text "reviewNote"; reviewed_at = text "reviewedAt" }

let decode_queue body =
  match Decode.parse_json body with
  | Ok json -> (
      match
        Option.bind (Js.Json.decodeObject json) (fun o ->
            Option.bind (Js.Dict.get o "queue") Js.Json.decodeArray)
      with
      | Some entries -> Some (Array.to_list entries |> List.filter_map decode_entry)
      | None -> None)
  | Error _ -> None

let error_message body fallback =
  match Decode.parse_json body with
  | Ok json -> (
      match
        Option.bind (Js.Json.decodeObject json) (fun o ->
            Option.bind (Js.Dict.get o "error") Js.Json.decodeObject)
      with
      | Some e ->
          Option.value
            (Option.bind (Js.Dict.get e "message") Js.Json.decodeString)
            ~default:fallback
      | None -> fallback)
  | Error _ -> fallback

let make () =
  let state, set_state = Solid.signal (if Store.admin_token () = "" then Locked else Loading) in
  let draft, set_draft = Solid.signal (Store.admin_token ()) in
  let busy, set_busy = Solid.signal "" in
  let load () =
    if Store.admin_token () = "" then set_state Locked
    else (
      set_state Loading;
      (let> status, body =
         Web.request ~method_:"GET" ~headers:(auth_headers ()) "/api/admin/queue"
       in
       (match (status, decode_queue body) with
       | 200, Some entries -> set_state (Ready entries)
       | 0, _ -> set_state (Refused "The Garden did not answer.")
       | _ -> set_state (Refused (error_message body "The queue could not be loaded.")));
       Js.Promise.resolve ())
      |> ignore)
  in
  let decide (t : Theme_meta.t) verb =
    let note =
      if verb = "reject" then
        Js.Nullable.toOption
          (Web.prompt Web.window ("Why is " ^ t.name ^ " not ready? (sent to the author)") "")
      else Some ""
    in
    match note with
    | None -> ()
    | Some note ->
        set_busy t.id;
        let body =
          Js.Json.stringify (Js.Json.object_ (Js.Dict.fromList [ ("note", Js.Json.string note) ]))
        in
        (let> status, text =
           Web.request ~method_:"POST"
             ~headers:(("Content-Type", "application/json") :: auth_headers ())
             ~body
             (Printf.sprintf "/api/admin/themes/%s/%s" t.id verb)
         in
         set_busy "";
         if status = 200 then (
           Theme_css.forget t.id;
           load ();
           Store.load_themes () |> ignore)
         else set_state (Refused (error_message text "The decision was not recorded."));
         Js.Promise.resolve ())
        |> ignore
  in
  load ();
  let status_icon = function
    | Theme_lint.Pass -> span ~a:[ ("class", str "check-icon ok") ] [ Icons.check () ]
    | Theme_lint.Warn -> span ~a:[ ("class", str "check-icon warn") ] [ Icons.warn () ]
    | Theme_lint.Fail -> span ~a:[ ("class", str "check-icon fail") ] [ Icons.cross () ]
    | Theme_lint.Pending -> span ~a:[ ("class", str "check-icon pending") ] [ Icons.clock () ]
  in
  let status_tag (t : Theme_meta.t) =
    tag
      ~kind:
        (match t.status with
        | Theme_meta.Approved -> "tag-accent-2"
        | Theme_meta.Rejected -> "tag-accent"
        | _ -> "tag-neutral")
      (Theme_meta.status_label t.status)
  in
  let row e =
    let t = e.theme in
    div
      ~a:
        [
          ("class", str "queue-row");
          ("data-theme", str t.id);
          ("data-status", str (Theme_meta.status_key t.status));
        ]
      [
        span ~a:[ ("class", str "featured-disc"); ("style", str (conic t.swatches)) ] [];
        div
          ~a:[ ("class", str "queue-main") ]
          [
            div
              ~a:[ ("class", str "row wrap gap-8") ]
              [
                span ~a:[ ("class", str "featured-name") ] [ text t.name ];
                status_tag t;
                tag ~kind:"tag-accent-2" (Theme_meta.target_label t.target);
                span
                  ~a:[ ("class", str "muted small") ]
                  [ text ("by " ^ t.author ^ {js| · |js} ^ t.id ^ ".css") ];
              ];
            div
              ~a:[ ("class", str "queue-checks") ]
              (List.map
                 (fun (c : Theme_lint.check) ->
                   span
                     ~a:[ ("class", str "queue-check"); ("title", str c.note) ]
                     [ status_icon c.status; text c.title ])
                 e.checks);
            (match e.note with
            | Some note when note <> "" ->
                p ~a:[ ("class", str "queue-note") ] [ text ({js|Note: |js} ^ note) ]
            | _ -> nothing);
            (match e.reviewed_at with
            | Some at -> p ~a:[ ("class", str "small muted") ] [ text ("Reviewed " ^ at) ]
            | None -> nothing);
          ];
        div
          ~a:[ ("class", str "queue-actions") ]
          [
            button
              ~a:
                [
                  ("class", str "btn btn-secondary btn-sm");
                  ("type", str "button");
                  on_click (fun () -> Store.pick_theme t.id);
                ]
              [ text "Stage" ];
            button
              ~a:
                [
                  ("class", str "btn btn-primary btn-sm");
                  ("type", str "button");
                  ("data-action", str "approve");
                  ("disabled", dyn (fun () -> busy () = t.id || t.status = Theme_meta.Approved));
                  on_click (fun () -> decide t "approve");
                ]
              [ text "Approve" ];
            button
              ~a:
                [
                  ("class", str "btn btn-ghost btn-sm");
                  ("type", str "button");
                  ("data-action", str "reject");
                  ("disabled", dyn (fun () -> busy () = t.id || t.status = Theme_meta.Rejected));
                  on_click (fun () -> decide t "reject");
                ]
              [ text {js|Reject…|js} ];
          ];
      ]
  in
  let token_form =
    div
      ~a:[ ("class", str "row wrap gap-8 queue-token") ]
      [
        input
          ~a:
            [
              ("class", str "input queue-token-input");
              ("type", str "password");
              ("placeholder", str "Reviewer token");
              ("aria-label", str "Reviewer token");
              ("value", dyn draft);
              ("onInput", handler (fun (e : Web.event) -> set_draft (Web.value (Web.target e))));
              ( "onKeyDown",
                handler (fun (e : Web.event) ->
                    if Web.key e = "Enter" then (
                      Store.remember_admin_token (draft ());
                      load ())) );
            ]
          [];
        button
          ~a:
            [
              ("class", str "btn btn-primary btn-sm");
              ("type", str "button");
              on_click (fun () ->
                  Store.remember_admin_token (draft ());
                  load ());
            ]
          [ text "Unlock" ];
        button
          ~a:
            [
              ("class", str "btn btn-ghost btn-sm");
              ("type", str "button");
              on_click (fun () ->
                  set_draft "";
                  Store.remember_admin_token "";
                  set_state Locked);
            ]
          [ text "Forget token" ];
        span ~a:[ ("class", str "small muted") ] [ text "Kept in this browser only." ];
      ]
  in
  section
    ~a:[ ("class", str "page admin"); ("aria-label", str "Review queue") ]
    [
      div
        ~a:[ ("class", str "gallery-head") ]
        [
          div
            [
              h1 [ text "Review queue" ];
              p
                ~a:[ ("class", str "lede") ]
                [
                  text
                    "Every Submission, its contract checks, and a decision. Approved themes join \
                     the Garden; rejected ones leave the Gallery with a note for the author.";
                ];
            ];
          token_form;
        ];
      div
        ~a:[ ("class", str "queue") ]
        [
          show (fun () ->
              match state () with
              | Locked ->
                  p
                    ~a:[ ("class", str "queue-empty") ]
                    [ text "Enter the reviewer token to load the queue." ]
              | Loading -> p ~a:[ ("class", str "queue-empty") ] [ text {js|Loading…|js} ]
              | Refused why ->
                  p ~a:[ ("class", str "queue-empty fail"); ("role", str "alert") ] [ text why ]
              | Ready [] ->
                  p
                    ~a:[ ("class", str "queue-empty") ]
                    [ text "Nothing to review. The Garden is quiet." ]
              | Ready entries -> list (List.map row entries));
        ];
      div
        ~a:[ ("class", str "gallery-selected") ]
        [
          h2
            ~a:[ ("class", str "gallery-selected-title") ]
            [
              text "Staged: ";
              show_text (fun () ->
                  Option.fold ~none:""
                    ~some:(fun (t : Theme_meta.t) -> t.name)
                    (Store.selected_theme ()));
            ];
          view_seg ();
        ];
      primary_sheet ~class_:"gallery-sheet";
    ]
