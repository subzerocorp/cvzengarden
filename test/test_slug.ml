open Rz_shared

let run () =
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
      Check.string "skill" "front-end" (Slug.skill_slug skills "Front-end"))
