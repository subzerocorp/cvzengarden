open Rz_shared

let run () =
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
      Check.string "hostname empty" "" (Safe_url.hostname "https://"))
