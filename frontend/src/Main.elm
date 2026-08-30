port module Main exposing (main)

{-| ResumeZen Garden chrome: live Theme switcher and "Use my résumé" paste
around a sandboxed Skeleton.

The iframe `src` is constant (`sandbox.html`). Switching a Theme changes only
the Theme stylesheet href inside that document. `.rz-resume` inner HTML is
only replaced by crate output (`swapResume`). Chrome class names never use
the `rz-` prefix.

Theme id resolution is pure (`ThemeId`). History and the iframe stylesheet
are isolated actions (ports).
-}

import About
import Browser
import Browser.Events as Events
import CopyLink
import Generated.Themes as Themes exposing (Target(..), Theme)
import Html exposing (Html, a, button, div, h1, h2, iframe, li, p, span, ul)
import Html.Attributes as Attr exposing (attribute, class, classList, href, id, rel, src, target, title, type_)
import Html.Events exposing (onClick)
import Html.Keyed as Keyed
import Json.Decode as Decode
import Paste
import Process
import Task
import ThemeId



-- PORTS


port setThemeHref : String -> Cmd msg


port setPreviewMedia : String -> Cmd msg


port printGarden : () -> Cmd msg


port pushThemeQuery : String -> Cmd msg


port pushViewQuery : String -> Cmd msg


port onGardenQuery : ({ theme : String, view : String } -> msg) -> Sub msg


{-| Render a JSON Resume text with the Wasm renderer; the answer arrives on
`onRendered` as `{ ok, html, error }` (decoded to a `Result`).
-}
port renderResume : String -> Cmd msg


port onRendered : (Decode.Value -> msg) -> Sub msg


{-| Replace `article.rz-resume` in the sandbox with crate output
(`window.resumezen.swap`). The Theme link and the iframe src are untouched.
-}
port swapResume : String -> Cmd msg


{-| The renderer's raw error, for `console.debug` only — never for the panel.
-}
port logDebug : String -> Cmd msg


{-| Persist the raw accepted JSON Resume under `resumezen.resume`.
-}
port storeResume : String -> Cmd msg


{-| Drop `resumezen.resume`.
-}
port forgetResume : () -> Cmd msg


{-| Put the sandbox's original Jordan Hale article back. No network.
-}
port restoreSample : () -> Cmd msg


port onFileBytes : ({ name : String, text : String } -> msg) -> Sub msg


port onStoredResume : (String -> msg) -> Sub msg


{-| Write a string to the clipboard. The answer arrives on `onCopied`.
-}
port copyText : String -> Cmd msg


port onCopied : (Bool -> msg) -> Sub msg


{-| Write `location.href` to the clipboard. The answer arrives on `onLinkCopied`.
-}
port copyLink : () -> Cmd msg


port onLinkCopied : (Bool -> msg) -> Sub msg


{-| Move keyboard focus to an element id after Elm has patched the DOM.
-}
port focusId : String -> Cmd msg


type alias PageEstimate =
    { pages : Int
    , paper : String
    , source : String
    , label : String
    }


{-| Constrained-column page estimate from ports.js. Shown only in Print preview.
-}
port pageEstimate : (PageEstimate -> msg) -> Sub msg



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
    , viewQuery : String
    }


type alias GardenQuery =
    { theme : String
    , view : String
    }


type alias Model =
    { selectedId : String
    , preview : Preview
    , filter : Filter
    , appearance : Appearance
    , prefersDark : Bool
    , paste : Paste.Model
    , about : About.Model
    , copyLink : CopyLink.Model
    , themeNotice : Maybe String
    , sidebarOpen : Bool
    , pageEstimate : Maybe PageEstimate
    }



-- INIT


init : Flags -> ( Model, Cmd Msg )
init flags =
    applyLoadedQuery
        { theme = flags.themeQuery, view = flags.viewQuery }
        { selectedId = ThemeId.fallback
        , preview = Screen
        , filter = FilterAll
        , appearance = FollowSystem
        , prefersDark = flags.prefersDark
        , paste = Paste.init
        , about = About.init
        , copyLink = CopyLink.init
        , themeNotice = Nothing
        , sidebarOpen = False
        , pageEstimate = Nothing
        }



-- UPDATE


