(** The HTTP surface against an in-memory store, through Hono's own [app.request] — no socket, no
    server. *)

open Rz_shared
open Rz_backend
open Promise

let json_of text = Result.get_ok (Decode.parse_json text)
let obj text = Option.get (Js.Json.decodeObject (json_of text))
let field o key = Js.Dict.get o key
let str o key = Option.bind (field o key) Js.Json.decodeString
let post path body = Hono.request_raw_init path (Js.Json.stringify body)

let good_css =
  "/* rz-target: web */\n\
   .rz-resume { background: #123456; color: #fafafa; font-family: system-ui }\n\
   .rz-name { color: #ffd166 }\n"

let submission ?(css = good_css) name =
  Js.Json.object_
    (Js.Dict.fromList
       [
         ("name", Js.Json.string name);
         ("author", Js.Json.string "Test Author");
         ("target", Js.Json.string "web");
         ("fonts", Js.Json.string "library");
         ("css", Js.Json.string css);
       ])

let run () =
  Check.suite "api" (fun () -> ());
  let db = Db.connect ~url:":memory:" () in
  let> () = Db.migrate db in
  let> () = Seed.run ~demo:true db in
  let app = Api.build db in
  let get path = Hono.request app path in
  let> r = get "/api/health" in
  Check.int "health 200" 200 (Hono.response_status r);
  let> themes = get "/api/themes" in
  let> body = Hono.response_text themes in
  let list = Result.get_ok (Theme_meta.list_of_json (Option.get (field (obj body) "themes"))) in
  Check.int "three officials + three demo submissions" 6 (List.length list);
  Check.is_true "officials come first" ((List.hd list).status = Theme_meta.Official);
  let> one = get "/api/themes/quarto" in
  let> one_body = Hono.response_text one in
  Check.string "theme detail name" "Quarto"
    (Option.value
       (Option.bind
          (Option.bind (field (obj one_body) "theme") Js.Json.decodeObject)
          (fun t -> str t "name"))
       ~default:"");
  let> missing = get "/api/themes/nope" in
  Check.int "unknown theme 404" 404 (Hono.response_status missing);
  let> css = get "/themes/quarto.css" in
  Check.int "official css 200" 200 (Hono.response_status css);
  Check.string "official css content type" "text/css; charset=utf-8"
    (Option.value (Js.Nullable.toOption (Hono.response_header css "content-type")) ~default:"");
  let> css_body = Hono.response_text css in
  Check.is_true "official css served from disk"
    (Js.String.startsWith ~prefix:"/* rz-target: print */" css_body);
  let> demo_css = get "/api/themes/tidepool/css" in
  Check.int "submission css 200" 200 (Hono.response_status demo_css);
  let> sample = get "/api/samples/junior" in
  Check.int "sample 200" 200 (Hono.response_status sample);
  let> render = post "/api/render" (json_of {|{"basics":{"name":"Ada","label":"Engineer"}}|}) app in
  Check.int "render 200" 200 (Hono.response_status render);
  let> render_body = Hono.response_text render in
  Check.string "render title" {js|Ada — Engineer|js}
    (Option.value (str (obj render_body) "title") ~default:"");
  Check.is_true "render html is a document"
    (Js.String.startsWith ~prefix:"<!DOCTYPE html>"
       (Option.value (str (obj render_body) "html") ~default:""));
  let> render_themed =
    post "/api/render?theme=quarto" (json_of {|{"basics":{"name":"Ada"}}|}) app
  in
  let> themed_body = Hono.response_text render_themed in
  Check.is_true "themed render inlines the stylesheet"
    (Js.String.includes ~search:"<style>" (Option.value (str (obj themed_body) "html") ~default:""));
  let> bad_render = post "/api/render" (json_of {|{"work":[{"highlights":[1]}]}|}) app in
  Check.int "invalid resume 400" 400 (Hono.response_status bad_render);
  let> bad_body = Hono.response_text bad_render in
  Check.string "invalid resume path" "work[0].highlights[0]"
    (Option.value
       (Option.bind
          (Option.bind (field (obj bad_body) "error") Js.Json.decodeObject)
          (fun e -> str e "path"))
       ~default:"");
  let> lint =
    post "/api/lint" (Js.Json.object_ (Js.Dict.fromList [ ("css", Js.Json.string ".btn{}") ])) app
  in
  let> lint_body = Hono.response_text lint in
  Check.is_true "lint reports blocking"
    (Option.bind (field (obj lint_body) "blocking") Js.Json.decodeBoolean = Some true);
  let> accepted = post "/api/submissions" (submission "Tidepool") app in
  Check.int "submission 201" 201 (Hono.response_status accepted);
  let> accepted_body = Hono.response_text accepted in
  let accepted_theme =
    Option.get (Option.bind (field (obj accepted_body) "theme") Js.Json.decodeObject)
  in
  Check.string "submission id avoids the seeded tidepool" "tidepool-2"
    (Option.value (str accepted_theme "id") ~default:"");
  Check.string "submission is in review" "in_review"
    (Option.value (str accepted_theme "status") ~default:"");
  Check.string "swatches derived from css" "#123456"
    (match Option.bind (field accepted_theme "swatches") Js.Json.decodeArray with
    | Some [| g; _; _ |] -> Option.value (Js.Json.decodeString g) ~default:""
    | _ -> "");
  let> rejected = post "/api/submissions" (submission ~css:".btn { color: red }" "Bad") app in
  Check.int "failing contract 422" 422 (Hono.response_status rejected);
  let> malformed =
    post "/api/submissions" (Js.Json.object_ (Js.Dict.fromList [ ("name", Js.Json.string "") ])) app
  in
  Check.int "malformed submission 400" 400 (Hono.response_status malformed);
  let> malformed_body = Hono.response_text malformed in
  Check.string "malformed names the field" "name"
    (Option.value
       (Option.bind
          (Option.bind (field (obj malformed_body) "error") Js.Json.decodeObject)
          (fun e -> str e "path"))
       ~default:"");
  let> queue = get "/api/submissions" in
  let> queue_body = Hono.response_text queue in
  let queue_list =
    Result.get_ok (Theme_meta.list_of_json (Option.get (field (obj queue_body) "themes")))
  in
  Check.int "review queue lists four" 4 (List.length queue_list);
  let> spa = get "/gallery" in
  Check.is_true "spa route answers" (List.mem (Hono.response_status spa) [ 200; 503 ]);
  let> nf = get "/api/nothing" in
  Check.int "unknown api route 404" 404 (Hono.response_status nf);
  return ()
