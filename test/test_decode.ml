open Rz_shared

let run () =
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
