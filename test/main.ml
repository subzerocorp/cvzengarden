let () =
  Check.suite "skeleton" Test_skeleton.run;
  Test_iso_date.run ();
  Test_slug.run ();
  Test_safe_url.run ();
  Test_decode.run ();
  Test_theme_lint.run ();
  Test_print_media.run ();
  Test_api.run ()
  |> Js.Promise.then_ (fun () ->
      Check.report ();
      Js.Promise.resolve ())
  |> Js.Promise.catch (fun err ->
      Check.fail "api suite raised" (Option.value (Js.Json.stringifyAny err) ~default:"unknown");
      Check.report ();
      Js.Promise.resolve ())
  |> fun p -> ignore (p : unit Js.Promise.t)
