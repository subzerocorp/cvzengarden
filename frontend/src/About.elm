module About exposing (Effect(..), Model, Msg(..), init, subscriptions, update, view)

{-| Sidebar About link and in-chrome dialog.

`update` is a calculation: it returns the next model and a list of
`Effect`s for `Main` to turn into port commands. The dialog is absent
from the tree when closed so `document.body.textContent` cannot pick up
its copy. ZG-14 fills the "For designers" slot; this module leaves it
labeled and empty.
-}

import Browser.Events as Events
import Html exposing (Html)
import Html.Attributes as Attr exposing (attribute, class, href, id, type_)
import Html.Events exposing (onClick, preventDefaultOn)
import Json.Decode as Decode



-- MODEL


type Model
    = Closed
    | Open


type Effect
    = Focus String


init : Model
init =
    Closed


openControlId : String
openControlId =
    "about-open"


panelId : String
panelId =
    "about-panel"


titleId : String
titleId =
    "about-title"


repoHref : String
repoHref =
    "https://github.com/subzerocorp/cvzengarden"



-- UPDATE


type Msg
    = Opened
    | Dismissed


update : Msg -> Model -> ( Model, List Effect )
update msg _ =
    case msg of
        Opened ->
            ( Open, [ Focus panelId ] )

        Dismissed ->
            ( Closed, [ Focus openControlId ] )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    case model of
        Closed ->
            Sub.none

        Open ->
            Events.onKeyDown escapeDecoder


escapeDecoder : Decode.Decoder Msg
escapeDecoder =
    Decode.field "key" Decode.string
        |> Decode.andThen
            (\key ->
                if key == "Escape" then
                    Decode.succeed Dismissed

                else
                    Decode.fail "not escape"
            )



-- VIEW


view : Model -> Html Msg
view model =
    Html.footer [ class "app-footer" ]
        [ viewOpenLink
        , viewPanel model
        ]


viewOpenLink : Html Msg
viewOpenLink =
    Html.a
        [ class "about-link"
        , id openControlId
        , href "#about"
        , preventDefaultOn "click" (Decode.succeed ( Opened, True ))
        ]
        [ Html.text "About" ]


viewPanel : Model -> Html Msg
viewPanel model =
    case model of
        Closed ->
            Html.text ""

        Open ->
            Html.div
                [ class "about-panel"
                , attribute "role" "dialog"
                , attribute "aria-modal" "true"
                , attribute "aria-labelledby" titleId
                , id panelId
                , Attr.tabindex -1
                ]
                [ Html.div [ class "about-panel__card" ]
                    [ Html.h2 [ class "about-panel__title", id titleId ]
                        [ Html.text "About ResumeZen" ]
                    , Html.p [ class "about-panel__lede" ]
                        [ Html.text whatItIs ]
                    , Html.p [ class "about-panel__price" ]
                        [ Html.text "Free during the preview. Pricing is not announced." ]
                    , Html.p [ class "about-panel__repo" ]
                        [ Html.a
                            [ class "about-panel__repo-link"
                            , href repoHref
                            , Attr.target "_blank"
                            , Attr.rel "noopener"
                            ]
                            [ Html.text "GitHub repository" ]
                        ]
                    , Html.section
                        [ class "about-panel__designers"
                        , attribute "aria-labelledby" "about-designers-title"
                        ]
                        [ Html.h3 [ class "about-panel__slot-title", id "about-designers-title" ]
                            [ Html.text "For designers" ]
                        ]
                    , Html.button
                        [ type_ "button"
                        , class "btn btn--md btn--primary about-panel__close"
                        , id "about-close"
                        , onClick Dismissed
                        ]
                        [ Html.text "Close" ]
                    ]
                ]



-- COPY


whatItIs : String
whatItIs =
    "ResumeZen is a garden of looks for one résumé. You pick a look and your words stay the same. Print the page, or come back later to share a link."
