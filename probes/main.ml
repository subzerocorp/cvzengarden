(** Browser probes: the five routes and the review queue, driven through Playwright against a server
    this runner starts. Run with [just probe]. *)

open Playwright

external mkdir : string -> unit = "mkdirSync" [@@mel.module "node:fs"]

let shots_dir = "probes/shots"

let shot page name =
  Js.Promise.then_
    (fun _ -> return ())
    (screenshot page { path = shots_dir ^ "/" ^ name ^ ".png"; fullPage = false })

(* A small but complete Theme: styled on screen, compact on paper so the long
   fixture stays within the three-page limit. *)
let good_css =
  String.concat "\n"
    [
      "/* rz-target: both */";
      ".rz-resume { padding: 2rem; background: #204050; color: #f0f4f8; font-family: system-ui; \
       line-height: 1.4 }";
      ".rz-name { color: #ffd166; margin: 0 }";
      ".rz-section { margin: 0 0 .8rem } .rz-entry { margin: 0 0 .5rem } .rz-entries, .rz-bullets, \
       .rz-tags, .rz-skill-groups, .rz-skill-list, .rz-meta-list, .rz-contact-list, .rz-link-list \
       { margin: 0; padding: 0; list-style: none }";
      ".rz-section-title, .rz-entry-primary, .rz-skill-group-name { margin: 0 0 .2rem } \
       .rz-entry-secondary, .rz-dates, .rz-location, .rz-score, .rz-skill-level, .rz-prose p { \
       margin: 0 }";
      "@media (prefers-reduced-motion: reduce) { .rz-resume { transition: none } }";
      "@media print { @page { size: letter; margin: 0.4in 0.5in } .rz-resume { padding: 0; \
       background: #fff; color: #111; font-size: 9pt; line-height: 1.2 } .rz-name { font-size: \
       16pt } .rz-section-title { font-size: 9pt } .rz-section { margin: 0 0 4pt } .rz-entry { \
       margin: 0 0 3pt } .rz-entry-header { display: grid; grid-template-columns: minmax(0, 1fr) \
       max-content; column-gap: 8pt } .rz-entry-primary, .rz-entry-secondary, .rz-location, \
       .rz-score { grid-column: 1 } .rz-dates { grid-column: 2; grid-row: 1 } .rz-contact-list, \
       .rz-link-list, .rz-tags, .rz-skill-list { display: flex; flex-wrap: wrap; gap: 0 8pt } \
       .rz-skill-groups { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 2pt 8pt } \
       .rz-bullet { margin: 0 } }";
    ]

let errors : string list ref = ref []

let watch page =
  on_console page (fun m ->
      let text = message_text m in
      (* Blocked font hosts and the deliberate wrong-token probe are expected. *)
      let expected =
        Js.String.includes ~search:"ERR_FAILED" text
        || Js.String.includes ~search:"status of 401" text
        (* BAR-T2: preview.css must 404; example.html links it and the browser
           reports that late, after the probe has moved on. *)
        || Js.String.endsWith ~suffix:"/skeleton/preview.css" (message_location m).url
      in
      if message_type m = "error" && not expected then
        errors := (text ^ " @ " ^ (message_location m).url) :: !errors);
  on_page_error page (fun e -> errors := ("pageerror: " ^ error_message e) :: !errors);
  (* Name the URL behind any unexpected 404, which the console message omits. *)
  on_response page (fun r ->
      if response_status r = 404 && not !Report.expecting_404 then
        errors := ("404: " ^ response_url r) :: !errors)

let sheet page selector = in_frame (frame_locator page "iframe.sheet-frame") selector

let garden page base =
  Report.suite "garden";
  let> () = visit page (base ^ "/") in
  let> n = count (sheet page ".rz-resume") in
  Report.equal_int "the sheet holds one skeleton" 1 n;
  let> name = text (sheet page ".rz-name") in
  Report.equal_string {js|the sample résumé is drawn|js} "Jordan Hale" name;
  let> pages = text (locator page ".pages") in
  Report.contains "page estimate for Letter" "page" pages;
  let> () = click (locator page "button.pill:has-text('Nightgarden')") in
  let> () = wait_for_timeout page 400 in
  Report.contains "picking a theme updates the URL" "theme=nightgarden" (url page);
  let> () = click (locator page ".seg2 button:has-text('Screen')") in
  let> () = wait_for_timeout page 400 in
  Report.contains "view toggle updates the URL" "view=screen" (url page);
  let> pages = text (locator page ".pages") in
  Report.contains "screen view label" "Screen view" pages;
  let> () = shot page "garden-nightgarden-screen" in
  let> () = click (locator page "button[aria-label='Menu']") in
  let> () = wait_for_timeout page 300 in
  let> drawer = count (locator page ".drawer") in
  Report.equal_int "the drawer opens" 1 drawer;
  let> () = shot page "drawer" in
  let> () = press page "Escape" in
  let> () = wait_for_timeout page 300 in
  let> drawer = count (locator page ".drawer") in
  Report.equal_int "Escape closes the drawer" 0 drawer;
  return ()

