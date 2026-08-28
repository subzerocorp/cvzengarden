module CopyLink exposing (Effect(..), Model, Msg(..), init, update, view)

{-| "Copy link" in the View section. Writes `location.href` (the port
reads it). Success is a 2-second `Copied` state; a rejected clipboard
write is `Copy failed — select the address bar and copy it` and never
`Copied`.
-}

import Html exposing (Html, button)
import Html.Attributes exposing (attribute, class, type_)
import Html.Events exposing (onClick)



-- MODEL


type alias Model =
    { state : CopyState
    , gen : Int
    }


type CopyState
    = Idle
    | Copied
    | Failed


type Effect
    = CopyHref
    | WaitClear Int


init : Model
init =
    { state = Idle
    , gen = 0
    }



-- UPDATE


type Msg
    = Clicked
    | Finished Bool
    | Clear Int


update : Msg -> Model -> ( Model, List Effect )
update msg model =
    case msg of
        Clicked ->
            begin model

        Finished ok ->
            finish ok model

        Clear gen ->
            clear gen model


begin : Model -> ( Model, List Effect )
begin model =
    let
        gen =
            model.gen + 1
    in
    ( { model | state = Idle, gen = gen }, [ CopyHref ] )


finish : Bool -> Model -> ( Model, List Effect )
finish ok model =
    if ok then
        ( { model | state = Copied }, [ WaitClear model.gen ] )

    else
        ( { model | state = Failed }, [] )


clear : Int -> Model -> ( Model, List Effect )
clear gen model =
    if gen == model.gen && model.state == Copied then
        ( { model | state = Idle }, [] )

    else
        ( model, [] )



-- VIEW


view : Model -> Html Msg
view model =
    button
        (copyButtonAttrs model.state)
        [ Html.text (copyButtonLabel model.state) ]


copyButtonAttrs : CopyState -> List (Html.Attribute Msg)
copyButtonAttrs state =
    [ type_ "button"
    , class "btn btn--md btn--outline copy-link"
    , onClick Clicked
    ]
        ++ (case state of
                Idle ->
                    []

                Copied ->
                    [ attribute "data-copy-state" "copied" ]

                Failed ->
                    [ attribute "data-copy-state" "failed" ]
           )


copyButtonLabel : CopyState -> String
copyButtonLabel state =
    case state of
        Idle ->
            "Copy link"

        Copied ->
            "Copied"

        Failed ->
            failedSentence


failedSentence : String
failedSentence =
    "Copy failed — select the address bar and copy it"
