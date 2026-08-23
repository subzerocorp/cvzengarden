port module Main exposing (main)

{-| ResumeZen Garden chrome: live Theme switcher around a sandboxed Skeleton.

The iframe `src` is constant (`sandbox.html`). Switching a Theme changes only
the Theme stylesheet href inside that document. `.rz-resume` inner HTML is
never rewritten. Chrome class names never use the `rz-` prefix.

Theme id resolution is pure (`ThemeId`). History and the iframe stylesheet
are isolated actions (ports).
-}

import Browser
import Generated.Themes as Themes exposing (Target(..), Theme)
import Html exposing (Html, button, div, h1, h2, iframe, li, p, span, ul)
import Html.Attributes as Attr exposing (attribute, class, classList, id, src, title, type_)
import Html.Events exposing (onClick)
import Html.Keyed as Keyed
import Json.Decode as Decode
import ThemeId



-- PORTS


port setThemeHref : String -> Cmd msg


port setPreviewMedia : String -> Cmd msg


port printGarden : () -> Cmd msg


port pushThemeQuery : String -> Cmd msg


port onThemeQuery : (String -> msg) -> Sub msg



-- MODEL


type Preview
    = Screen
    | PrintPreview


type Filter
    = FilterAll
    | FilterWeb
    | FilterPrint


type Appearance
    = FollowSystem
    | PinLight
    | PinDark


type alias Flags =
    { prefersDark : Bool
    , themeQuery : String
    }


type alias Model =
    { selectedId : String
    , preview : Preview
    , filter : Filter
    , appearance : Appearance
    , prefersDark : Bool
    }



-- INIT


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        theme =
            ThemeId.themeFromQuery flags.themeQuery

        model =
            { selectedId = theme.id
            , preview = Screen
            , filter = FilterAll
            , appearance = FollowSystem
            , prefersDark = flags.prefersDark
            }
    in
    ( model
    , Cmd.batch
        [ setThemeHref theme.href
        , setPreviewMedia "screen"
        ]
    )



-- UPDATE


type Msg
    = SelectTheme String
    | ThemeQueryChanged String
    | SetPreview Preview
    | SetFilter Filter
    | SetAppearance Appearance
    | SystemPrefersDark Bool
    | PrintRequested


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SelectTheme id ->
            applyTheme id True model

        ThemeQueryChanged raw ->
            applyTheme (ThemeId.fromQuery raw) False model

        SetPreview preview ->
            ( { model | preview = preview }
            , setPreviewMedia (previewMedia preview)
            )

        SetFilter filter ->
            ( { model | filter = filter }, Cmd.none )

        SetAppearance appearance ->
            ( { model | appearance = appearance }, Cmd.none )

        SystemPrefersDark prefersDark ->
            ( { model | prefersDark = prefersDark }, Cmd.none )

        PrintRequested ->
            ( model, printGarden () )


applyTheme : String -> Bool -> Model -> ( Model, Cmd Msg )
applyTheme id pushQuery model =
    case Themes.themeById id of
        Nothing ->
            applyTheme ThemeId.fallback pushQuery model

        Just theme ->
            let
                next =
                    { model | selectedId = theme.id }

                hrefCmd =
                    setThemeHref theme.href

                historyCmd =
                    if pushQuery then
                        pushThemeQuery theme.id

                    else
                        Cmd.none
            in
            ( next
            , Cmd.batch [ hrefCmd, historyCmd ]
            )


previewMedia : Preview -> String
previewMedia preview =
    case preview of
        Screen ->
            "screen"

        PrintPreview ->
            "print"



-- VIEW


view : Model -> Html Msg
view model =
    let
        selected =
            ThemeId.themeFromQuery model.selectedId
    in
    div
        [ class "app-shell"
        , attribute "data-theme" (themeMode model)
        , attribute "data-preview" (previewMedia model.preview)
        ]
        [ viewSidebar model selected
        , viewStage model.preview
        ]


themeMode : Model -> String
themeMode model =
    case model.appearance of
        PinLight ->
            "light"

        PinDark ->
            "dark"

        FollowSystem ->
            if model.prefersDark then
                "dark"

            else
                "light"


viewSidebar : Model -> Theme -> Html Msg
viewSidebar model selected =
    Html.aside [ class "app-sidebar" ]
        [ viewBrand
        , viewSwitcher model selected
        , viewPreviewControls model.preview
        , viewAppearance model.appearance
        ]


viewBrand : Html Msg
viewBrand =
    Html.header [ class "app-brand" ]
        [ p [ class "app-eyebrow" ] [ Html.text "ResumeZen" ]
        , h1 [ class "app-title" ] [ Html.text "Garden" ]
        , p [ class "app-lede" ]
            [ Html.text "One Skeleton. Flip a Theme. Print stays print." ]
        ]


viewSwitcher : Model -> Theme -> Html Msg
viewSwitcher model selected =
    div [ class "theme-switcher" ]
        [ h2 [ class "theme-switcher__title" ] [ Html.text "Themes" ]
        , p [ class "theme-switcher__hint" ]
            [ Html.text "Labels come from "
            , Html.code [] [ Html.text "/* rz-target */" ]
            , Html.text ". A print Theme is not judged on hover."
            ]
        , viewFilters model.filter
        , ul
            [ class "theme-switcher__list"
            , attribute "role" "list"
            ]
            (visibleThemes model.filter
                |> List.map (viewThemeItem selected.id)
            )
        ]