type Msg
    = SelectTheme String
    | GardenQueryChanged GardenQuery
    | SetPreview Preview
    | SetFilter Filter
    | SetAppearance Appearance
    | SystemPrefersDark Bool
    | PrintRequested
    | PasteMsg Paste.Msg
    | AboutMsg About.Msg
    | CopyLinkMsg CopyLink.Msg
    | DismissNotice
    | ToggleSidebar
    | CloseSidebar
    | PageEstimateReceived PageEstimate
    | Rendered (Result String String)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SelectTheme id ->
            applyTheme id True model

        GardenQueryChanged query ->
            applyLoadedQuery query model

        SetPreview preview ->
            ( { model | preview = preview }
            , Cmd.batch
                [ setPreviewMedia (previewMedia preview)
                , pushViewQuery (previewMedia preview)
                ]
            )

        SetFilter filter ->
            ( { model | filter = filter }, Cmd.none )

        SetAppearance appearance ->
            ( { model | appearance = appearance }, Cmd.none )

        SystemPrefersDark prefersDark ->
            ( { model | prefersDark = prefersDark }, Cmd.none )

        PrintRequested ->
            ( model, printGarden () )

        PasteMsg pasteMsg ->
            Paste.update pasteMsg model.paste
                |> applyPaste model

        AboutMsg aboutMsg ->
            About.update aboutMsg model.about
                |> applyAbout model

        CopyLinkMsg copyMsg ->
            CopyLink.update copyMsg model.copyLink
                |> applyCopyLink model

        DismissNotice ->
            ( { model | themeNotice = Nothing }, Cmd.none )

        ToggleSidebar ->
            if model.sidebarOpen then
                closeSidebar model

            else
                ( { model | sidebarOpen = True }, Cmd.none )

        CloseSidebar ->
            closeSidebar model

        PageEstimateReceived estimate ->
            ( { model | pageEstimate = Just estimate }, Cmd.none )

        Rendered result ->
            Paste.rendered result model.paste
                |> applyPaste model


applyPaste : Model -> ( Paste.Model, List Paste.Effect ) -> ( Model, Cmd Msg )
applyPaste model ( paste, effects ) =
    ( { model | paste = paste }
    , Cmd.batch (List.map pasteCommand effects)
    )


{-| The only place a Paste effect becomes an action.
-}
pasteCommand : Paste.Effect -> Cmd Msg
pasteCommand effect =
    case effect of
        Paste.Render json ->
            renderResume json

        Paste.Swap html ->
            swapResume html

        Paste.LogDebug raw ->
            logDebug raw

        Paste.Store json ->
            storeResume json

        Paste.Forget ->
            forgetResume ()

        Paste.RestoreSample ->
            restoreSample ()

        Paste.Copy text ->
            copyText text

        Paste.WaitClearCopy gen ->
            Process.sleep 2000
                |> Task.perform (\_ -> PasteMsg (Paste.ClearCopy gen))


applyAbout : Model -> ( About.Model, List About.Effect ) -> ( Model, Cmd Msg )
applyAbout model ( about, effects ) =
    ( { model | about = about }
    , Cmd.batch (List.map aboutCommand effects)
    )


{-| The only place an About effect becomes an action.
-}
aboutCommand : About.Effect -> Cmd Msg
aboutCommand effect =
    case effect of
        About.Focus target ->
            focusId target


applyCopyLink : Model -> ( CopyLink.Model, List CopyLink.Effect ) -> ( Model, Cmd Msg )
applyCopyLink model ( link, effects ) =
    ( { model | copyLink = link }
    , Cmd.batch (List.map copyLinkCommand effects)
    )


copyLinkCommand : CopyLink.Effect -> Cmd Msg
copyLinkCommand effect =
    case effect of
        CopyLink.CopyHref ->
            copyLink ()

        CopyLink.WaitClear gen ->
            Process.sleep 2000
                |> Task.perform (\_ -> CopyLinkMsg (CopyLink.Clear gen))


closeSidebar : Model -> ( Model, Cmd Msg )
closeSidebar model =
    ( { model | sidebarOpen = False }
    , if model.sidebarOpen then
        focusId themeToggleId

      else
        Cmd.none
    )


themeToggleId : String
themeToggleId =
    "theme-toggle"


themeSheetId : String
themeSheetId =
    "theme-sheet"


applyLoadedQuery : GardenQuery -> Model -> ( Model, Cmd Msg )
applyLoadedQuery query model =
    let
        resolved =
            ThemeId.fromQuery query.theme

        theme =
            ThemeId.themeFromResult resolved

        preview =
            previewFromQuery query.view

        notice =
            case resolved of
                ThemeId.Unknown raw ->
                    Just raw

                _ ->
                    Nothing
    in
    ( { model
        | selectedId = theme.id
        , preview = preview
        , themeNotice = notice
      }
    , Cmd.batch
        [ setThemeHref theme.href
        , setPreviewMedia (previewMedia preview)
        ]
    )


