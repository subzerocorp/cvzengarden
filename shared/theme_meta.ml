(** Theme metadata: what the Gallery, the Switcher and the store agree on. The CSS itself is a
    separate asset; this is only the card. *)

type target = Screen | Paper | Both

let target_key = function Screen -> "web" | Paper -> "print" | Both -> "both"

let target_of_key = function
  | "web" | "screen" -> Some Screen
  | "print" | "paper" -> Some Paper
  | "both" -> Some Both
  | _ -> None

let target_label = function Screen -> "Screen" | Paper -> "Paper" | Both -> "Screen + paper"

let target_supports target (view : View_mode.t) =
  match (target, view) with
  | Both, _ | Screen, View_mode.Screen | Paper, View_mode.Paper -> true
  | _ -> false

type status = Official | Approved | In_review | Rejected

let status_key = function
  | Official -> "official"
  | Approved -> "approved"
  | In_review -> "in_review"
  | Rejected -> "rejected"

let status_of_key = function
  | "official" -> Some Official
  | "approved" -> Some Approved
  | "in_review" -> Some In_review
  | "rejected" -> Some Rejected
  | _ -> None

let status_label = function
  | Official -> "First-party"
  | Approved -> "Approved"
  | In_review -> "In review"
  | Rejected -> "Rejected"

type fonts = Library | Https_cdn

let fonts_key = function Library -> "library" | Https_cdn -> "https"

let fonts_of_key = function
  | "library" -> Some Library
  | "https" | "cdn" -> Some Https_cdn
  | _ -> None

type t = {
  id : string;
  name : string;
  author : string;
  author_url : string option;
  target : target;
  fonts : fonts;
  swatches : string * string * string;  (** ground, ink, accent *)
  badge : string;
  bg : string;
  status : status;
}

let file t = t.id ^ ".css"
let is_public t = match t.status with Official | Approved -> true | In_review | Rejected -> false

(** Listed in the Gallery: public Themes plus the review queue. *)
let is_listed t = t.status <> Rejected

let officials =
  [
    {
      id = "nightgarden";
      name = "Nightgarden";
      author = "ResumeZen";
      author_url = None;
      target = Screen;
      fonts = Library;
      swatches = ("#0c1220", "#9ff3c8", "#c7b4ff");
      badge = "#2563eb";
      bg = "#0c1220";
      status = Official;
    };
    {
      id = "quarto";
      name = "Quarto";
      author = "ResumeZen";
      author_url = None;
      target = Paper;
      fonts = Library;
      swatches = ("#f3ead8", "#6e1f1a", "#8a7460");
      badge = "#d97706";
      bg = "#f3ead8";
      status = Official;
    };
    {
      id = "switchyard";
      name = "Switchyard";
      author = "ResumeZen";
      author_url = None;
      target = Both;
      fonts = Library;
      swatches = ("#dce6d4", "#1b3d8f", "#b45309");
      badge = "#16a34a";
      bg = "#dce6d4";
      status = Official;
    };
  ]

let default_id = "quarto"
let find_official id = List.find_opt (fun t -> t.id = id) officials

(* ── JSON ───────────────────────────────────────────────────────────────── *)

let to_json t =
  let s = Js.Json.string in
  let g, i, a = t.swatches in
  let fields =
    [
      ("id", s t.id);
      ("name", s t.name);
      ("author", s t.author);
      ("authorUrl", Option.fold ~none:Js.Json.null ~some:s t.author_url);
      ("target", s (target_key t.target));
      ("fonts", s (fonts_key t.fonts));
      ("swatches", Js.Json.stringArray [| g; i; a |]);
      ("badge", s t.badge);
      ("bg", s t.bg);
      ("status", s (status_key t.status));
      ("file", s (file t));
    ]
  in
  Js.Json.object_ (Js.Dict.fromList fields)

let ( let* ) = Result.bind

let required name (dec : 'a Decode.t) ~path o =
  let* v = Decode.field name dec ~path o in
  match v with
  | Some v -> Ok v
  | None -> Error { Decode.path = Decode.join_field path name; message = "is required" }

let keyed name of_key ~path o =
  let* raw = required name Decode.string ~path o in
  match of_key raw with
  | Some v -> Ok v
  | None -> Error { Decode.path = Decode.join_field path name; message = "unknown value " ^ raw }

let decode : t Decode.t =
  Decode.obj (fun ~path o ->
      let* id = required "id" Decode.string ~path o in
      let* name = required "name" Decode.string ~path o in
      let* author = required "author" Decode.string ~path o in
      let* author_url = Decode.field "authorUrl" Decode.string ~path o in
      let* target = keyed "target" target_of_key ~path o in
      let* fonts = keyed "fonts" fonts_of_key ~path o in
      let* swatches = Decode.field_list "swatches" Decode.string ~path o in
      let* swatches =
        match swatches with
        | [ g; i; a ] -> Ok (g, i, a)
        | _ ->
            Error
              {
                Decode.path = Decode.join_field path "swatches";
                message = "expected exactly three colours";
              }
      in
      let* badge = required "badge" Decode.string ~path o in
      let* bg = required "bg" Decode.string ~path o in
      let* status = keyed "status" status_of_key ~path o in
      Ok { id; name; author; author_url; target; fonts; swatches; badge; bg; status })

let list_of_json json = Decode.list decode ~path:"themes" json
