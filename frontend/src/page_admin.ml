(** [/admin] — the review queue. A reviewer token unlocks the moderation API; every Submission is
    listed with its contract checks, can be staged on the sheet, and approved or rejected with a
    note. *)

open Rz_shared
open H
open Ui

let ( let> ) = Web.( let> )
let ( let** ) = Option.bind

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

type view = {
  state : state Solid.signal;
  draft : string Solid.signal;  (** the token being typed *)
  busy : string Solid.signal;  (** the theme id with a decision in flight *)
}
(** The page's signals. *)

let new_view () =
  {
    state = Solid.signal (if Store.admin_token () = "" then Locked else Loading);
    draft = Solid.signal (Store.admin_token ());
    busy = Solid.signal "";
  }

(* ── Calculations on the API's answers ───────────────────────────────── *)

let auth_headers () = [ ("Authorization", "Bearer " ^ Store.admin_token ()) ]

let decode_entry json =
  let** o = Js.Json.decodeObject json in
  let** theme =
    Option.bind (Js.Dict.get o "theme") (fun t ->
        Result.to_option (Theme_meta.decode ~path:"theme" t))
  in
  let checks =
    Option.value ~default:[]
      (Option.bind (Js.Dict.get o "checks") (fun c ->
           Result.to_option (Decode.list Theme_lint.decode ~path:"checks" c)))
  in
  let text key = Option.bind (Js.Dict.get o key) Js.Json.decodeString in
  Some { theme; checks; note = text "reviewNote"; reviewed_at = text "reviewedAt" }

let decode_queue body =
  let** json = Result.to_option (Decode.parse_json body) in
  let** o = Js.Json.decodeObject json in
  let** entries = Option.bind (Js.Dict.get o "queue") Js.Json.decodeArray in
  Some (List.filter_map decode_entry (Array.to_list entries))

let error_message body fallback =
  let message =
    let** json = Result.to_option (Decode.parse_json body) in
    let** o = Js.Json.decodeObject json in
    let** e = Option.bind (Js.Dict.get o "error") Js.Json.decodeObject in
    Option.bind (Js.Dict.get e "message") Js.Json.decodeString
  in
  Option.value message ~default:fallback

let state_of_queue (status, body) =
  match (status, decode_queue body) with
  | 200, Some entries -> Ready entries
  | 0, _ -> Refused "The Garden did not answer."
  | _ -> Refused (error_message body "The queue could not be loaded.")

(* ── Actions ─────────────────────────────────────────────────────────── *)

let load view () =
  if Store.admin_token () = "" then snd view.state Locked
  else (
    snd view.state Loading;
    (let> response = Web.request ~method_:"GET" ~headers:(auth_headers ()) "/api/admin/queue" in
     snd view.state (state_of_queue response);
     Js.Promise.resolve ())
    |> ignore)

let ask_note (t : Theme_meta.t) verb =
  if verb = "reject" then
    Js.Nullable.toOption
      (Web.prompt Web.window ("Why is " ^ t.name ^ " not ready? (sent to the author)") "")
  else Some ""

let post_decision view (t : Theme_meta.t) verb note =
  snd view.busy t.id;
  let body =
    Js.Json.stringify (Js.Json.object_ (Js.Dict.fromList [ ("note", Js.Json.string note) ]))
  in
  let url = Printf.sprintf "/api/admin/themes/%s/%s" t.id verb in
  (let> status, text =
     Web.request ~method_:"POST"
       ~headers:(("Content-Type", "application/json") :: auth_headers ())
       ~body url
   in
   snd view.busy "";
   if status = 200 then (
     Theme_css.forget t.id;
     load view ();
     Store.load_themes () |> ignore)
   else snd view.state (Refused (error_message text "The decision was not recorded."));
   Js.Promise.resolve ())
  |> ignore

let decide view t verb = Option.iter (post_decision view t verb) (ask_note t verb)

let unlock view () =
  Store.remember_admin_token (fst view.draft ());
  load view ()

let forget view () =
  snd view.draft "";
  Store.remember_admin_token "";
  snd view.state Locked

(* ── Views ───────────────────────────────────────────────────────────── *)

let status_tag (t : Theme_meta.t) =
  let kind =
    match t.status with
    | Theme_meta.Approved -> "tag-accent-2"
    | Theme_meta.Rejected -> "tag-accent"
    | _ -> "tag-neutral"
  in
  tag ~kind (Theme_meta.status_label t.status)

let check_chip (c : Theme_lint.check) =
  span
    ~a:[ ("class", str "queue-check"); ("title", str c.note) ]
    [ Page_workbench.status_icon c.status; text c.title ]

let row_details e =
  let t = e.theme in
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
      div ~a:[ ("class", str "queue-checks") ] (List.map check_chip e.checks);
      (match e.note with
      | Some note when note <> "" -> p ~a:[ ("class", str "queue-note") ] [ text ("Note: " ^ note) ]
      | _ -> nothing);
      (match e.reviewed_at with
      | Some at -> p ~a:[ ("class", str "small muted") ] [ text ("Reviewed " ^ at) ]
      | None -> nothing);
    ]

let decision_button view (t : Theme_meta.t) ~verb ~label ~class_ ~done_ =
  button
    ~a:
      [
        ("class", str class_);
        ("type", str "button");
        ("data-action", str verb);
        ("disabled", dyn (fun () -> fst view.busy () = t.id || t.status = done_));
        on_click (fun () -> decide view t verb);
      ]
    [ text label ]

let row_actions view (t : Theme_meta.t) =
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
      decision_button view t ~verb:"approve" ~label:"Approve" ~class_:"btn btn-primary btn-sm"
        ~done_:Theme_meta.Approved;
      decision_button view t ~verb:"reject" ~label:{js|Reject…|js} ~class_:"btn btn-ghost btn-sm"
        ~done_:Theme_meta.Rejected;
    ]

