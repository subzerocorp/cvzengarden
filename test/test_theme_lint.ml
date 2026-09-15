open Rz_shared

let status_of id checks =
  List.find_map (fun (c : Theme_lint.check) -> if c.id = id then Some c.status else None) checks
  |> Option.value ~default:Theme_lint.Pending

let show = function
  | Theme_lint.Pass -> "Pass"
  | Warn -> "Warn"
  | Fail -> "Fail"
  | Pending -> "Pending"

let expect name css id status = Check.equal ~show name status (status_of id (Theme_lint.run css))

let run () =
  Check.suite "theme lint: first-party themes pass" (fun () ->
      List.iter
        (fun id ->
          let css = Check.read ("themes/" ^ id ^ ".css") in
          let checks = Theme_lint.run css in
          Check.is_false (id ^ " has no failing check") (Theme_lint.blocking checks);
          Check.int (id ^ " passes six text checks") 6 (Theme_lint.passing checks))
        [ "nightgarden"; "quarto"; "switchyard" ]);
  Check.suite "theme lint: rules" (fun () ->
      let good =
        "/* rz-target: web */\n\
         .rz-resume { color: red }\n\
         @media print { .rz-name { color: black } }\n\
         html, body { margin: 0 }\n"
      in
      expect "scope pass" good "scope" Pass;
      expect "header pass" good "header" Pass;
      expect "pure pass" good "pure" Pass;
      expect "fonts none" good "fonts" Pass;
      expect "motion none" good "motion" Pass;
      expect "pages pending" good "pages" Pending;
      expect "chrome class fails" "/* rz-target: web */\n.btn { color: red }" "scope" Fail;
      expect "bare tag fails" "/* rz-target: web */\np { margin: 0 }" "scope" Fail;
      expect "chrome ancestor of a contract class fails"
        "/* rz-target: web */\n.theme-switcher .rz-name { color: red }" "scope" Fail;
      expect "chrome button ancestor fails" "/* rz-target: web */\n.btn .rz-name { color: red }"
        "scope" Fail;
      expect "id ancestor fails" "/* rz-target: web */\n#app .rz-name { color: red }" "scope" Fail;
      expect "document ancestor ok" "/* rz-target: web */\nbody .rz-name { color: red }" "scope"
        Pass;
      expect "pseudo on contract ok"
        "/* rz-target: web */\n.rz-bullet:not(:last-child)::after { content: \", \" }" "scope" Pass;
      expect "words: separators pass"
        {js|/* rz-target: web */ .rz-tag:not(:last-child)::after { content: ", " } .rz-contact-label::after { content: " · " }|js}
        "words" Pass;
      expect "words: a name in content fails"
        "/* rz-target: web */\n.rz-name::after { content: \"Jordan Hale\" }" "words" Fail;
      expect "words: a date in content fails"
        "/* rz-target: web */\n.rz-dates::before { content: '2022' }" "words" Fail;
      expect "words: justify-content is not content"
        "/* rz-target: web */\n.rz-header { justify-content: center }" "words" Pass;
      expect "descendant tag under rz ok" "/* rz-target: web */\n.rz-prose p { margin: 0 }" "scope"
        Pass;
      expect "attribute selector ok"
        "/* rz-target: web */\n[data-rz-section=\"skills\"] { margin: 0 }" "scope" Pass;
      expect "keyframes ignored"
        "/* rz-target: web */\n\
         @keyframes x { from { opacity: 0 } to { opacity: 1 } }\n\
         .rz-a{animation:x 1s}\n\
         @media (prefers-reduced-motion: reduce){.rz-a{animation:none}}"
        "scope" Pass;
      expect "font-face ignored"
        "/* rz-target: web */\n@font-face { font-family: X; src: url(fonts/x.woff2) }" "scope" Pass;
      expect "library fonts pass"
        "/* rz-target: web */\n@font-face { font-family: X; src: url(\"fonts/x.woff2\") }" "fonts"
        Pass;
      expect "https fonts pass"
        "/* rz-target: web */\n@import \"https://fonts.googleapis.com/css2?family=X\";" "fonts" Pass;
      expect "http fonts fail" "/* rz-target: web */\n@import url(http://x.example/a.css);" "fonts"
        Fail;
      expect "data uri warns"
        "/* rz-target: web */\n@font-face{src:url(data:font/woff2;base64,AAAA)}" "fonts" Warn;
      expect "missing header fails" ".rz-resume{}" "header" Fail;
      expect "late header warns" ".rz-resume{}\n/* rz-target: print */" "header" Warn;
      expect "script fails" "/* rz-target: web */\n.rz-a{content:\"<script>\"}" "pure" Fail;
      expect "javascript url fails"
        "/* rz-target: web */\n.rz-a{background:url(javascript:alert(1))}" "pure" Fail;
      expect "motion without prm fails" "/* rz-target: web */\n.rz-a{transition:color .2s}" "motion"
        Fail;
      expect "motion with prm passes"
        "/* rz-target: web */\n\
         .rz-a{transition:color .2s}\n\
         @media (prefers-reduced-motion: reduce){.rz-a{transition:none}}"
        "motion" Pass;
      expect "transition none is not motion" "/* rz-target: web */\n.rz-a{transition:none}" "motion"
        Pass;
      Check.string "declared target" "both"
        (Option.value (Theme_lint.declared_target "/* rz-target: both */") ~default:"");
      let measured = Theme_lint.with_pages 4 (Theme_lint.run good) in
      Check.equal ~show "measured pages over limit fails" Fail (status_of "pages" measured);
      Check.equal ~show "measured pages within limit passes" Pass
        (status_of "pages" (Theme_lint.with_pages 3 (Theme_lint.run good))))
