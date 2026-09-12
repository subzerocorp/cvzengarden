open Rz_shared

let render_file path =
  match Resume.of_string (Check.read path) with
  | Ok resume -> Skeleton.render resume
  | Error e -> failwith ("fixture did not decode: " ^ Decode.error_to_string e)

let run () =
  (* example.html carries a designer-facing head comment, a preview.css link
     and blank lines between header blocks; the body's elements are the
     contract. *)
  let from_body html =
    let i = Js.String.indexOf ~search:"<body>" html in
    Js.String.slice ~start:i html |> Js.String.split ~sep:"\n" |> Array.to_list
    |> List.filter (fun line -> Js.String.trim line <> "")
    |> String.concat "\n"
  in
  Check.document "skeleton/resume.json renders skeleton/example.html body byte for byte"
    (from_body (Check.read "skeleton/example.html"))
    (from_body (render_file "skeleton/resume.json"));
  Check.document "skeleton/samples/junior.json renders junior.html byte for byte"
    (Check.read "skeleton/samples/junior.html")
    (render_file "skeleton/samples/junior.json");
  let render json =
    match Resume.of_string json with
    | Ok r -> Skeleton.render_article r
    | Error e -> failwith (Decode.error_to_string e)
  in
  let has needle html = Js.String.includes ~search:needle html in
  let a =
    render
      {|{"basics":{"name":"A","url":"javascript:alert(1)","profiles":[{"network":"Twitter","username":"a","url":"https://"}]}}|}
  in
  Check.is_false "unsafe basics.url is dropped entirely" (has "rz-contact--url" a);
  Check.is_true "profile with unsafe url keeps a span value"
    (has {|<span class="rz-link-value">a</span>|} a);
  Check.is_true "twitter maps to x" (has {|rz-link--x|} a);
  let b = render {|{"work":[{"name":"Acme","startDate":"March 2020"}]}|} in
  Check.is_true "unparseable start renders a span without datetime"
    (has {|<span class="rz-date rz-date--start">March 2020</span>|} b);
  Check.is_false "unparseable start is not current" (has "rz-is-current" b);
  Check.is_true "present span still emitted" (has "rz-date--present" b);
  Check.is_true "slug has no year when start is unparseable" (has {|data-rz-entry="acme"|} b);
  let c =
    render {|{"work":[{"name":"Acme","startDate":"2020"},{"name":"Acme","startDate":"2020"}]}|}
  in
  Check.is_true "slug collisions append -2" (has {|data-rz-entry="acme-2020-2"|} c);
  let d =
    render {|{"education":[{"institution":"X","score":3.7},{"institution":"Y","score":4}]}|}
  in
  Check.is_true "numeric score float" (has "GPA 3.7" d);
  Check.is_true "numeric score int" (has "GPA 4" d);
  let e = render {|{"work":[{"name":"  "},{"url":"https://only.example/x"}]}|} in
  Check.is_false "blank entry omitted" (has {|rz-entry--experience" data-rz-entry="entry|} e);
  Check.is_true "url-only entry uses hostname"
    (has {|<a class="rz-entry-primary-link" href="https://only.example/x">only.example</a>|} e);
  let f = render {|{"interests":[{"name":"A"},{"name":"B","keywords":["k"]}]}|} in
  Check.is_true "interests with keywords become entries" (has {|data-rz-kind="entries"|} f);
  let g = render {|{"basics":{"name":"Z","summary":"one\r\n\r\ntwo"}}|} in
  Check.is_true "CRLF prose splits into paragraphs" (has "<p>one</p>\n      <p>two</p>" g);
  let h = render {|{"basics":{"name":"Q & A <b>"}}|} in
  Check.is_true "text is escaped" (has "Q &amp; A &lt;b&gt;" h);
  Check.string "document title with both" {js|Sam — Dev|js}
    (Skeleton.document_title
       (Result.get_ok (Resume.of_string {|{"basics":{"name":"Sam","label":"Dev"}}|})));
  Check.is_true "inline style is emitted in head"
    (has "<style>\n.rz-name{color:red}\n    </style>"
       (Skeleton.render ~style:".rz-name{color:red}" (Result.get_ok (Resume.of_string "{}"))))
