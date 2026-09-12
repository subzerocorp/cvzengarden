open Rz_shared

let date raw = Option.map (fun d -> (Iso_date.datetime d, Iso_date.visible d)) (Iso_date.parse raw)
let show_pair = function None -> "None" | Some (a, b) -> Printf.sprintf "Some (%s, %s)" a b

let run () =
  Check.suite "iso dates" (fun () ->
      let eq name e a = Check.equal ~show:show_pair name e a in
      eq "year" (Some ("2020", "2020")) (date "2020");
      eq "year-month" (Some ("2022-03", "March 2022")) (date "2022-03");
      eq "full" (Some ("2022-01-15", "January 15, 2022")) (date "2022-01-15");
      eq "trimmed" (Some ("2020", "2020")) (date " 2020 ");
      eq "timestamp T" (Some ("2023-05-31", "May 31, 2023")) (date "2023-05-31T09:00:00Z");
      eq "timestamp space" (Some ("2020-05-31", "May 31, 2020")) (date "2020-05-31 09:00");
      List.iter
        (fun raw -> eq ("rejects " ^ raw) None (date raw))
        [
          "2020-1";
          "2020-00";
          "2020-13";
          "2021-02-29";
          "2020-02-30";
          "2021-04-31";
          "2020-05-00";
          "2020-13-01";
          "2020-01-32";
          "2020-01-01-01";
          "2020 (approx)";
          "2020 ish";
          "2020-05 9:00";
          "2020T";
          {js|２０２０|js};
          {js|日本語|js};
          "March 2020";
          "Present";
          "";
          "-";
          "1900-02-29";
        ];
      eq "leap 2000" (Some ("2000-02-29", "February 29, 2000")) (date "2000-02-29");
      eq "leap 2024" (Some ("2024-02-29", "February 29, 2024")) (date "2024-02-29"));
  Check.suite "slugs" (fun () ->
      Check.string "basic" "acme-studio-2022" (Slug.slugify "Acme Studio-2022");
      Check.string "dashes" "css-design-awards-site-of-the-day-2021"
        (Slug.slugify {js|CSS Design Awards — Site of the Day-2021|js});
      Check.string "comma" "minutes-plain-2019" (Slug.slugify "Minutes, Plain-2019");
      Check.string "unicode" {js|café-ñ|js} (Slug.slugify {js|Café Ñ!|js});
      Check.string "emoji only" "" (Slug.slugify {js|🔥🔥|js});
      let used = Slug.fresh () in
      Check.string "entry slug" "acme-2022"
        (Slug.entry_slug used ~primary:"Acme" ~start_year:(Some 2022));
      Check.string "entry slug collision" "acme-2022-2"
        (Slug.entry_slug used ~primary:"Acme" ~start_year:(Some 2022));
      Check.string "entry slug collision 3" "acme-2022-3"
        (Slug.entry_slug used ~primary:"Acme" ~start_year:(Some 2022));
      Check.string "empty falls back" "entry-2022"
        (Slug.entry_slug used ~primary:"" ~start_year:(Some 2022));
      Check.string "no year" "entry" (Slug.entry_slug used ~primary:{js|🔥🔥|js} ~start_year:None);
      let skills = Slug.fresh () in
      Check.string "skill fallback" "skill" (Slug.skill_slug skills {js|🎨|js});
      Check.string "skill fallback 2" "skill-2" (Slug.skill_slug skills "");
      Check.string "skill" "front-end" (Slug.skill_slug skills "Front-end"));
  Check.suite "safe urls" (fun () ->
      let so = Check.string_option in
      so "https kept" (Some "https://verify.example/abc")
        (Safe_url.safe_href "https://verify.example/abc");
      so "http trimmed" (Some "http://example.com") (Safe_url.safe_href " http://example.com ");
      so "bare host" (Some "https://example.com/me") (Safe_url.safe_href "example.com/me");
      so "protocol relative" (Some "https://example.com") (Safe_url.safe_href "//example.com");
      so "mailto" (Some "mailto:a@b.example") (Safe_url.safe_href "mailto:a@b.example");
      so "tel" (Some "tel:+1555") (Safe_url.safe_href "tel:+1555");
      List.iter
        (fun raw -> so ("rejects " ^ raw) None (Safe_url.safe_href raw))
        [
          "https://";
          "http://";
          "//";
          "";
          "   ";
          "https:///path";
          "javascript:alert(1)";
          "JAVASCRIPT:alert(1)";
          "data:text/html,hi";
          "ftp://files.example";
          "vbscript:x";
          "mailto:";
          "tel: ";
        ];
      Check.string "hostname" "jordanhale.example" (Safe_url.hostname "https://jordanhale.example");
      Check.string "hostname path" "www.linkedin.com"
        (Safe_url.hostname "https://www.linkedin.com/in/jordanhale");
      Check.string "hostname query" "a.example" (Safe_url.hostname "http://a.example?x=1");
      Check.string "hostname fragment" "a.example" (Safe_url.hostname "a.example#top");
      Check.string "hostname empty" "" (Safe_url.hostname "https://"));
  Check.suite "skeleton helpers" (fun () ->
      Check.string "tel strips punctuation" "tel:+15035550142" (Skeleton.tel_href "+1 503 555 0142");
      Check.string "tel parens" "tel:5035550142" (Skeleton.tel_href "(503) 555-0142");
      Check.string "gpa numeric" "GPA 3.8" (Skeleton.format_score "3.8");
      Check.string "gpa text" "First Class" (Skeleton.format_score "First Class");
      Check.string "profile github" "github" (Skeleton.profile_type "GitHub");
      Check.string "profile unknown" "other" (Skeleton.profile_type "UnknownNet"));
  Check.suite "decode" (fun () ->
      let err json =
        match Resume.of_string json with Error e -> Decode.error_to_string e | Ok _ -> "ok"
      in
      Check.string "wrong highlight type" "work[0].highlights[1]: expected a string, found a number"
        (err {|{"work":[{"highlights":["a",2]}]}|});
      Check.string "score list rejected"
        "education[0].score: expected a string or number, found an array"
        (err {|{"education":[{"score":[3.7]}]}|});
      Check.string "basics not object" "basics: expected an object, found a string"
        (err {|{"basics":"x"}|});
      Check.is_true "malformed json reports a message" (err "{" <> "ok");
      Check.string "null field is absent" "ok" (err {|{"basics":null,"work":null}|});
      match Resume.of_string (Check.read "skeleton/resume.json") with
      | Ok r ->
          Check.int "work count" 3 (List.length r.work);
          Check.int "section counts" 11 (List.length (Resume.section_counts r))
      | Error e -> Check.fail "fixture decodes" (Decode.error_to_string e))
