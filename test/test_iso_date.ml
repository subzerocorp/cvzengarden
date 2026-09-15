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
      eq "leap 2024" (Some ("2024-02-29", "February 29, 2024")) (date "2024-02-29"))
