module Paste.JsonScan exposing (Fault, Kind(..), Outcome(..), Position, positionOf, scan)

{-| A small pure JSON scanner whose only job is to say *where* a text stops
being JSON and *what kind* of slip it is. `Json.Decode` reports no position,
and Elena's complaint is exactly the position-free error, so this scanner
walks the text once and stops at the first fault.

It is strict about the slips a person makes by hand: a trailing comma,
unquoted text, an unterminated string, a stray character, a number JSON
cannot read (`01`, `-`, `1.`), and a backslash it cannot read (`\x`). The
crate remains the oracle for validity.

Two guards keep a hostile paste from blowing the JS stack: only the first
`windowSize` characters are scanned, and nesting deeper than `maxDepth`
gives up. Both report `Lost` rather than a made-up position.

-}


type Kind
    = TrailingComma
    | UnquotedText
    | UnterminatedString
    | Stray
    | Truncated
    | BadNumber
    | BadEscape


type alias Fault =
    { offset : Int
    , kind : Kind
    }


type alias Position =
    { line : Int
    , column : Int
    }


{-| `Clean`: the text is one well-formed JSON value. `Found`: the first
slip. `Lost`: the text is invalid but the scanner cannot say where (too
long, too deep).
-}
type Outcome
    = Clean
    | Found Fault
    | Lost


{-| Characters scanned before giving up on a position (64 KB).
-}
windowSize : Int
windowSize =
    65536


maxDepth : Int
maxDepth =
    64


scan : String -> Outcome
scan text =
    let
        clipped =
            String.length text > windowSize
    in
    { rest = String.toList (String.left windowSize text), offset = 0 }
        |> skipSpace
        |> value 0
        |> Result.andThen (skipSpace >> expectEnd)
        |> outcome clipped


{-| In a clipped scan, running out of text says nothing about the file.
-}
outcome : Bool -> Step -> Outcome
outcome clipped step =
    case step of
        Ok _ ->
            if clipped then
                Lost

            else
                Clean

        Err TooDeep ->
            Lost

        Err (Slip found) ->
            if clipped && found.kind == Truncated then
                Lost

            else
                Found found


{-| 1-based line and column of a character offset in `text`.
-}
positionOf : String -> Int -> Position
positionOf text offset =
    let
        before =
            String.left offset text

        lines =
            String.split "\n" before

        column =
            lines
                |> List.reverse
                |> List.head
                |> Maybe.map String.length
                |> Maybe.withDefault 0
    in
    { line = List.length lines, column = column + 1 }



-- SCANNER PRIMITIVES


type alias Scanner =
    { rest : List Char
    , offset : Int
    }


type Stop
    = Slip Fault
    | TooDeep


type alias Step =
    Result Stop Scanner


fault : Kind -> Scanner -> Result Stop a
fault kind scanner =
    Err (Slip { offset = scanner.offset, kind = kind })


advance : Int -> Scanner -> Scanner
advance count scanner =
    { rest = List.drop count scanner.rest, offset = scanner.offset + count }


peek : Scanner -> Maybe Char
peek scanner =
    List.head scanner.rest


peekIs : (Char -> Bool) -> Scanner -> Bool
peekIs test scanner =
    peek scanner |> Maybe.map test |> Maybe.withDefault False


skipSpace : Scanner -> Scanner
skipSpace =
    consumeWhile isSpace


isSpace : Char -> Bool
isSpace c =
    c == ' ' || c == '\n' || c == '\t' || c == '\u{000D}'


isControl : Char -> Bool
isControl c =
    Char.toCode c < 0x20


consumeWhile : (Char -> Bool) -> Scanner -> Scanner
consumeWhile keep scanner =
    if peekIs keep scanner then
        consumeWhile keep (advance 1 scanner)

    else
        scanner


{-| Skip `wanted` if it is next; otherwise stay.
-}
skipChar : Char -> Scanner -> Scanner
skipChar wanted scanner =
    if peek scanner == Just wanted then
        advance 1 scanner

    else
        scanner


expectEnd : Scanner -> Step
expectEnd scanner =
    case peek scanner of
        Nothing ->
            Ok scanner

        Just _ ->
            fault Stray scanner


expectChar : Char -> Scanner -> Step
expectChar wanted scanner =
    case peek scanner of
        Just c ->
            if c == wanted then
                Ok (advance 1 scanner)

            else
                fault Stray scanner

        Nothing ->
            fault Truncated scanner



-- VALUES


{-| The scanner sits on the first character of a value (whitespace skipped).
-}
value : Int -> Scanner -> Step
value depth scanner =
    case peek scanner of
        Nothing ->
            fault Truncated scanner

        Just '{' ->
            container '}' (member depth) depth (advance 1 scanner)

        Just '[' ->
            container ']' (value (depth + 1)) depth (advance 1 scanner)

        Just '"' ->
            string scanner

        Just c ->
            if isNumberStart c then
                number scanner

            else if Char.isAlpha c then
                literal scanner

            else
                fault Stray scanner


isNumberStart : Char -> Bool
isNumberStart c =
    c == '-' || Char.isDigit c


{-| `-? (0 | [1-9][0-9]*) (. digits)? ([eE] [+-]? digits)?`; every slip is
reported at the start of the number so the column points at what Elena typed.
-}
number : Scanner -> Step
number start =
    start
        |> skipChar '-'
        |> integerPart start
        |> Result.andThen (fractionPart start)
        |> Result.andThen (exponentPart start)


