module Paste exposing (Effect(..), Model, Msg(..), Status(..), init, rendered, update, view)

{-| "Use my résumé": a sidebar control that opens a panel where an Author
pastes or opens a JSON Resume, sees it in every Theme, and has it restored
on reload.

`update` is a calculation: it returns the next model and a list of
`Effect`s for `Main` to turn into port commands. `text` is the editing
buffer; `accepted` is the last résumé that classified and rendered (the
datum stored under `resumezen.resume`). Restore sets both; Forget clears
both. Every message the Author can see is a plain sentence built here —
no crate text ever reaches the panel; `Main` sends it to the console
instead.

Public panel state: `data-paste-status`, `data-paste-attempt`,
`data-paste-error`, `[data-drop-zone]`.
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
    , accepted : Maybe String
    , status : Status
    , attempt : Int
    }


type Status
    = Idle
    | Rendering Intent String
    | Shown
    | Failed Failure


{-| Who asked for this render. Author failures are sentences; Restore
failures drop the stored key and stay on Jordan Hale.
-}
type Intent
    = Author
    | Restore


type Failure
    = Rejected Problem
    | RenderFailed


type Effect
    = Render String
    | Swap String
    | LogDebug String
    | Store String
    | Forget
    | RestoreSample


type alias File =
    { name : String
    , text : String
    }


init : Model
init =
    { open = False, text = "", accepted = Nothing, status = Idle, attempt = 0 }



-- UPDATE


type Msg
    = ToggleOpen
    | TextChanged String
    | ShowIt
    | FileOpened File
    | Restored String
    | ForgetClicked


update : Msg -> Model -> ( Model, List Effect )
update msg model =
    case msg of
        ToggleOpen ->
            ( { model | open = not model.open }, [] )

        TextChanged text ->
            ( { model | text = text }, [] )

        ShowIt ->
            submit model

        FileOpened file ->
            openFile file { model | open = True }

        Restored json ->
            restore json model

        ForgetClicked ->
            forget model


submit : Model -> ( Model, List Effect )
submit model =
    case Classify.classify model.text of
        Accepted json ->
            beginRender Author json model

        Classify.Rejected problem ->
            reject problem model


openFile : File -> Model -> ( Model, List Effect )
openFile file model =
    case Classify.classifyFile file.name file.text of
        Accepted json ->
            beginRender Author json model

        Classify.Rejected problem ->
            reject problem model


restore : String -> Model -> ( Model, List Effect )
restore json model =
    case Classify.classify json of
        Accepted accepted ->
            beginRender Restore accepted { model | text = accepted }

        Classify.Rejected _ ->
            discardStored model


forget : Model -> ( Model, List Effect )
forget model =
    ( { model
        | text = ""
        , accepted = Nothing
        , status = Idle
        , attempt = model.attempt + 1
      }
    , [ Forget, RestoreSample ]
    )


beginRender : Intent -> String -> Model -> ( Model, List Effect )
beginRender intent json model =
    ( { model
        | status = Rendering intent json
        , attempt = model.attempt + 1
      }
    , [ Render json ]
    )


reject : Problem -> Model -> ( Model, List Effect )
reject problem model =
    ( { model
        | status = Failed (Rejected problem)
        , attempt = model.attempt + 1
      }
    , []
    )


discardStored : Model -> ( Model, List Effect )
discardStored model =
    ( { model | text = "", accepted = Nothing, status = Idle }
    , [ Forget ]
    )


{-| The renderer answered. Its raw error is for the console only, and
only when the Author asked — a stored value that will not draw is
forgotten with no banner.
-}
rendered : Result String String -> Model -> ( Model, List Effect )
rendered result model =
    case model.status of
        Rendering intent json ->
            case result of
                Ok html ->
                    keep intent json html model

                Err raw ->
                    failRender intent raw model

        _ ->
            ( model, [] )


keep : Intent -> String -> String -> Model -> ( Model, List Effect )
keep intent json html model =
    let
        shown =
            { model | status = Shown, accepted = Just json }
    in
    case intent of
        Author ->
            ( shown, [ Swap html, Store json ] )

        Restore ->
            ( { shown | text = json }, [ Swap html ] )


failRender : Intent -> String -> Model -> ( Model, List Effect )
failRender intent raw model =
    case intent of
        Author ->
            ( { model | status = Failed RenderFailed }, [ LogDebug raw ] )

        Restore ->
            discardStored model



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
        , viewForget model
        ]


viewPanel : Model -> Html Msg
viewPanel model =
    div
        [ id "paste-panel"
        , class "paste__panel"
        , Attr.hidden (not model.open)
        ]
        [ viewPasteBox model
        , viewOpenFile
        , viewDropZone
        , button
            [ type_ "button"
            , class "btn btn--md btn--primary paste__show"
            , onClick ShowIt
            ]
            [ Html.text "Show it" ]
        , viewStatus model.status
        ]


viewPasteBox : Model -> Html Msg
viewPasteBox model =
    div [ class "paste__box" ]
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
        ]


viewOpenFile : Html Msg
viewOpenFile =
    Html.label
        [ class "btn btn--md btn--outline paste__open"
        , Attr.for "paste-file"
        ]
        [ Html.text "Open a file"
        , Html.input
            [ type_ "file"
            , id "paste-file"
            , class "paste__file"
            , Attr.accept ".json,application/json"
            , attribute "aria-label" "Open a file"
            ]
            []
        ]


viewDropZone : Html Msg
viewDropZone =
    div
        [ class "paste__drop"
        , attribute "data-drop-zone" ""
        ]
        [ Html.text "Or drop a JSON file here" ]


viewForget : Model -> Html Msg
viewForget model =
    case model.accepted of
        Nothing ->
            Html.text ""

        Just _ ->
            button
                [ type_ "button"
                , class "btn btn--md btn--outline paste__forget"
                , onClick ForgetClicked
                ]
                [ Html.text "Forget my résumé" ]


viewStatus : Status -> Html Msg
viewStatus status =
    case status of
        Idle ->
            Html.text ""

        Rendering Restore _ ->
            Html.text ""

        Rendering Author _ ->
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

        NotJsonFile filename ->
            filename
                ++ " is not a JSON Resume. Open a JSON file, or paste the JSON Resume text into the box."


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

        Rendering _ _ ->
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

        Rejected (NotJsonFile _) ->
            "not-json-file"

        RenderFailed ->
            "render-failed"


boolAttr : Bool -> String
boolAttr flag =
    if flag then
        "true"

    else
        "false"
