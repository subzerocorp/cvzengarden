module Generated.Themes exposing (Target(..), Theme, all, hrefFor, themeById)


{-| Generated from the Garden theme directory. Do not edit by hand — run `npm run gen`.
-}


type Target
    = Web
    | Print
    | Both


type alias Theme =
    { id : String
    , name : String
    , href : String
    , target : Target
    , author : String
    , url : Maybe String
    }


all : List Theme
all =
    [ { id = "nightgarden"
      , name = "Nightgarden"
      , href = "themes/nightgarden.css"
      , target = Web
      , author = "ResumeZen"
      , url = Just "https://github.com/subzerocorp/cvzengarden"
      }
    ,
    { id = "quarto"
      , name = "Quarto"
      , href = "themes/quarto.css"
      , target = Print
      , author = "ResumeZen"
      , url = Just "https://github.com/subzerocorp/cvzengarden"
      }
    ,
    { id = "switchyard"
      , name = "Switchyard"
      , href = "themes/switchyard.css"
      , target = Both
      , author = "ResumeZen"
      , url = Just "https://github.com/subzerocorp/cvzengarden"
      }
    ]


themeById : String -> Maybe Theme
themeById id =
    all
        |> List.filter (\theme -> theme.id == id)
        |> List.head


hrefFor : String -> Maybe String
hrefFor id =
    themeById id
        |> Maybe.map .href