viewFilters : Filter -> Html Msg
viewFilters current =
    div
        [ class "theme-switcher__filters"
        , attribute "role" "group"
        , attribute "aria-label" "Filter themes by target"
        ]
        [ filterButton FilterAll "All" current
        , filterButton FilterWeb "Web" current
        , filterButton FilterPrint "Print" current
        ]


filterButton : Filter -> String -> Filter -> Html Msg
filterButton filter label current =
    button
        [ type_ "button"
        , class "btn btn--sm"
        , classList
            [ ( "btn--secondary", current == filter )
            , ( "btn--ghost", current /= filter )
            ]
        , attribute "aria-pressed"
            (if current == filter then
                "true"

             else
                "false"
            )
        , onClick (SetFilter filter)
        ]
        [ Html.text label ]


visibleThemes : Filter -> List Theme
visibleThemes filter =
    Themes.all
        |> List.filter
            (\theme ->
                case filter of
                    FilterAll ->
                        True

                    FilterWeb ->
                        theme.target == Web || theme.target == Both

                    FilterPrint ->
                        theme.target == Print || theme.target == Both
            )


viewThemeItem : String -> Theme -> Html Msg
viewThemeItem selectedId theme =
    li [ class "theme-switcher__item" ]
        [ button
            [ type_ "button"
            , id ("theme-option-" ++ theme.id)
            , class "theme-switcher__option"
            , classList [ ( "theme-switcher__option--selected", theme.id == selectedId ) ]
            , attribute "aria-pressed"
                (if theme.id == selectedId then
                    "true"

                 else
                    "false"
                )
            , onClick (SelectTheme theme.id)
            ]
            [ span [ class "theme-switcher__name" ] [ Html.text theme.name ]
            , span
                [ class "badge"
                , classList
                    [ ( "badge--web", theme.target == Web )
                    , ( "badge--print", theme.target == Print )
                    , ( "badge--both", theme.target == Both )
                    ]
                ]
                [ Html.text (targetLabel theme.target) ]
            ]
        ]


targetLabel : Target -> String
targetLabel target =
    case target of
        Web ->
            "web"

        Print ->
            "print"

        Both ->
            "both"


viewPreviewControls : Preview -> Html Msg
viewPreviewControls preview =
    div [ class "preview-controls" ]
        [ h2 [ class "preview-controls__title" ] [ Html.text "View" ]
        , div
            [ class "preview-controls__row"
            , attribute "role" "group"
            , attribute "aria-label" "Screen or print preview"
            ]
            [ previewButton Screen "Screen" preview
            , previewButton PrintPreview "Print preview" preview
            ]
        , button
            [ type_ "button"
            , class "btn btn--md btn--outline preview-controls__print"
            , onClick PrintRequested
            ]
            [ Html.text "Print" ]
        , p [ class "preview-controls__hint" ]
            [ Html.text "Print preview emulates "
            , Html.code [] [ Html.text "@media print" ]
            , Html.text ". Browser print uses the active Theme’s print CSS."
            ]
        ]


previewButton : Preview -> String -> Preview -> Html Msg
previewButton preview label current =
    button
        [ type_ "button"
        , class "btn btn--sm"
        , classList
            [ ( "btn--secondary", current == preview )
            , ( "btn--ghost", current /= preview )
            ]
        , attribute "aria-pressed"
            (if current == preview then
                "true"

             else
                "false"
            )
        , onClick (SetPreview preview)
        ]
        [ Html.text label ]


viewAppearance : Appearance -> Html Msg
viewAppearance appearance =
    div [ class "appearance" ]
        [ h2 [ class "appearance__title" ] [ Html.text "Chrome" ]
        , div
            [ class "appearance__row"
            , attribute "role" "group"
            , attribute "aria-label" "Chrome appearance"
            ]
            [ appearanceButton FollowSystem "System" appearance
            , appearanceButton PinLight "Light" appearance
            , appearanceButton PinDark "Dark" appearance
            ]
        ]


appearanceButton : Appearance -> String -> Appearance -> Html Msg
appearanceButton choice label current =
    button
        [ type_ "button"
        , class "btn btn--xs"
        , classList
            [ ( "btn--secondary", current == choice )
            , ( "btn--ghost", current /= choice )
            ]
        , attribute "aria-pressed"
            (if current == choice then
                "true"

             else
                "false"
            )
        , onClick (SetAppearance choice)
        ]
        [ Html.text label ]


viewStage : Preview -> Html Msg
viewStage preview =
    Keyed.node "main"
        [ class "garden-stage"
        , classList [ ( "garden-stage--print", preview == PrintPreview ) ]
        ]
        [ ( "garden-frame"
          , iframe
                [ id "garden-frame"
                , class "garden-frame"
                , src "sandbox.html"
                , title "Résumé preview"
                , attribute "aria-label" "Sandboxed résumé"
                ]
                []
          )
        ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ preferDarkChanged SystemPrefersDark
        , onThemeQuery ThemeQueryChanged
        ]


port preferDarkChanged : (Bool -> msg) -> Sub msg



-- FLAGS / MAIN


flagsDecoder : Decode.Decoder Flags
flagsDecoder =
    Decode.map2 Flags
        (Decode.field "prefersDark" Decode.bool)
        (Decode.field "themeQuery" Decode.string)


main : Program Decode.Value Model Msg
main =
    Browser.element
        { init =
            \value ->
                init
                    (Decode.decodeValue flagsDecoder value
                        |> Result.withDefault { prefersDark = False, themeQuery = "" }
                    )
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