let gallery page base =
  Report.suite "gallery";
  let> () = visit page (base ^ "/gallery") in
  let> official = count (locator page ".card-theme") in
  Report.equal_int "three first-party cards" 3 official;
  let> review = count (locator page ".card-review") in
  Report.equal_int "three review-queue cards" 3 review;
  let> thumbs = count (locator page ".thumb iframe") in
  Report.equal_int "each card has a live thumbnail" 3 thumbs;
  let> () = click (locator page ".card-theme:has-text('Switchyard')") in
  let> () = wait_for_timeout page 300 in
  let> pressed = text (locator page ".card-theme[aria-pressed='true'] .card-theme-name") in
  Report.equal_string "clicking a card stages it" "Switchyard" pressed;
  let> () = shot page "gallery" in
  return ()

let about page base =
  Report.suite "about";
  let> () = visit page (base ^ "/about?theme=quarto") in
  let> staged = text (locator page ".staged-title") in
  Report.equal_string "staged theme card follows the URL" "Quarto" staged;
  let> featured = count (locator page ".featured") in
  Report.equal_int "featured community themes" 3 featured;
  return ()

let studio page base =
  Report.suite "studio";
  let> () = visit page (base ^ "/studio") in
  let> () =
    fill
      (locator page "textarea.studio-editor")
      {|{"basics":{"name":"Probe Person"},"work":[{"name":"X","highlights":[1]}]}|}
  in
  let> () = wait_for_timeout page 300 in
  let> problem = text (locator page ".problem") in
  Report.contains "schema error names the path" "work[0].highlights[0]" problem;
  let> () =
    fill
      (locator page "textarea.studio-editor")
      {|{"basics":{"name":"Probe Person","label":"Tester"},"skills":[{"name":"Probing","keywords":["a","b"]}]}|}
  in
  let> () = wait_for_timeout page 400 in
  let> valid = text (first (locator page ".studio-panel .tag")) in
  Report.equal_string {js|valid résumé is tagged|js} "Valid JSON Resume" valid;
  let> name = text (sheet page ".rz-name") in
  Report.equal_string {js|the sheet redraws the typed résumé|js} "Probe Person" name;
  let> () = shot page "studio" in
  return ()

let workbench page base =
  Report.suite "workbench";
  let> () = visit page (base ^ "/workbench") in
  let> () =
    fill
      (locator page "textarea.wb-editor")
      "/* rz-target: web */\n.btn { color: red }\n.rz-resume { transition: color .2s }"
  in
  let> () = wait_for_timeout page 600 in
  let> scope_fail = count (locator page ".check:has-text('Targets rz-*') .check-icon.fail") in
  Report.equal_int "a chrome selector fails the scope check" 1 scope_fail;
  let> motion_fail = count (locator page ".check:has-text('Reduced motion') .check-icon.fail") in
  Report.equal_int "unguarded motion fails" 1 motion_fail;
  let> () = fill (locator page "textarea.wb-editor") good_css in
  let> () = wait_for_timeout page 1500 in
  let> fails = count (locator page ".check-icon.fail") in
  let> rows = count (locator page ".check") in
  let rec dump i =
    if i >= rows then return ()
    else
      let> title = text (nth (locator page ".check-title") i) in
      let> note = text (nth (locator page ".check-note") i) in
      let> icon = attribute (nth (locator page ".check-icon") i) "class" in
      Report.pass (Printf.sprintf "  [%s] %s: %s" (Option.value icon ~default:"") title note);
      dump (i + 1)
  in
  let> () = if fails > 0 then dump 0 else return () in
  Report.equal_int "a clean stylesheet has no failing check" 0 fails;
  let> submit_tag = text (locator page ".wb-checks .tag") in
  Report.pass ("contract summary: " ^ submit_tag);
  let> pages_ok = count (locator page ".check:has-text('prints in') .check-icon.ok") in
  Report.equal_int "page count is measured on the long fixture" 1 pages_ok;
  let> () = fill (locator page ".wb-meta input[placeholder='Tidepool']") "Probe Theme" in
  let> () = fill (locator page ".wb-meta input[placeholder='Your name']") "Probe Author" in
  let> () = click (locator page ".wb-submit button") in
  let> () = wait_for_timeout page 900 in
  let> outcome = text (locator page ".wb-submit .ok") in
  Report.contains "submission is accepted into review" "Submitted as" outcome;
  let> () = shot page "workbench" in
  let> () = visit page (base ^ "/gallery") in
  let> review = count (locator page ".card-review") in
  Report.equal_int "the new submission shows in the Gallery queue" 4 review;
  return ()

