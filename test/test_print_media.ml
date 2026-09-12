open Rz_shared

let run () =
  Check.suite "print media emulation" (fun () ->
      let css =
        "@import \"https://x.example/a.css\";\n\
         .rz-a { color: red }\n\
         @media screen { .rz-a { color: blue } }\n\
         @media print { .rz-a { color: black } @page { size: A4; margin: 12mm 15mm } }\n\
         @media (prefers-reduced-motion: reduce) { .rz-a { animation: none } }\n\
         @media print, (prefers-reduced-motion: reduce) { .rz-b { animation: none } }\n\
         @keyframes k { from { opacity: 0 } }\n"
      in
      let paper = Print_media.emulate css in
      let has needle = Js.String.includes ~search:needle paper in
      Check.is_true "plain rules stay" (has ".rz-a { color: red }");
      Check.is_false "screen rules are dropped" (has "color: blue");
      Check.is_true "print rules are unwrapped" (has ".rz-a { color: black }");
      Check.is_false "no @media print wrapper remains" (has "@media print");
      Check.is_true "feature queries are kept"
        (has "@media (prefers-reduced-motion: reduce) { .rz-a { animation: none } }");
      Check.is_true "print-or-feature lists unwrap" (has ".rz-b { animation: none }");
      Check.is_true "keyframes stay" (has "@keyframes k { from { opacity: 0 } }");
      Check.is_true "statements stay" (has "@import \"https://x.example/a.css\";");
      let box = Print_media.page_box css in
      Check.is_true "page size read" (box.size = Print_media.A4);
      Check.string "page margin read" "12mm 15mm" box.margin;
      Check.string "default margin" "0.5in" (Print_media.page_box ".rz-a{}").margin;
      Check.is_true "default size is Letter" ((Print_media.page_box "").size = Print_media.Letter);
      List.iter
        (fun id ->
          let theme = Check.read ("themes/" ^ id ^ ".css") in
          let paper = Print_media.emulate theme in
          Check.is_false
            (id ^ " paper css has no @media print left")
            (Js.String.includes ~search:"@media print" paper);
          Check.is_false
            (id ^ " paper css has no @media screen left")
            (Js.String.includes ~search:"@media screen" paper))
        [ "nightgarden"; "quarto"; "switchyard" ];
      Check.string "font urls are anchored to the Library"
        "src: url(\"/themes/fonts/x.woff2\"), url('/themes/fonts/y.woff2'), \
         url(/themes/fonts/z.woff2)"
        (Sandbox_doc.absolute_font_urls
           "src: url(\"fonts/x.woff2\"), url('fonts/y.woff2'), url(fonts/z.woff2)");
      Check.is_true "switchyard prints on A4"
        ((Print_media.page_box (Check.read "themes/switchyard.css")).size = Print_media.A4))
