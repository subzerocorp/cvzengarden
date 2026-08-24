module Paste exposing (Effect(..), Model, Msg(..), Status(..), init, rendered, update, view)

{-| "Use my résumé": a sidebar control that opens a panel where an Author
pastes a JSON Resume and presses "Show it".

`update` is a calculation: it returns the next model and an `Effect` for
`Main` to turn into a port command. Every message the Author can see is a
plain sentence built here (`problemSentence`, `renderFailedSentence`) — no
crate text ever reaches the panel; `Main` sends it to the console instead.
-}

import Html exposing (Html, button, div, h2, p, textarea)
import Html.Attributes as Attr exposing (attribute, class, id, type_)
import Html.Events exposing (onClick, onInput)
import Paste.Classify as Classify exposing (Classification(..), Problem(..), Shape(..))
import Paste.JsonScan as JsonScan



-- MODEL


type alias Model =
    { open : Bool
    , text : String
    , status : Status
    , attempt : Int
    }


type Status
    = Idle
    | Rendering
    | Shown
    | Failed Failure


type Failure
    = Rejected Problem
    | RenderFailed


type Effect
    = NoEffect
    | Render String
    | Swap String
    | LogDebug String


init : Model
init =
    { open = False, text = "", status = Idle, attempt = 0 }



-- UPDATE


type Msg
    = ToggleOpen
    | TextChanged String
    | ShowIt


update : Msg -> Model -> ( Model, Effect )
update msg model =
    case msg of
        ToggleOpen ->
            ( { model | open = not model.open }, NoEffect )

        TextChanged text ->
            ( { model | text = text }, NoEffect )

        ShowIt ->
            submit { model | attempt = model.attempt + 1 }


submit : Model -> ( Model, Effect )
submit model =
    case Classify.classify model.text of
        Accepted json ->
            ( { model | status = Rendering }, Render json )

        Classify.Rejected problem ->
            ( { model | status = Failed (Rejected problem) }, NoEffect )


{-| The renderer answered. Its raw error is for the console only.
-}
rendered : Result String String -> Model -> ( Model, Effect )
rendered result model =
    case result of
        Ok html ->
            ( { model | status = Shown }, Swap html )

        Err raw ->
            ( { model | status = Failed RenderFailed }, LogDebug raw )



-- VIEW


view : Model -> Html Msg
view model =
    div
        [ class "paste"
        , attribute "data-paste-status" (statusName model.status)
        , attribute "data-paste-attempt" (String.fromInt model.attempt)
        ]
        [ h2 [ class "paste__title" ] [ Html.text "Your résumé" ]
        , button
            [ type_ "button"
            , class "btn btn--md btn--primary paste__toggle"
            , attribute "aria-expanded" (boolAttr model.open)
            , attribute "aria-controls" "paste-panel"
            , onClick ToggleOpen
            ]
            [ Html.text "Use my résumé" ]
        , p [ class "paste__hint" ]
            [ Html.text "Nothing leaves your browser until you publish." ]
        , viewPanel model
        ]


viewPanel : Model -> Html Msg
viewPanel model =
    div
        [ id "paste-panel"
        , class "paste__panel"
        , Attr.hidden (not model.open)
        ]
        [ Html.label [ class "paste__label", Attr.for "paste-input" ]
            [ Html.text "Paste your JSON Resume here" ]
        , textarea
            [ id "paste-input"
            , class "paste__input"
            , Attr.rows 10
            , Attr.spellcheck False
            , Attr.placeholder "{ \"basics\": { \"name\": \"Your Name\" }, … }"
            , Attr.value model.text
            , onInput TextChanged
            ]
            []
        , button
            [ type_ "button"
            , class "btn btn--md btn--primary paste__show"
            , onClick ShowIt
            ]
            [ Html.text "Show it" ]
        , viewStatus model.status
        ]


