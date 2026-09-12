(** Lucide-style inline icons at stroke 2.75 (design system rule). Each is a function: a hyperscript
    thunk builds its element once, so every use needs a fresh one. *)

let svg ?(size = 16) ?(stroke = "2.75") paths =
  H.h "svg"
    (H.props
       [
         ("width", H.int size);
         ("height", H.int size);
         ("viewBox", H.str "0 0 24 24");
         ("fill", H.str "none");
         ("stroke", H.str "currentColor");
         ("stroke-width", H.str stroke);
         ("stroke-linecap", H.str "round");
         ("stroke-linejoin", H.str "round");
         ("aria-hidden", H.str "true");
       ])
    (Array.of_list (List.map (fun d -> H.h "path" (H.props [ ("d", H.str d) ]) [||]) paths))

let menu () = svg ~size:18 [ "M4 6h16M4 12h16M4 18h16" ]

let download ?size () =
  svg ?size [ "M12 3v12m0 0 4-4m-4 4-4-4M4 17v2a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-2" ]

let upload ?size () =
  svg ?size [ "M12 16V4m0 0 4 4m-4-4-4 4M4 17v2a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-2" ]

let star () = svg [ "m12 3 2.9 5.9 6.5.9-4.7 4.6 1.1 6.5L12 17.8 6.2 20.9l1.1-6.5L2.6 9.8l6.5-.9z" ]
let check () = svg ~size:12 ~stroke:"3.5" [ "M20 6 9 17l-5-5" ]
let warn () = svg ~size:12 ~stroke:"3.5" [ "M12 8v5m0 4h.01" ]
let cross () = svg ~size:12 ~stroke:"3.5" [ "M18 6 6 18M6 6l12 12" ]
let clock () = svg ~size:12 ~stroke:"3.5" [ "M12 6v6l4 2" ]
