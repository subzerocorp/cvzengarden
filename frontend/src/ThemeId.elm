module ThemeId exposing (fallback, fromQuery, themeFromQuery)

{-| Pure Theme id resolution. Unknown or empty query → Nightgarden.
-}

import Generated.Themes as Themes exposing (Theme)


fallback : String
fallback =
    "nightgarden"


fromQuery : String -> String
fromQuery raw =
    let
        id =
            raw
                |> String.trim
                |> String.toLower
    in
    case Themes.themeById id of
        Just theme ->
            theme.id

        Nothing ->
            fallback


themeFromQuery : String -> Theme
themeFromQuery raw =
    Themes.themeById (fromQuery raw)
        |> Maybe.withDefault fallbackTheme


fallbackTheme : Theme
fallbackTheme =
    case Themes.themeById fallback of
        Just theme ->
            theme

        Nothing ->
            case Themes.all of
                first :: _ ->
                    first

                [] ->
                    { id = fallback
                    , name = "Nightgarden"
                    , href = "themes/nightgarden.css"
                    , target = Themes.Web
                    }
