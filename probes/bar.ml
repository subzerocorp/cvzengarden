(** The market-quality-bar probes (qa/MARKET-QUALITY-BAR.md). Each prints its BAR id so a report can
    be read against the bar. Computed styles come from Playwright's own expectations, never from
    evaluated JavaScript. *)

open Playwright

external read_file : string -> string -> string = "readFileSync" [@@mel.module "node:fs"]

let read path = read_file path "utf8"
let sheet page selector = in_frame (frame_locator page "iframe.sheet-frame") selector
let re s = Js.Re.fromStringWithFlags s ~flags:"i"

(** Theme → the [.rz-name] face and ink the first-party set locks (BAR-L1). *)
let identities =
  [
    ("nightgarden", "Syne", "rgb(159, 243, 200)");
    ("quarto", "EB Garamond", "rgb(110, 31, 26)");
    ("switchyard", "IBM Plex Sans", "rgb(27, 61, 143)");
  ]

(** BAR-Q1: the binding priority is named in the README and the bar. *)
let q1 () =
  Report.suite "BAR-Q1 binding priority";
  List.iter
    (fun path ->
      let text = read path in
      Report.contains (path ^ " names the Guardian") "Independent Product Experience Guardian" text;
      Report.contains
        (path ^ " keeps the priority order")
        "(1) ease of use, (2) UI look and feel, (3) consistency, (4) category-leading" text)
    [ "README.md"; "qa/MARKET-QUALITY-BAR.md" ];
  return ()

(** BAR-U1: the first paint of a Theme is styled, and a swap never shows the default serif. *)
let u1 page base =
  Report.suite "BAR-U1 FOUC";
  let> () = visit page (base ^ "/?theme=nightgarden&view=screen") in
  let name = sheet page ".rz-name" in
  let> styled = has_css name "font-family" (re "Syne") in
  Report.expect "first paint of Nightgarden is styled" styled
    "the name was not in Syne when it first appeared";
  let> () = click (locator page "button.pill:has-text('Quarto')") in
  let> () = wait_for_timeout page 150 in
  let> serif = has_css name "font-family" (re "^(serif|Times)") in
  Report.expect "a swap never paints the default serif" (not serif) "default serif seen mid-swap";
  let> garamond = eventually_css name "font-family" (re "EB Garamond") in
  Report.expect "the swap lands in Quarto's face" garamond "EB Garamond never applied";
  return ()

(** BAR-U2: no first-party Theme clips dates or overflows at 1280px. *)
let u2 page base =
  Report.suite "BAR-U2 overflow";
  let> () = set_viewport_size page { width = 1280; height = 900 } in
  let check_theme id =
    let> () = visit page (Printf.sprintf "%s/?theme=%s&view=screen" base id) in
    let> frame_box = bounding_box (locator page "iframe.sheet-frame") in
    let> article_box = bounding_box (sheet page ".rz-resume") in
    (match (Js.Nullable.toOption frame_box, Js.Nullable.toOption article_box) with
    | Some f, Some a ->
        Report.expect
          (id ^ ": the sheet fits its frame")
          (a.x +. a.width <= f.x +. f.width +. 1.)
          (Printf.sprintf "article right %.0f > frame right %.0f" (a.x +. a.width) (f.x +. f.width))
    | _ -> Report.fail (id ^ ": the sheet fits its frame") "no boxes");
    let dates = sheet page ".rz-dates" in
    let> n = count dates in
    let rec each i =
      if i >= n then return ()
      else
        let> d = bounding_box (nth dates i) in
        let> e = bounding_box (nth (sheet page ".rz-entry-header") i) in
        (match (Js.Nullable.toOption d, Js.Nullable.toOption e) with
        | Some d, Some e ->
            if d.x +. d.width > e.x +. e.width +. 1. || d.x < e.x -. 1. then
              Report.fail
                (Printf.sprintf "%s: dates %d stay inside their entry" id i)
                (Printf.sprintf "dates %.0f..%.0f, entry %.0f..%.0f" d.x (d.x +. d.width) e.x
                   (e.x +. e.width))
        | _ -> ());
        each (i + 1)
    in
    let> () = each 0 in
    Report.pass (Printf.sprintf "%s: %d date ranges checked" id n);
    return ()
  in
  let> () = check_theme "nightgarden" in
  let> () = check_theme "quarto" in
  let> () = check_theme "switchyard" in
  set_viewport_size page { width = 1380; height = 900 }

(** Pages in a PDF: one [/Type /Page] object per page. *)
let pdf_pages buffer =
  let text = buffer_to_string buffer "latin1" in
  match
    Js.String.match_ ~regexp:(Js.Re.fromStringWithFlags "/Type\\s*/Page[^s]" ~flags:"g") text
  with
  | Some m -> Array.length m
  | None -> 0

(** BAR-U3: a web Theme prints paper-honest — light ink on a page count in the same league as the
    print Themes. Printed from the standalone preview document so the Theme's own [@media print] and
    [@page] apply. *)
