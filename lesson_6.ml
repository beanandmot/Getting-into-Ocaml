(*
  LESSON 6: Records, Deeper Variants, and the Result Type

  In lessons 4 and 5 you learned:
  - Variants: types that are "this OR that"
  - Pattern matching on them
  - map / filter / fold on lists

  This lesson adds three things you need to build real programs:

    Records       -- named fields, like a struct or dataclass
    Deeper variants -- variants that carry records, not just primitives
    Result type   -- the OCaml way to handle errors without exceptions

  By the end of this lesson you will be able to model
  a real payload validator for your AI framework.

  Run everything on: https://ocaml.org/play
*)


(*
  =========================
  PART 1: RECORDS
  =========================

  WHAT THEY ARE:
  A record is a type with NAMED fields.
  Every field has a name AND a type.
  All fields are always present.

  Think of it like a Python dataclass or TypeScript interface --
  but the compiler enforces the shape at compile time.

  SYNTAX TO DEFINE:

      type my_record = {
        field_name : type;
        field_name : type;
      }

  SYNTAX TO CREATE:

      let r = { field_name = value; field_name = value }

  SYNTAX TO READ A FIELD:

      r.field_name

  SIMPLE EXAMPLE:
*)

type person = {
  name  : string;
  age   : int;
  email : string;
}

(*
  This defines a type called person.
  Every person value MUST have all three fields.
  The compiler will reject a person with a missing or wrong-typed field.
*)

let alice = { name = "Alice"; age = 30; email = "alice@example.com" }
let bob   = { name = "Bob";   age = 25; email = "bob@example.com"   }

(*
  ACCESS fields with dot notation:
*)

let () =
  Printf.printf "Name: %s\n" alice.name;
  Printf.printf "Age:  %d\n" alice.age;
  Printf.printf "Email: %s\n" alice.email


(*
  PATTERN MATCHING on records:

  You can destructure a record in a match or let binding.
  Use { field_name; ... } to pull out fields by name.
*)

let greet person =
  Printf.printf "Hello, %s! You are %d years old.\n" person.name person.age

let () =
  greet alice;
  greet bob


(*
  RECORD UPDATE SYNTAX:

  Records are IMMUTABLE by default.
  To "change" a field you create a NEW record with { old with field = new_value }.
  The original is untouched.
*)

let older_alice = { alice with age = alice.age + 1 }

(*
  older_alice is a NEW record.
  alice is unchanged.

  This is safe because nothing else holding a reference to alice
  will ever see a surprise mutation. There are no surprises.
*)

let () =
  Printf.printf "alice.age       = %d\n" alice.age;
  Printf.printf "older_alice.age = %d\n" older_alice.age


(*
  RECORDS vs TUPLES -- WHEN TO USE WHICH:

  Tuples:
    - Unnamed, positional: (1, "hello", true)
    - Fine for small, obvious groupings: (x, y) coordinates
    - Gets confusing with more than 2-3 fields

  Records:
    - Named fields
    - Self-documenting: { name = "Alice"; age = 30 }
    - Required once the shape has more than ~2 fields
    - Much easier to read and maintain

  Rule: if you find yourself writing tuples with 3+ elements, use a record.
*)


(*
  =========================
  PART 2: VARIANTS CARRYING RECORDS
  =========================

  In lesson 4, variants carried simple values:

      type shape =
        | Circle    of float
        | Rectangle of float * float

  Variants can also carry RECORDS.
  This is how you model richer, named data attached to each case.

  EXAMPLE: model different kinds of events in an AI pipeline
*)

type event =
  | NodeStarted  of { node_name : string; timestamp : float }
  | NodeFinished of { node_name : string; duration_ms : float; success : bool }
  | NodeFailed   of { node_name : string; error_msg : string }

(*
  Each constructor carries a different record shape.
  NodeStarted carries a name and a timestamp.
  NodeFinished carries a name, duration, and success flag.
  NodeFailed carries a name and an error message.

  Pattern match to get the fields out:
*)

let describe_event ev =
  match ev with
  | NodeStarted  { node_name; timestamp } ->
      Printf.printf "[%.2f] %s STARTED\n" timestamp node_name
  | NodeFinished { node_name; duration_ms; success } ->
      Printf.printf "%s FINISHED in %.1fms, success=%b\n"
        node_name duration_ms success
  | NodeFailed   { node_name; error_msg } ->
      Printf.printf "%s FAILED: %s\n" node_name error_msg