applyTheme : String -> Bool -> Model -> ( Model, Cmd Msg )
applyTheme id pushQuery model =
    case Themes.themeById id of
        Nothing ->
            applyTheme ThemeId.fallback pushQuery model

        Just theme ->
            let
                next =
                    { model
                        | selectedId = theme.id
                        , themeNotice = Nothing
                        , sidebarOpen = False
                    }

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


previewFromQuery : String -> Preview
previewFromQuery raw =
    case String.toLower (String.trim raw) of
        "print" ->
            PrintPreview

        _ ->
            Screen



-- VIEW


view : Model -> Html Msg
view model =
    let
        selected =
            ThemeId.themeFromQuery model.selectedId
    in
    div
        [ class "app-shell"
        , classList [ ( "app-shell--sidebar-open", model.sidebarOpen ) ]
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
    Html.aside
        [ class "app-sidebar"
        , classList [ ( "app-sidebar--open", model.sidebarOpen ) ]
        ]
        [ viewSidebarToggle model.sidebarOpen
        , div
            [ class "app-sidebar__sheet"
            , id themeSheetId
            ]
            [ viewBrand
            , Html.map PasteMsg (Paste.view model.paste)
            , viewSwitcher model selected
            , viewThemeNotice model.themeNotice
            , viewPreviewControls model
            , viewAppearance model.appearance
            , Html.map AboutMsg (About.view model.about)
            ]
        ]


viewSidebarToggle : Bool -> Html Msg
viewSidebarToggle open =
    button
        [ type_ "button"
        , class "btn btn--md btn--primary sidebar-toggle"
        , id themeToggleId
        , attribute "aria-expanded"
            (if open then
                "true"

             else
                "false"
            )
        , attribute "aria-controls" themeSheetId
        , onClick ToggleSidebar
        ]
        [ Html.text "Theme" ]


viewBrand : Html Msg
viewBrand =
    Html.header [ class "app-brand" ]
        [ p [ class "app-eyebrow" ] [ Html.text "ResumeZen" ]
        , h1 [ class "app-title" ] [ Html.text "Garden" ]
        , p [ class "app-lede" ]
            [ Html.text "Pick a look for your résumé. Your content stays the same. Print it or share the link." ]
        ]


viewSwitcher : Model -> Theme -> Html Msg
viewSwitcher model selected =
    div [ class "theme-switcher" ]
        [ h2 [ class "theme-switcher__title" ] [ Html.text "Themes" ]
        , viewFilters model.filter
        , ul
            [ class "theme-switcher__list"
            , attribute "role" "list"
            ]
            (visibleThemes model.filter
                |> List.map (viewThemeItem selected.id)
            )
        , p [ class "theme-switcher__note" ]
            [ Html.text "Every theme prints in dark ink on white paper" ]
        ]


viewFilters : Filter -> Html Msg
viewFilters current =
    div
        [ class "theme-switcher__filters"
        , attribute "role" "group"
        , attribute "aria-label" "Show looks for"
        ]
        [ filterButton FilterAll "All" current
        , filterButton FilterWeb "For screen" current
        , filterButton FilterPrint "For paper" current
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


{-| The card is the `li`: it carries the border, background and selected
state, while the option button inside it stays the single control that
selects the theme. The byline is the button's sibling, not its child —
`button` forbids interactive descendants, and a link nested inside one is
never exposed as a link by assistive tech.
-}
viewThemeItem : String -> Theme -> Html Msg
viewThemeItem selectedId theme =
    li
        [ class "theme-switcher__item"
        , classList [ ( "theme-switcher__item--selected", theme.id == selectedId ) ]
        ]
        [ button
            [ type_ "button"
            , id ("theme-option-" ++ theme.id)
            , class "theme-switcher__option"
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
        , viewByline theme
        ]


{-| The designer's credit. No `Author:` header means no byline at all, rather
than a fabricated one. When the theme carries an http(s) `URL:` the name
becomes a link. Sitting outside the option button, the link needs no click
guard: crediting the designer cannot reach the theme-selection handler.
-}
viewByline : Theme -> Html Msg
viewByline theme =
    if String.isEmpty theme.author then
        Html.text ""

    else
        span [ class "theme-switcher__author" ]
            [ Html.text "by "
            , case theme.url of
                Just link ->
                    a
                        [ href link
                        , rel "noopener"
                        , target "_blank"
                        , class "theme-switcher__author-link"
                        ]
                        [ Html.text theme.author ]

                Nothing ->
                    Html.text theme.author
            ]


targetLabel : Target -> String
targetLabel target =
    case target of
        Web ->
            "Screen"

        Print ->
            "Paper"

        Both ->
            "Screen + paper"


viewThemeNotice : Maybe String -> Html Msg
viewThemeNotice notice =
    case notice of
        Nothing ->
            Html.text ""

        Just raw ->
            div
                [ class "theme-notice"
                , attribute "data-theme-notice" "unknown"
                , attribute "role" "status"
                ]
                [ p [ class "theme-notice__text" ]
                    [ Html.text "No theme called \""
                    , Html.text raw
                    , Html.text "\" — showing Nightgarden."
                    ]
                , button
                    [ type_ "button"
                    , class "theme-notice__close"
                    , attribute "aria-label" "Dismiss theme notice"
                    , onClick DismissNotice
                    ]
                    [ Html.text "Close" ]
                ]


viewPreviewControls : Model -> Html Msg
viewPreviewControls model =
    div [ class "preview-controls" ]
        [ h2 [ class "preview-controls__title" ] [ Html.text "View" ]
        , div
            [ class "preview-controls__row"
            , attribute "role" "group"
            , attribute "aria-label" "Screen or print preview"
            ]
            [ previewButton Screen "Screen" model.preview
            , previewButton PrintPreview "Print preview" model.preview
            ]
        , Html.map CopyLinkMsg (CopyLink.view model.copyLink)
        , button
            [ type_ "button"
            , class "btn btn--md btn--outline preview-controls__print"
            , attribute "aria-label" "Print / Save as PDF"
            , onClick PrintRequested
            ]
            [ Html.text "Print / Save as PDF" ]
        , p [ class "preview-controls__hint" ]
            [ Html.text "What you see here is what the printer prints." ]
        , p [ class "preview-controls__hint", attribute "data-pdf-hint" "" ]
            [ Html.text "Choose \"Save as PDF\" in the print dialog to get a PDF." ]
        , viewPageEstimate model
        ]


viewPageEstimate : Model -> Html Msg
viewPageEstimate model =
    case ( model.preview, model.pageEstimate ) of
        ( PrintPreview, Just estimate ) ->
            p
                [ class "preview-controls__pages"
                , attribute "data-page-estimate" (String.fromInt estimate.pages)
                , attribute "data-page-size" estimate.paper
                , attribute "data-page-size-source" estimate.source
                ]
                [ Html.text estimate.label ]

        _ ->
            Html.text ""


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
        [ h2 [ class "appearance__title" ] [ Html.text "Appearance" ]
        , div
            [ class "appearance__row"
            , attribute "role" "group"
            , attribute "aria-label" "Light or dark"
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
subscriptions model =
    Sub.batch
        [ preferDarkChanged SystemPrefersDark
        , onGardenQuery GardenQueryChanged
        , onRendered (decodeRendered >> Rendered)
        , onFileBytes (Paste.FileOpened >> PasteMsg)
        , onStoredResume (Paste.Restored >> PasteMsg)
        , onCopied (Paste.CopyFinished >> PasteMsg)
        , onLinkCopied (CopyLink.Finished >> CopyLinkMsg)
        , Sub.map AboutMsg (About.subscriptions model.about)
        , pageEstimate PageEstimateReceived
        , sidebarKeys model
        ]


sidebarKeys : Model -> Sub Msg
sidebarKeys model =
    if model.sidebarOpen then
        Events.onKeyDown escapeDecoder

    else
        Sub.none


escapeDecoder : Decode.Decoder Msg
escapeDecoder =
    Decode.field "key" Decode.string
        |> Decode.andThen
            (\key ->
                if key == "Escape" then
                    Decode.succeed CloseSidebar

                else
                    Decode.fail "not escape"
            )


{-| `{ ok : Bool, html : String, error : String }` from the port, as a Result.
An undecodable value is itself a render failure.
-}
decodeRendered : Decode.Value -> Result String String
decodeRendered value =
    let
        decoder =
            Decode.map3
                (\ok html error ->
                    if ok then
                        Ok html

                    else
                        Err error
                )
                (Decode.field "ok" Decode.bool)
                (Decode.field "html" Decode.string)
                (Decode.field "error" Decode.string)
    in
    case Decode.decodeValue decoder value of
        Ok result ->
            result

        Err problem ->
            Err (Decode.errorToString problem)


port preferDarkChanged : (Bool -> msg) -> Sub msg



-- FLAGS / MAIN


flagsDecoder : Decode.Decoder Flags
flagsDecoder =
    Decode.map3 Flags
        (Decode.field "prefersDark" Decode.bool)
        (Decode.field "themeQuery" Decode.string)
        (Decode.field "viewQuery" Decode.string)


main : Program Decode.Value Model Msg
main =
    Browser.element
        { init =
            \value ->
                init
                    (Decode.decodeValue flagsDecoder value
                        |> Result.withDefault { prefersDark = False, themeQuery = "", viewQuery = "" }
                    )
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
