module ThemeId exposing (FromQuery(..), fallback, fallbackTheme, fromQuery, themeFromQuery, themeFromResult)

{-| Pure Theme id resolution.

`fromQuery` distinguishes a known Theme id, an unknown raw value, and an
absent/empty `theme` param. History and URL rewriting stay in `ports.js`.
-}

import Generated.Themes as Themes exposing (Theme)


type FromQuery
    = Known String
    | Unknown String
    | Absent


fallback : String
fallback =
    "nightgarden"


fromQuery : String -> FromQuery
fromQuery raw =
    let
        trimmed =
            String.trim raw
    in
    if trimmed == "" then
        Absent

    else
        case Themes.themeById (String.toLower trimmed) of
            Just theme ->
                Known theme.id

            Nothing ->
                Unknown raw


themeFromQuery : String -> Theme
themeFromQuery raw =
    themeFromResult (fromQuery raw)


themeFromResult : FromQuery -> Theme
themeFromResult result =
    case result of
        Known id ->
            Themes.themeById id
                |> Maybe.withDefault fallbackTheme

        Unknown _ ->
            fallbackTheme

        Absent ->
            fallbackTheme


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
                    -- Only reachable with an empty catalog, which the generator
                    -- refuses to produce. A synthesised theme has no designer,
                    -- so it carries no byline rather than an invented one.
                    { id = fallback
                    , name = "Nightgarden"
                    , href = "themes/nightgarden.css"
                    , target = Themes.Web
                    , author = ""
                    , url = Nothing
                    }
