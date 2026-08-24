module Paste.Classify exposing (Classification(..), Problem(..), Shape(..), classify, classifyFile, knownKeys)

{-| Pure classification of pasted text and of opened/dropped files.

The rule is deliberately the AC and no more (Avril, CTO rule 7): empty,
not JSON (with the position from `Paste.JsonScan`), a known top-level key
of the wrong shape, no `basics.name`, and for files a content-first
`not-json-file`. Everything else is `Accepted` and the crate remains the
oracle.
-}

import Json.Decode as Decode exposing (Decoder, Value)
import Paste.JsonScan as JsonScan


type Classification
    = Accepted String
    | Rejected Problem


type Problem
    = Empty
    | InvalidJson { line : Int, column : Int, kind : JsonScan.Kind }
    | InvalidJsonSomewhere
    | NotAResume { key : String, shape : Shape }
    | MissingName
    | NotJsonFile String


{-| What a known top-level key must hold.
-}
type Shape
    = Group
    | ListOfEntries


{-| JSON Resume top-level keys and their shapes, in schema order.
-}
knownKeys : List ( String, Shape )
knownKeys =
    ( "basics", Group )
        :: List.map (\key -> ( key, ListOfEntries ))
            [ "work"
            , "volunteer"
            , "education"
            , "awards"
            , "certificates"
            , "publications"
            , "skills"
            , "languages"
            , "interests"
            , "references"
            , "projects"
            ]


classify : String -> Classification
classify text =
    if String.isEmpty (String.trim text) then
        Rejected Empty

    else
        case Decode.decodeString Decode.value text of
            Err _ ->
                Rejected (invalidJson text)

            Ok document ->
                shapeProblem document
                    |> Maybe.map Rejected
                    |> Maybe.withDefault (Accepted text)


{-| The scanner locates the fault. When it cannot (the text is too long or
too deep, or the decoder rejects something the scanner accepts) the
problem is real but has no position — never invent one.
-}
invalidJson : String -> Problem
invalidJson text =
    case JsonScan.scan text of
        JsonScan.Found found ->
            let
                position =
                    JsonScan.positionOf text found.offset
            in
            InvalidJson { line = position.line, column = position.column, kind = found.kind }

        JsonScan.Clean ->
            InvalidJsonSomewhere

        JsonScan.Lost ->
            InvalidJsonSomewhere


shapeProblem : Value -> Maybe Problem
shapeProblem document =
    case firstWrongShape document of
        Just problem ->
            Just problem

        Nothing ->
            if hasName document then
                Nothing

            else
                Just MissingName


firstWrongShape : Value -> Maybe Problem
firstWrongShape document =
    knownKeys
        |> List.filter (\( key, shape ) -> hasWrongShape key shape document)
        |> List.head
        |> Maybe.map (\( key, shape ) -> NotAResume { key = key, shape = shape })


{-| Absent and `null` are fine (the renderer tolerates both); a present
value of the wrong shape is the problem.
-}
hasWrongShape : String -> Shape -> Value -> Bool
hasWrongShape key shape document =
    let
        present =
            Decode.decodeValue (Decode.field key nonNull) document == Ok True

        fits =
            Decode.decodeValue (Decode.field key (shapeDecoder shape)) document
                |> Result.map (always True)
                |> Result.withDefault False
    in
    present && not fits


nonNull : Decoder Bool
nonNull =
    Decode.oneOf
        [ Decode.null False
        , Decode.succeed True
        ]


shapeDecoder : Shape -> Decoder ()
shapeDecoder shape =
    case shape of
        Group ->
            Decode.map (always ()) (Decode.keyValuePairs Decode.value)

        ListOfEntries ->
            Decode.map (always ()) (Decode.list Decode.value)


hasName : Value -> Bool
hasName document =
    Decode.decodeValue (Decode.at [ "basics", "name" ] Decode.string) document
        |> Result.map (String.trim >> String.isEmpty >> not)
        |> Result.withDefault False



{-| Content first, then extension: JSON bytes win whatever the filename;
a `.json` file that fails to parse is `invalid-json`; any other
unparseable file is `not-json-file` naming the file.
-}
classifyFile : String -> String -> Classification
classifyFile filename text =
    case classify text of
        Rejected problem ->
            if unreadableAsJson problem && not (isJsonName filename) then
                Rejected (NotJsonFile filename)

            else
                Rejected problem

        accepted ->
            accepted


unreadableAsJson : Problem -> Bool
unreadableAsJson problem =
    case problem of
        Empty ->
            True

        InvalidJson _ ->
            True

        InvalidJsonSomewhere ->
            True

        NotAResume _ ->
            False

        MissingName ->
            False

        NotJsonFile _ ->
            False


isJsonName : String -> Bool
isJsonName filename =
    filename
        |> String.toLower
        |> String.endsWith ".json"
