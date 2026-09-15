(** JSON Resume [iso8601] dates: [YYYY], [YYYY-MM], [YYYY-MM-DD]. Pure calculations; see
    CLASS-CONTRACT §5.3 "Dates" for the rules ported here. *)

type t = { year : int; month : int option; day : int option }

let month_names =
  [|
    "January";
    "February";
    "March";
    "April";
    "May";
    "June";
    "July";
    "August";
    "September";
    "October";
    "November";
    "December";
  |]

let month_name month = if month >= 1 && month <= 12 then Some month_names.(month - 1) else None

let datetime t =
  match (t.month, t.day) with
  | Some month, Some day -> Printf.sprintf "%04d-%02d-%02d" t.year month day
  | Some month, None -> Printf.sprintf "%04d-%02d" t.year month
  | _ -> Printf.sprintf "%04d" t.year

let visible t =
  match (Option.bind t.month month_name, t.day) with
  | Some month, Some day -> Printf.sprintf "%s %d, %d" month day t.year
  | Some month, None -> Printf.sprintf "%s %d" month t.year
  | _ -> string_of_int t.year

let is_leap_year year = year mod 4 = 0 && (year mod 100 <> 0 || year mod 400 = 0)

let days_in_month year month =
  match month with
  | 1 | 3 | 5 | 7 | 8 | 10 | 12 -> 31
  | 4 | 6 | 9 | 11 -> 30
  | 2 when is_leap_year year -> 29
  | 2 -> 28
  | _ -> 0

let is_calendar_valid t =
  match (t.month, t.day) with
  | None, _ -> true
  | Some month, None -> month >= 1 && month <= 12
  | Some month, Some day -> day >= 1 && day <= days_in_month t.year month

(** Exactly [len] ASCII digits, as an int. *)
let digits len text =
  let pattern = Printf.sprintf "^[0-9]{%d}$" len in
  if Js.Re.test ~str:text (Js.Re.fromString pattern) then int_of_string_opt text else None

let time_tail = Js.Re.fromString "^[0-9]{2}:"

(** Drop a time component after [T] or a space, but only when what follows looks like a clock
    ([HH:]). Prose after a space stays part of the token. *)
let date_part raw =
  let first_of a b = match (a, b) with -1, b -> b | a, -1 -> a | a, b -> min a b in
  let cut = first_of (Js.String.indexOf ~search:"T" raw) (Js.String.indexOf ~search:" " raw) in
  if cut < 0 then raw
  else
    let tail = Js.String.slice ~start:(cut + 1) raw in
    if Js.Re.test ~str:tail time_tail then Js.String.slice ~start:0 ~end_:cut raw else raw

let ( let** ) = Option.bind

let parse raw =
  let parts = Js.String.split ~sep:"-" (date_part (Js.String.trim raw)) in
  let candidate =
    match Array.to_list parts with
    | [ year ] ->
        let** year = digits 4 year in
        Some { year; month = None; day = None }
    | [ year; month ] ->
        let** year = digits 4 year in
        let** month = digits 2 month in
        Some { year; month = Some month; day = None }
    | [ year; month; day ] ->
        let** year = digits 4 year in
        let** month = digits 2 month in
        let** day = digits 2 day in
        Some { year; month = Some month; day = Some day }
    | _ -> None
  in
  Option.bind candidate (fun date -> if is_calendar_valid date then Some date else None)