let () =
  let events = [
    NodeStarted  { node_name = "fetch_user";   timestamp = 1000.0 };
    NodeFinished { node_name = "fetch_user";   duration_ms = 12.5; success = true };
    NodeStarted  { node_name = "validate_pii"; timestamp = 1012.5 };
    NodeFailed   { node_name = "validate_pii"; error_msg = "SSN field present" };
  ] in
  List.iter describe_event events

(*
  NOTICE:
  The compiler forces you to handle ALL three cases.
  If you forget NodeFailed, it warns you about a non-exhaustive match.
  You cannot accidentally miss an event type.

  This is the core OCaml safety guarantee.
*)


(*
  =========================
  PART 3: THE RESULT TYPE
  =========================

  WHAT IT IS:
  Result is a built-in variant for operations that can succeed or fail.

  TYPE:
      type ('ok, 'err) result =
        | Ok    of 'ok
        | Error of 'err

  'ok  is the type of the SUCCESS value.
  'err is the type of the ERROR value.

  It is like Option (Some/None) but the failure case carries information.

  WHY NOT EXCEPTIONS?
  Exceptions in Python and OCaml are invisible in the type signature.
  You cannot tell from the type of a function whether it might crash.

  With Result:
  - The function's return type tells you it can fail
  - The compiler forces you to handle both cases
  - Errors are values, not surprises

  SIMPLE EXAMPLE:
*)

let safe_divide a b =
  if b = 0
  then Error "division by zero"
  else Ok (a / b)

(*
  TYPE: int -> int -> (int, string) result

  The return type explicitly says:
  "this gives you either an int or a string error"

  You MUST handle both when you use it:
*)

let () =
  let result_a = safe_divide 10 2 in
  let result_b = safe_divide 10 0 in

  (match result_a with
  | Ok value    -> Printf.printf "10 / 2 = %d\n" value
  | Error msg   -> Printf.printf "Error: %s\n" msg);

  (match result_b with
  | Ok value    -> Printf.printf "10 / 0 = %d\n" value
  | Error msg   -> Printf.printf "Error: %s\n" msg)

(*
  result_a = Ok 5      -> prints "10 / 2 = 5"
  result_b = Error ... -> prints "Error: division by zero"
*)


(*
  CHAINING RESULTS:

  A common pattern: you have multiple steps that can each fail.
  You want to stop at the first failure and propagate the error.

  The pattern is match -> if Ok continue -> if Error stop.

  EXAMPLE: parse a string as int, then divide
*)

let parse_int s =
  match int_of_string_opt s with
  | Some n -> Ok n
  | None   -> Error ("not a number: " ^ s)

let divide_strings a_str b_str =
  match parse_int a_str with
  | Error msg -> Error msg
  | Ok a ->
    match parse_int b_str with
    | Error msg -> Error msg
    | Ok b -> safe_divide a b

let () =
  let cases = [
    ("10", "2");
    ("10", "0");
    ("10", "abc");
    ("xyz", "2");
  ] in
  List.iter (fun (a, b) ->
    match divide_strings a b with
    | Ok v    -> Printf.printf "%s / %s = %d\n" a b v
    | Error e -> Printf.printf "%s / %s -> Error: %s\n" a b e
  ) cases

(*
  TRACE:
  "10" / "2"   -> parse 10 -> Ok 10, parse 2 -> Ok 2, divide -> Ok 5
  "10" / "0"   -> parse 10 -> Ok 10, parse 2 -> Ok 0, divide -> Error
  "10" / "abc" -> parse 10 -> Ok 10, parse "abc" -> Error
  "xyz" / "2"  -> parse "xyz" -> Error (stops immediately)
*)


(*
  =========================
  PART 4: PUTTING IT TOGETHER
  =========================

  Now we build something directly relevant to your validator:

  A payload is a record with named fields.
  Some fields may or may not be present (option).
  Validation returns a Result.

  This is the exact shape of what the OCaml validator will do.
*)


(*
  STEP 1: define what a payload looks like

  These are the fields an AI node might receive.
  ssn and credit_card are option types --
  they might be absent (None) or present (Some value).
*)

type payload = {
  user_id     : string;
  user_name   : string;
  query       : string;
  ssn         : string option;
  credit_card : string option;
}


(*
  STEP 2: define what validation errors look like

  Each constructor is a specific reason validation failed.
  Not just a string -- a structured, matchable value.
*)

type validation_error =
  | PiiFieldPresent of { field_name : string }
  | RequiredFieldMissing of { field_name : string }
  | FieldTooLong of { field_name : string; max_len : int; actual_len : int }