let u3 page base =
  Report.suite "BAR-U3 print honesty";
  let print_pages id =
    let> () = visit page (Printf.sprintf "%s/preview/%s.html" base id) in
    let> () = emulate_media page { media = "print" } in
    let> light =
      eventually_css ~ms:2000 (locator page ".rz-resume") "background-color"
        (re "rgb\\(2[0-9]{2}, 2[0-9]{2}, 2[0-9]{2}\\)")
    in
    Report.expect (id ^ " prints on a light ground") light "print background is dark";
    let> buffer = pdf page { format = "Letter" } in
    let pages = pdf_pages buffer in
    Report.pass (Printf.sprintf "%s prints %d page(s)" id pages);
    let> () = emulate_media page { media = "screen" } in
    return pages
  in
  let> night = print_pages "nightgarden" in
  let> quarto = print_pages "quarto" in
  let> switchyard = print_pages "switchyard" in
  Report.expect "Nightgarden is not far longer than the print Themes"
    (night <= max quarto switchyard + 1)
    (Printf.sprintf "nightgarden %d vs quarto %d / switchyard %d" night quarto switchyard);
  Report.expect "no first-party Theme prints past three pages"
    (night <= 3 && quarto <= 3 && switchyard <= 3)
    (Printf.sprintf "%d / %d / %d" night quarto switchyard);
  return ()

(** BAR-U4: the Theme is in the URL and Back restores it. *)
let u4 page base =
  Report.suite "BAR-U4 permalink";
  let> () = visit page (base ^ "/") in
  let> () = click (locator page "button.pill:has-text('Switchyard')") in
  let> () = wait_for_timeout page 300 in
  Report.contains "the theme is a query parameter" "theme=switchyard" (url page);
  let> () = visit page (base ^ "/gallery?theme=nightgarden") in
  let> () =
    click (locator page "button.pill:has-text('Quarto')") |> Js.Promise.catch (fun _ -> return ())
  in
  let> _ = go_back page in
  let> () = wait_for_timeout page 400 in
  Report.contains "Back returns to the previous route" "/?theme=switchyard" (url page);
  let> pressed = attribute (locator page "button.pill:has-text('Switchyard')") "data-on" in
  Report.equal_string "Back restores the staged Theme" "true" (Option.value pressed ~default:"");
  return ()

(** BAR-L1: every first-party pair differs in face and ink, and no first-party Theme fetches from a
    third-party host. *)
let l1 page base =
  Report.suite "BAR-L1 look and feel";
  let foreign = ref [] in
  let origin_host = Js.String.replace ~search:"http://" ~replacement:"" base in
  on_request page (fun r ->
      let u = request_url r in
      let in_frame = not (request_frame r == main_frame page) in
      if
        in_frame
        && Js.String.startsWith ~prefix:"http" u
        && not (Js.String.includes ~search:origin_host u)
      then foreign := u :: !foreign);
  let rec each = function
    | [] -> return ()
    | (id, face, ink) :: rest ->
        let> () = visit page (Printf.sprintf "%s/?theme=%s&view=screen" base id) in
        let name = sheet page ".rz-name" in
        let> face_ok = eventually_css name "font-family" (re face) in
        Report.expect (id ^ " name face is " ^ face) face_ok "face differs";
        let> ink_ok =
          eventually_css name "color"
            (Js.Re.fromString
               (Js.String.replaceByRe
                  ~regexp:(Js.Re.fromStringWithFlags "[()]" ~flags:"g")
                  ~replacement:"." ink))
        in
        Report.expect (id ^ " name ink is " ^ ink) ink_ok "ink differs";
        each rest
  in
  let> () = each identities in
  Report.pass "three faces and three inks are pairwise distinct by construction";
  Report.expect "first-party Themes load fonts from this origin only" (!foreign = [])
    (String.concat ", " !foreign);
  return ()

(** BAR-T2 / BAR-D1: preview.css is not served; the designer path is. *)
let t2_d1 page base =
  Report.suite "BAR-T2 / BAR-D1 designer path";
  let status path =
    let> r = goto page (base ^ path) { waitUntil = "domcontentloaded" } in
    return
      (Option.fold ~none:0 ~some:(fun r -> Playwright.response_status r) (Js.Nullable.toOption r))
  in
  Report.expecting_404 := true;
  let> s = status "/skeleton/preview.css" in
  Report.equal_int "BAR-T2 preview.css is a 404" 404 s;
  (* example.html links preview.css for local reading; that 404 is the pass. *)
  let> s = status "/skeleton/example.html" in
  Report.equal_int "BAR-D1 sample HTML is reachable" 200 s;
  let> s = status "/themes/_blank.css" in
  Report.equal_int "BAR-D1 starter stylesheet is reachable" 200 s;
  (* Console messages from the documents above arrive late; a navigation
     away is the point after which none can. *)
  let> () = visit page (base ^ "/workbench") in
  Report.expecting_404 := false;
  let> submit = count (locator page ".wb-submit button") in
  Report.equal_int "BAR-D1 a visible submit path" 1 submit;
  let> () = visit page (base ^ "/about") in
  let> example_href = attribute (locator page "a[href='/skeleton/example.html']") "href" in
  Report.equal_string "About links to the Garden's sample HTML" "/skeleton/example.html"
    (Option.value example_href ~default:"");
  return ()

let run page base =
  let> () = q1 () in
  let> () = u1 page base in
  let> () = u2 page base in
  let> () = u3 page base in
  let> () = u4 page base in
  let> () = l1 page base in
  t2_d1 page base