viewStatus : Status -> Html Msg
viewStatus status =
    case status of
        Idle ->
            Html.text ""

        Rendering ->
            p [ class "paste__note" ] [ Html.text "Drawing your résumé…" ]

        Shown ->
            p [ class "paste__note" ]
                [ Html.text "This is your résumé now. Pick any Theme or print it." ]

        Failed failure ->
            viewFailure failure


viewFailure : Failure -> Html Msg
viewFailure failure =
    p
        [ class "paste__error"
        , attribute "data-paste-error" (failureName failure)
        , attribute "role" "alert"
        ]
        (case failure of
            Rejected problem ->
                [ Html.text (problemSentence problem) ]

            RenderFailed ->
                [ Html.text renderFailedSentence
                , Html.a
                    [ class "paste__report"
                    , Attr.href reportUrl
                    , Attr.target "_blank"
                    , Attr.rel "noopener"
                    ]
                    [ Html.text "Report this" ]
                , Html.text " so we can fix it."
                ]
        )



-- COPY


problemSentence : Problem -> String
problemSentence problem =
    case problem of
        Empty ->
            "There is nothing to show yet. Paste your résumé into the box above, then press Show it."

        InvalidJson { line, column, kind } ->
            "This is not quite valid JSON yet. Look at line "
                ++ String.fromInt line
                ++ ", column "
                ++ String.fromInt column
                ++ ": "
                ++ faultHint kind

        InvalidJsonSomewhere ->
            "This is not quite valid JSON yet, and we could not tell exactly where. Check the numbers and the backslashes in it, and that the whole file was pasted."

        NotAResume { key, shape } ->
            "This is JSON, but it does not look like a JSON Resume: the \""
                ++ key
                ++ "\" part should be "
                ++ shapeWords shape
                ++ "."

        MissingName ->
            "We could not find a name in it. A résumé needs \"basics\": { \"name\": \"Your Name\" } near the top."


faultHint : JsonScan.Kind -> String
faultHint kind =
    case kind of
        JsonScan.TrailingComma ->
            "there is a comma right before a closing bracket. Remove that last comma."

        JsonScan.UnquotedText ->
            "some text is not wrapped in double quotes. Every name and every piece of text needs \"quotes\" around it."

        JsonScan.UnterminatedString ->
            "a piece of text opens with a double quote but never closes it. Add the closing \" on that line."

        JsonScan.Stray ->
            "there is a character we cannot read there. Check the brackets, commas and quotes around it."

        JsonScan.Truncated ->
            "the text ends before every bracket is closed. Make sure the whole file was pasted."

        JsonScan.BadNumber ->
            "there is a number written in a way JSON cannot read. Numbers need no leading zeros, a digit on each side of any dot, and digits after any minus sign."

        JsonScan.BadEscape ->
            "there is a backslash followed by something JSON cannot read. Inside text, a backslash may only be followed by \" \\ / b f n r t, or u and four hex digits."


shapeWords : Shape -> String
shapeWords shape =
    case shape of
        Group ->
            "a group of fields written between { and }"

        ListOfEntries ->
            "a list of entries written between [ and ]"


renderFailedSentence : String
renderFailedSentence =
    "We could not draw this résumé, and we would like to know why. "


reportUrl : String
reportUrl =
    "https://github.com/subzerocorp/cvzengarden/issues/new?title=Could+not+draw+my+r%C3%A9sum%C3%A9"



-- NAMES


statusName : Status -> String
statusName status =
    case status of
        Idle ->
            "idle"

        Rendering ->
            "rendering"

        Shown ->
            "shown"

        Failed _ ->
            "failed"


failureName : Failure -> String
failureName failure =
    case failure of
        Rejected Empty ->
            "empty"

        Rejected (InvalidJson _) ->
            "invalid-json"

        Rejected InvalidJsonSomewhere ->
            "invalid-json"

        Rejected (NotAResume _) ->
            "not-a-resume"

        Rejected MissingName ->
            "missing-name"

        RenderFailed ->
            "render-failed"


boolAttr : Bool -> String
boolAttr flag =
    if flag then
        "true"

    else
        "false"
