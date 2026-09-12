(** Indented HTML emitter. Byte-compatible with the golden documents in [skeleton/]: two-space
    indentation, one element per line, text elements on a single line. Calculations only — the
    buffer is the sole state. *)

type attr = Kv of string * string | Flag of string

let kv key value = Kv (key, value)
let flag key = Flag key

type t = { buf : Buffer.t; mutable depth : int }

let create () = { buf = Buffer.create 16384; depth = 0 }

let replace_all ~pattern ~replacement s =
  Js.String.replaceByRe ~regexp:(Js.Re.fromStringWithFlags pattern ~flags:"g") ~replacement s

let escape_text s =
  s
  |> replace_all ~pattern:"&" ~replacement:"&amp;"
  |> replace_all ~pattern:"<" ~replacement:"&lt;"
  |> replace_all ~pattern:">" ~replacement:"&gt;"

let escape_attr s =
  s |> escape_text
  |> replace_all ~pattern:"\"" ~replacement:"&quot;"
  |> replace_all ~pattern:"'" ~replacement:"&#39;"

let indent t = Buffer.add_string t.buf (String.make (2 * t.depth) ' ')

let write_attrs t attrs =
  List.iter
    (function
      | Kv (key, value) ->
          Buffer.add_char t.buf ' ';
          Buffer.add_string t.buf key;
          Buffer.add_string t.buf "=\"";
          Buffer.add_string t.buf (escape_attr value);
          Buffer.add_char t.buf '"'
      | Flag key ->
          Buffer.add_char t.buf ' ';
          Buffer.add_string t.buf key)
    attrs

let doctype t = Buffer.add_string t.buf "<!DOCTYPE html>\n"

let open_ t tag attrs =
  indent t;
  Buffer.add_char t.buf '<';
  Buffer.add_string t.buf tag;
  write_attrs t attrs;
  Buffer.add_string t.buf ">\n";
  t.depth <- t.depth + 1

let close t tag =
  t.depth <- max 0 (t.depth - 1);
  indent t;
  Buffer.add_string t.buf "</";
  Buffer.add_string t.buf tag;
  Buffer.add_string t.buf ">\n"

let void t tag attrs =
  indent t;
  Buffer.add_char t.buf '<';
  Buffer.add_string t.buf tag;
  write_attrs t attrs;
  Buffer.add_string t.buf ">\n"

let text_el t tag attrs text =
  indent t;
  Buffer.add_char t.buf '<';
  Buffer.add_string t.buf tag;
  write_attrs t attrs;
  Buffer.add_char t.buf '>';
  Buffer.add_string t.buf (escape_text text);
  Buffer.add_string t.buf "</";
  Buffer.add_string t.buf tag;
  Buffer.add_string t.buf ">\n"

(** Raw, pre-rendered markup inserted verbatim at the current depth. *)
let raw t markup = Buffer.add_string t.buf markup

let contents t = Buffer.contents t.buf