integerPart : Scanner -> Scanner -> Step
integerPart start scanner =
    case peek scanner of
        Nothing ->
            fault Truncated scanner

        Just '0' ->
            let
                after =
                    advance 1 scanner
            in
            if peekIs Char.isDigit after then
                fault BadNumber start

            else
                Ok after

        Just c ->
            if Char.isDigit c then
                Ok (consumeWhile Char.isDigit scanner)

            else
                fault BadNumber start


fractionPart : Scanner -> Scanner -> Step
fractionPart start scanner =
    if peek scanner == Just '.' then
        digits start (advance 1 scanner)

    else
        Ok scanner


exponentPart : Scanner -> Scanner -> Step
exponentPart start scanner =
    if peekIs isExponent scanner then
        scanner
            |> advance 1
            |> skipChar '+'
            |> skipChar '-'
            |> digits start

    else
        Ok scanner


isExponent : Char -> Bool
isExponent c =
    c == 'e' || c == 'E'


{-| At least one digit.
-}
digits : Scanner -> Scanner -> Step
digits start scanner =
    case peek scanner of
        Nothing ->
            fault Truncated scanner

        Just c ->
            if Char.isDigit c then
                Ok (consumeWhile Char.isDigit scanner)

            else
                fault BadNumber start


keywords : List String
keywords =
    [ "true", "false", "null" ]


{-| `true`, `false`, `null`; a cut-off keyword is a truncated text; any
other bare word is text someone forgot to quote.
-}
literal : Scanner -> Step
literal scanner =
    let
        word =
            scanner.rest
                |> List.take 5
                |> String.fromList

        startsWord keyword =
            String.startsWith keyword word

        cutOff keyword =
            String.startsWith word keyword && String.length word < String.length keyword
    in
    case List.filter startsWord keywords of
        keyword :: _ ->
            Ok (advance (String.length keyword) scanner)

        [] ->
            if List.any cutOff keywords then
                fault Truncated (advance (String.length word) scanner)

            else
                fault UnquotedText scanner


{-| The scanner sits on the opening quote. A raw newline before the closing
quote is an unterminated string, reported at the opening quote so the line
number points at the text the author can see; running out of text is
`Truncated` like everywhere else.
-}
string : Scanner -> Step
string scanner =
    stringBody scanner (advance 1 scanner)


stringBody : Scanner -> Scanner -> Step
stringBody start scanner =
    case peek scanner of
        Nothing ->
            fault Truncated scanner

        Just '\n' ->
            fault UnterminatedString start

        Just '"' ->
            Ok (advance 1 scanner)

        Just '\\' ->
            case escape scanner of
                Ok after ->
                    stringBody start after

                Err stop ->
                    Err stop

        Just c ->
            if isControl c then
                fault Stray scanner

            else
                stringBody start (advance 1 scanner)


{-| The scanner sits on the backslash: one of the eight simple escapes or
`\uXXXX`; anything else is reported at the backslash.
-}
escape : Scanner -> Step
escape scanner =
    let
        afterSlash =
            advance 1 scanner
    in
    case peek afterSlash of
        Nothing ->
            fault Truncated afterSlash

        Just 'u' ->
            hex4 scanner (advance 1 afterSlash)

        Just c ->
            if isSimpleEscape c then
                Ok (advance 1 afterSlash)

            else
                fault BadEscape scanner


isSimpleEscape : Char -> Bool
isSimpleEscape c =
    String.contains (String.fromChar c) "\"\\/bfnrt"


hex4 : Scanner -> Scanner -> Step
hex4 slash scanner =
    let
        run =
            List.take 4 scanner.rest
    in
    if List.length run < 4 then
        fault Truncated (advance (List.length run) scanner)

    else if List.all Char.isHexDigit run then
        Ok (advance 4 scanner)

    else
        fault BadEscape slash


{-| `"key" : value` inside an object.
-}
member : Int -> Scanner -> Step
member depth scanner =
    case peek scanner of
        Just '"' ->
            string scanner
                |> Result.map skipSpace
                |> Result.andThen (expectChar ':')
                |> Result.map skipSpace
                |> Result.andThen (value (depth + 1))

        Just c ->
            if Char.isAlpha c then
                fault UnquotedText scanner

            else
                fault Stray scanner

        Nothing ->
            fault Truncated scanner



-- CONTAINERS


{-| After the opening bracket: an empty container, or items separated by
commas up to `close`.
-}
container : Char -> (Scanner -> Step) -> Int -> Scanner -> Step
container close item depth scanner =
    let
        afterOpen =
            skipSpace scanner
    in
    if depth >= maxDepth then
        Err TooDeep

    else if peek afterOpen == Just close then
        Ok (advance 1 afterOpen)

    else
        items close item afterOpen


{-| What follows one item: another item, the closing bracket, or a slip.
-}
type Next
    = More Scanner
    | Done Scanner


{-| Self-recursive in tail position so Elm compiles it to a loop: a
container with thousands of items costs no stack.
-}
items : Char -> (Scanner -> Step) -> Scanner -> Step
items close item scanner =
    case item scanner |> Result.map skipSpace |> Result.andThen (afterItem close) of
        Ok (More next) ->
            items close item next

        Ok (Done end) ->
            Ok end

        Err stop ->
            Err stop


{-| A comma followed by `close` is the trailing comma, reported at `close`.
-}
afterItem : Char -> Scanner -> Result Stop Next
afterItem close scanner =
    case peek scanner of
        Nothing ->
            fault Truncated scanner

        Just ',' ->
            let
                next =
                    skipSpace (advance 1 scanner)
            in
            if peek next == Just close then
                fault TrailingComma next

            else
                Ok (More next)

        Just c ->
            if c == close then
                Ok (Done (advance 1 scanner))

            else
                fault Stray scanner
