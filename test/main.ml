let () =
  Check.suite "skeleton" Test_skeleton.run;
  Test_calculations.run ();
  Test_theme_lint.run ();
  Test_api.run ()
  |> Js.Promise.then_ (fun () ->
      Check.report ();
      Js.Promise.resolve ())
  |> Js.Promise.catch (fun err ->
      Check.fail "api suite raised" (Option.value (Js.Json.stringifyAny err) ~default:"unknown");
      Check.report ();
      Js.Promise.resolve ())
  |> ignore