let row view e =
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
      row_details e;
      row_actions view t;
    ]

let token_form view =
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
            ("value", dyn (fst view.draft));
            ("onInput", handler (fun (e : Web.event) -> snd view.draft (Web.value (Web.target e))));
            ( "onKeyDown",
              handler (fun (e : Web.event) -> if Web.key e = "Enter" then unlock view ()) );
          ]
        [];
      button
        ~a:
          [
            ("class", str "btn btn-primary btn-sm"); ("type", str "button"); on_click (unlock view);
          ]
        [ text "Unlock" ];
      button
        ~a:[ ("class", str "btn btn-ghost btn-sm"); ("type", str "button"); on_click (forget view) ]
        [ text "Forget token" ];
      span ~a:[ ("class", str "small muted") ] [ text "Kept in this browser only." ];
    ]

let queue_view view =
  show (fun () ->
      match fst view.state () with
      | Locked ->
          p
            ~a:[ ("class", str "queue-empty") ]
            [ text "Enter the reviewer token to load the queue." ]
      | Loading -> p ~a:[ ("class", str "queue-empty") ] [ text {js|Loading…|js} ]
      | Refused why ->
          p ~a:[ ("class", str "queue-empty fail"); ("role", str "alert") ] [ text why ]
      | Ready [] ->
          p ~a:[ ("class", str "queue-empty") ] [ text "Nothing to review. The Garden is quiet." ]
      | Ready entries -> list (List.map (row view) entries))

let head view =
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
                "Every Submission, its contract checks, and a decision. Approved themes join the \
                 Garden; rejected ones leave the Gallery with a note for the author.";
            ];
        ];
      token_form view;
    ]

let staged_bar () =
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
    ]

let make () =
  let view = new_view () in
  load view ();
  section
    ~a:[ ("class", str "page admin"); ("aria-label", str "Review queue") ]
    [
      head view;
      div ~a:[ ("class", str "queue") ] [ queue_view view ];
      staged_bar ();
      primary_sheet ~class_:"gallery-sheet";
    ]