let admin page base =
  Report.suite "review queue";
  on_dialog page (fun d -> ignore (dialog_accept d "Contrast on tags is under 3:1"));
  let> () = visit page (base ^ "/admin") in
  let> locked = text (locator page ".queue-empty") in
  Report.contains "locked until a token is entered" "reviewer token" locked;
  let> () = fill (locator page ".queue-token-input") "wrong" in
  let> () = click (locator page ".queue-token button:has-text('Unlock')") in
  let> () = wait_for_timeout page 500 in
  let> refused = text (locator page ".queue-empty") in
  Report.contains "a wrong token is refused" "token" refused;
  let> () = fill (locator page ".queue-token-input") Server.token in
  let> () = click (locator page ".queue-token button:has-text('Unlock')") in
  let> () = wait_for_timeout page 600 in
  let> rows = count (locator page ".queue-row") in
  Report.equal_int "the queue lists every submission" 4 rows;
  let> () =
    click (locator page ".queue-row[data-theme='probe-theme'] button[data-action='approve']")
  in
  let> () = wait_for_timeout page 800 in
  let> status = attribute (locator page ".queue-row[data-theme='probe-theme']") "data-status" in
  Report.equal_string "approving moves the row to approved" "approved"
    (Option.value status ~default:"");
  let> () = click (locator page ".queue-row[data-theme='orchard'] button[data-action='reject']") in
  let> () = wait_for_timeout page 800 in
  let> note = text (locator page ".queue-row[data-theme='orchard'] .queue-note") in
  Report.contains "rejecting records the note" "Contrast on tags" note;
  let> () = shot page "admin" in
  let> () = visit page (base ^ "/gallery") in
  let> official = count (locator page ".card-theme") in
  Report.equal_int "an approved theme gets a Gallery card" 4 official;
  let> review = count (locator page ".card-review") in
  Report.equal_int "a rejected theme leaves the Gallery" 2 review;
  return ()

let narrow page base =
  Report.suite "narrow viewport";
  let> () = set_viewport_size page { width = 400; height = 800 } in
  let> () = visit page (base ^ "/") in
  let> box = bounding_box (locator page ".pillbar") in
  (match Js.Nullable.toOption box with
  | Some b ->
      Report.expect "the pill bar fits a 400px viewport"
        (b.x >= 0. && b.x +. b.width <= 400.)
        (Printf.sprintf "x=%.0f width=%.0f" b.x b.width)
  | None -> Report.fail "the pill bar fits a 400px viewport" "no pill bar");
  let> () = shot page "garden-narrow" in
  return ()

let run () =
  let> server = Server.start () in
  let base = server.base in
  let> browser = launch chromium in
  let> page = new_page browser { viewport = { width = 1380; height = 900 } } in
  watch page;
  let> () =
    route page (Js.Re.fromString "fonts\\.googleapis\\.com|fonts\\.gstatic\\.com") (fun r ->
        ignore (abort r))
  in
  let> () = garden page base in
  let> () = gallery page base in
  let> () = about page base in
  let> () = studio page base in
  let> () = workbench page base in
  let> () = admin page base in
  let> () = narrow page base in
  let> () = Bar.run page base in
  Report.suite "console";
  Report.expect "no console errors or page errors" (!errors = []) (String.concat "\n    " !errors);
  let> () = close browser in
  Server.stop server;
  return ()

let () =
  (try mkdir shots_dir with _ -> ());
  run ()
  |> Js.Promise.then_ (fun () ->
      Report.finish ();
      return ())
  |> Js.Promise.catch (fun err ->
      Report.fail "probe run raised" (Option.value (Js.Json.stringifyAny err) ~default:"unknown");
      Report.finish ();
      return ())
  |> ignore