(*
  STEP 3: write validators that return Result

  Each validator takes a payload and returns:
    Ok payload   -- passed, payload is clean
    Error ...    -- failed, with a structured reason
*)

let check_no_ssn p =
  match p.ssn with
  | None   -> Ok p
  | Some _ -> Error (PiiFieldPresent { field_name = "ssn" })

let check_no_credit_card p =
  match p.credit_card with
  | None   -> Ok p
  | Some _ -> Error (PiiFieldPresent { field_name = "credit_card" })

let check_query_not_empty p =
  if String.length p.query = 0
  then Error (RequiredFieldMissing { field_name = "query" })
  else Ok p

let check_query_length p =
  let max_len = 500 in
  let actual  = String.length p.query in
  if actual > max_len
  then Error (FieldTooLong { field_name = "query"; max_len; actual_len = actual })
  else Ok p


(*
  STEP 4: chain validators together

  Run each check in sequence.
  Stop at the first failure.
  Return Ok only if ALL pass.
*)

let validate_payload p =
  match check_no_ssn p with
  | Error e -> Error e
  | Ok p ->
    match check_no_credit_card p with
    | Error e -> Error e
    | Ok p ->
      match check_query_not_empty p with
      | Error e -> Error e
      | Ok p ->
        check_query_length p


(*
  STEP 5: describe errors in a human-readable way

  This is what gets sent back to Python as the error message.
*)

let describe_error err =
  match err with
  | PiiFieldPresent { field_name } ->
      Printf.sprintf "PII field '%s' must not be present" field_name
  | RequiredFieldMissing { field_name } ->
      Printf.sprintf "Required field '%s' is missing or empty" field_name
  | FieldTooLong { field_name; max_len; actual_len } ->
      Printf.sprintf "Field '%s' is too long: max %d, got %d"
        field_name max_len actual_len


(*
  STEP 6: test it
*)

let () =
  let clean_payload = {
    user_id     = "u_123";
    user_name   = "Alice";
    query       = "What is the weather today?";
    ssn         = None;
    credit_card = None;
  } in

  let pii_payload = {
    user_id     = "u_456";
    user_name   = "Bob";
    query       = "Help me";
    ssn         = Some "123-45-6789";
    credit_card = None;
  } in

  let empty_query_payload = {
    user_id     = "u_789";
    user_name   = "Carol";
    query       = "";
    ssn         = None;
    credit_card = None;
  } in

  let payloads = [clean_payload; pii_payload; empty_query_payload] in

  List.iter (fun p ->
    match validate_payload p with
    | Ok _    -> Printf.printf "[%s] PASSED\n" p.user_id
    | Error e -> Printf.printf "[%s] FAILED: %s\n" p.user_id (describe_error e)
  ) payloads

(*
  EXPECTED OUTPUT:

  [u_123] PASSED
  [u_456] FAILED: PII field 'ssn' must not be present
  [u_789] FAILED: Required field 'query' is missing or empty
*)


(*
  =========================
  KEY TAKEAWAYS
  =========================

  RECORDS:
  - Named fields, all required, all typed
  - Define with: type t = { field : type; ... }
  - Create with: { field = value; ... }
  - Access with: record.field
  - Update (immutably) with: { old with field = new_value }
  - Use records over tuples whenever you have 3+ fields

  VARIANTS CARRYING RECORDS:
  - Each constructor can carry a different record shape
  - | NodeFailed of { node_name : string; error_msg : string }
  - Pattern match pulls out the named fields cleanly
  - Compiler enforces exhaustiveness -- no forgotten cases

  RESULT TYPE:
  - type ('ok, 'err) result = Ok of 'ok | Error of 'err
  - The return type explicitly declares that failure is possible
  - Forces you to handle both cases at every call site
  - Chain with match: on Ok continue, on Error stop and propagate
  - Use structured error types (variants), not plain strings,
    so callers can match on the specific failure reason

  FOR YOUR VALIDATOR:
  - payload is a record: typed, named, complete
  - validation_error is a variant: each failure reason is distinct
  - each check returns Result: errors are values, not exceptions
  - chained checks: stop at first failure, clean payload passes through
  - describe_error turns a structured error into a string for Python

  WHAT YOU CAN NOW BUILD:
  A real OCaml validator that reads a JSON payload,
  checks it against typed rules, and exits with either
  a clean result or a structured error message.
  That is exactly what the subprocess validator needs.
*)
