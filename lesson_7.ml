(*
  LESSON 7: Yojson and JSON Parsing

  In lesson 6 you built:
  - A payload record type
  - A validation_error variant type
  - Validators that return Result
  - A chain that stops at the first failure

  That was the LOGIC layer -- pure OCaml, no external dependencies.

  This lesson adds the INTEGRATION layer:
  - How Yojson represents JSON as OCaml values
  - How to parse a JSON string into your typed record
  - How to build a JSON response and convert it back to a string
  - How to wire it all into a program Python can call

  By the end of this lesson you will understand:
  - The Yojson type and how to pattern match on it
  - How to extract fields safely using Result
  - How to serialize OCaml values back to JSON
  - The full shape of the validator entry point

  NOTE ON RUNNING THIS LESSON:
  This lesson uses Yojson, an external library.
  It cannot run on ocaml.org/play directly.
  Use the separate COLAB_SETUP.md to get your environment ready.
  Once set up, compile and run with:

      ocamlfind ocamlopt -package yojson -linkpkg lesson_7.ml -o lesson_7 && ./lesson_7
*)


(*
  =========================
  PART 1: WHAT IS YOJSON
  =========================

  JSON is just text. For example:

      {"user_id": "u_123", "query": "hello", "ssn": null}

  OCaml cannot use raw text directly.
  Yojson parses that text into an OCaml value you can pattern match on.

  Yojson represents ANY JSON value using this variant:

      type t =
        | `Null
        | `Bool   of bool
        | `Int    of int
        | `Float  of float
        | `String of string
        | `List   of t list
        | `Assoc  of (string * t) list

  NOTE: These constructors use a backtick -- `Null, `String, `Assoc.
  These are called POLYMORPHIC VARIANTS.
  They work exactly like the regular variants you learned in lesson 4.
  The backtick is just syntax. Match on them the same way.

  THE ONE YOU WILL USE MOST: `Assoc

  A JSON object maps to `Assoc -- an association list of (key, value) pairs.

  EXAMPLE:
  {"user_id": "u_123", "age": 30}
  becomes:
      `Assoc [("user_id", `String "u_123"); ("age", `Int 30)]

  FULL MAPPING:

  JSON                      Yojson
  ----                      ------
  "hello"                -> `String "hello"
  42                     -> `Int 42
  3.14                   -> `Float 3.14
  true                   -> `Bool true
  null                   -> `Null
  ["a", "b"]             -> `List [`String "a"; `String "b"]
  {"key": "val"}         -> `Assoc [("key", `String "val")]
*)


(*
  =========================
  PART 2: THE THREE FUNCTIONS YOU NEED
  =========================

  Yojson.Safe.from_string : string -> Yojson.Safe.t
    Parse a raw JSON string into a Yojson value.
    Raises an exception if the string is not valid JSON.

  Yojson.Safe.to_string : Yojson.Safe.t -> string
    Convert a Yojson value back into a JSON string.

  List.assoc_opt : string -> (string * 'a) list -> 'a option
    Look up a key in an association list.
    Returns Some value if found, None if missing.
    SAFE: never raises, unlike List.assoc.

  SIMPLE EXAMPLE:
*)

let () =
  let raw = {|{"name": "Alice", "age": 30}|} in

  (*
    {| ... |} is OCaml's raw string syntax.
    Inside {| |} you do not need to escape quotes.
    Exactly like Python's triple-quoted strings.
    Very useful for writing JSON inline.
  *)

  let json = Yojson.Safe.from_string raw in

  (*
    json is now:
    `Assoc [("name", `String "Alice"); ("age", `Int 30)]

    Pattern match to extract what we need:
  *)

  match json with
  | `Assoc fields ->
      let name = List.assoc_opt "name" fields in
      let age  = List.assoc_opt "age"  fields in
      (match name, age with
      | Some (`String n), Some (`Int a) ->
          Printf.printf "Name: %s, Age: %d\n" n a
      | _ ->
          print_endline "Unexpected field types")
  | _ ->
      print_endline "Expected a JSON object"

(*
  TRACE:

  raw    = {"name": "Alice", "age": 30}
  json   = `Assoc [("name", `String "Alice"); ("age", `Int 30)]
  fields = [("name", `String "Alice"); ("age", `Int 30)]

  List.assoc_opt "name" fields = Some (`String "Alice")
  List.assoc_opt "age"  fields = Some (`Int 30)

  match (Some (`String "Alice"), Some (`Int 30)):
    n = "Alice", a = 30
    -> prints "Name: Alice, Age: 30"

  WHY List.assoc_opt and not List.assoc?
  List.assoc raises Not_found if the key is missing.
  That is an exception -- invisible in the type signature.
  List.assoc_opt returns option -- forces you to handle the missing case.
  We always use assoc_opt.
*)


(*
  =========================
  PART 3: BUILDING JSON OUTPUT
  =========================

  Yojson.Safe.to_string converts a Yojson value back to a JSON string.
  You build the Yojson value using the same constructors.
*)

let () =
  let ok_response =
    `Assoc [
      ("status",  `String "ok");
      ("user_id", `String "u_123");
      ("query",   `String "What is the weather?");
    ]
  in
  let err_response =
    `Assoc [
      ("status",  `String "error");
      ("message", `String "PII field 'ssn' must not be present");
    ]
  in
  Printf.printf "ok:  %s\n" (Yojson.Safe.to_string ok_response);
  Printf.printf "err: %s\n" (Yojson.Safe.to_string err_response)

(*
  EXPECTED OUTPUT:
  ok:  {"status":"ok","user_id":"u_123","query":"What is the weather?"}
  err: {"status":"error","message":"PII field 'ssn' must not be present"}

  NOTE: to_string produces compact JSON with no spaces.
  That is fine -- Python's json.loads handles it perfectly.

  HANDLING option IN JSON OUTPUT:
  None   -> `Null
  Some s -> `String s

  The pattern:
      match p.ssn with None -> `Null | Some s -> `String s
*)

let () =
  let with_ssn    = Some "123-45-6789" in
  let without_ssn = (None : string option) in
  let to_json opt = match opt with None -> `Null | Some s -> `String s in
  Printf.printf "with ssn:    %s\n" (Yojson.Safe.to_string (to_json with_ssn));
  Printf.printf "without ssn: %s\n" (Yojson.Safe.to_string (to_json without_ssn))

(*
  EXPECTED:
  with ssn:    "123-45-6789"
  without ssn: null
*)


(*
  =========================
  PART 4: PARSING HELPERS THAT RETURN RESULT
  =========================

  We want to go from raw JSON to a typed payload record.
  Each field extraction can fail (wrong type, missing key).
  We want those failures as Result values, not exceptions.

  Two helpers:

  parse_string_field:
    Required field. Must be present and must be a string.
    Ok s      if found and is a string
    Error msg if missing or wrong type

  parse_optional_string_field:
    Optional field. Can be absent or null.
    Ok None   if missing or null
    Ok Some s if present and is a string
    Error msg if present but wrong type
*)

let parse_string_field key fields =
  match List.assoc_opt key fields with
  | Some (`String s) -> Ok s
  | Some _           -> Error ("field '" ^ key ^ "' has wrong type, expected string")
  | None             -> Error ("field '" ^ key ^ "' is missing")

let parse_optional_string_field key fields =
  match List.assoc_opt key fields with
  | None             -> Ok None
  | Some `Null       -> Ok None
  | Some (`String s) -> Ok (Some s)
  | Some _           -> Error ("field '" ^ key ^ "' has wrong type, expected string or null")

let () =
  let fields = [
    ("user_id", `String "u_123");
    ("query",   `String "hello");
    ("ssn",     `Null);
    ("score",   `Int 42);
  ] in

  (* required field present -> Ok *)
  (match parse_string_field "user_id" fields with
  | Ok s    -> Printf.printf "user_id: %s\n" s
  | Error e -> Printf.printf "ERROR: %s\n" e);

  (* required field missing -> Error *)
  (match parse_string_field "user_name" fields with
  | Ok s    -> Printf.printf "user_name: %s\n" s
  | Error e -> Printf.printf "user_name missing (expected): %s\n" e);

  (* required field wrong type -> Error *)
  (match parse_string_field "score" fields with
  | Ok s    -> Printf.printf "score: %s\n" s
  | Error e -> Printf.printf "score wrong type (expected): %s\n" e);

  (* optional field null -> Ok None *)
  (match parse_optional_string_field "ssn" fields with
  | Ok None     -> print_endline "ssn: None (null, expected)"
  | Ok (Some s) -> Printf.printf "ssn: %s\n" s
  | Error e     -> Printf.printf "ERROR: %s\n" e);

  (* optional field missing -> Ok None *)
  (match parse_optional_string_field "credit_card" fields with
  | Ok None     -> print_endline "credit_card: None (missing, expected)"
  | Ok (Some s) -> Printf.printf "credit_card: %s\n" s
  | Error e     -> Printf.printf "ERROR: %s\n" e)

(*
  EXPECTED:
  user_id: u_123
  user_name missing (expected): field 'user_name' is missing
  score wrong type (expected): field 'score' has wrong type, expected string
  ssn: None (null, expected)
  credit_card: None (missing, expected)
*)


(*
  =========================
  PART 5: PARSING JSON INTO A RECORD
  =========================

  Now combine everything into one function:
  raw JSON string -> typed payload record.

  This is called DESERIALIZATION.
  Untyped JSON -> typed OCaml record.

  The function chains Result all the way through:
  stop at the first missing or wrong-typed field.
*)

type payload = {
  user_id     : string;
  user_name   : string;
  query       : string;
  ssn         : string option;
  credit_card : string option;
}

let parse_payload json_str =
  (*
    Step 1: parse the raw string into Yojson.
    from_string raises on invalid JSON so we wrap it in try.
  *)
  let json =
    try Ok (Yojson.Safe.from_string json_str)
    with _ -> Error "invalid JSON"
  in
  (*
    Step 2: expect a JSON object at the top level.
    Step 3: extract each field, chaining Result.
    Stop at first error. Return Ok record only if all pass.
  *)
  match json with
  | Error e -> Error e
  | Ok (`Assoc fields) ->
      (match parse_string_field "user_id" fields with
      | Error e -> Error e
      | Ok user_id ->
        match parse_string_field "user_name" fields with
        | Error e -> Error e
        | Ok user_name ->
          match parse_string_field "query" fields with
          | Error e -> Error e
          | Ok query ->
            match parse_optional_string_field "ssn" fields with
            | Error e -> Error e
            | Ok ssn ->
              match parse_optional_string_field "credit_card" fields with
              | Error e -> Error e
              | Ok credit_card ->
                Ok { user_id; user_name; query; ssn; credit_card })
  | Ok _ -> Error "expected a JSON object at the top level"

(*
  TRACE: clean input

  Input:
    {"user_id":"u_1","user_name":"Alice","query":"hello","ssn":null,"credit_card":null}

  Step 1: from_string -> Ok (`Assoc [...])
  Step 2: match `Assoc fields
  Step 3: parse "user_id"     -> Ok "u_1"
  Step 4: parse "user_name"   -> Ok "Alice"
  Step 5: parse "query"       -> Ok "hello"
  Step 6: parse "ssn"         -> Ok None   (null -> None)
  Step 7: parse "credit_card" -> Ok None   (missing -> None)
  Result: Ok { user_id="u_1"; user_name="Alice"; query="hello"; ... }

  TRACE: missing field

  Input: {"user_name":"Alice","query":"hello","ssn":null,"credit_card":null}
  Step 3: parse "user_id" -> Error "field 'user_id' is missing"
  -> immediately return Error, skip all remaining steps

  TRACE: invalid JSON

  Input: not valid json at all
  Step 1: from_string raises -> we catch it -> Error "invalid JSON"
  -> immediately return Error

  NOTE: parsing and validation are SEPARATE steps.
  parse_payload only asks: is the JSON well-formed and are fields typed correctly?
  validate_payload (lesson 6) asks: do the values satisfy business rules?
*)

let () =
  let cases = [
    {|{"user_id":"u_1","user_name":"Alice","query":"What is the weather?","ssn":null,"credit_card":null}|};
    {|{"user_id":"u_2","user_name":"Bob","query":"Help","ssn":"123-45-6789","credit_card":null}|};
    {|{"user_name":"Carol","query":"Hello","ssn":null}|};
    {|not valid json|};
  ] in
  List.iter (fun s ->
    match parse_payload s with
    | Ok p    -> Printf.printf "Parsed OK: user_id=%s\n" p.user_id
    | Error e -> Printf.printf "Parse error: %s\n" e
  ) cases

(*
  EXPECTED:
  Parsed OK: user_id=u_1
  Parsed OK: user_id=u_2    <- ssn present but parse succeeds; validation catches it
  Parse error: field 'user_id' is missing
  Parse error: invalid JSON
*)


(*
  =========================
  PART 6: THE COMPLETE VALIDATOR
  =========================

  Bring in the validators from lesson 6 -- nothing changes.
  Add JSON output functions.
  Wire into a complete entry point.
*)

type validation_error =
  | PiiFieldPresent      of { field_name : string }
  | RequiredFieldMissing of { field_name : string }
  | FieldTooLong         of { field_name : string; max_len : int; actual_len : int }

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

let describe_error err =
  match err with
  | PiiFieldPresent { field_name } ->
      Printf.sprintf "PII field '%s' must not be present" field_name
  | RequiredFieldMissing { field_name } ->
      Printf.sprintf "Required field '%s' is missing or empty" field_name
  | FieldTooLong { field_name; max_len; actual_len } ->
      Printf.sprintf "Field '%s' is too long: max %d, got %d"
        field_name max_len actual_len

let payload_to_json p =
  `Assoc [
    ("user_id",     `String p.user_id);
    ("user_name",   `String p.user_name);
    ("query",       `String p.query);
    ("ssn",         (match p.ssn         with None -> `Null | Some s -> `String s));
    ("credit_card", (match p.credit_card with None -> `Null | Some s -> `String s));
  ]

let make_ok_response p =
  `Assoc [ ("status", `String "ok"); ("payload", payload_to_json p) ]

let make_error_response msg =
  `Assoc [ ("status", `String "error"); ("message", `String msg) ]


(*
  THE ENTRY POINT

  This is what runs when Python calls ./validator.

  1. Python sends a JSON payload on stdin
  2. We read all of stdin into a string
  3. parse_payload  -> Ok payload   or Error string
  4. validate_payload -> Ok clean   or Error validation_error
  5. Print JSON result to stdout
  6. exit 0 (success) or exit 1 (failure)

  WHY exit 0 / exit 1?
  Unix convention: exit 0 = success, exit 1 = failure.
  Python's subprocess.run gives you returncode.
  returncode 0 = ok. Anything else = error.
  Python reads that and either continues or raises.
*)

let () =
  let input =
    let buf = Buffer.create 256 in
    (try while true do Buffer.add_channel buf stdin 1 done
     with End_of_file -> ());
    Buffer.contents buf
  in
  match parse_payload input with
  | Error e ->
      print_string (Yojson.Safe.to_string (make_error_response ("parse error: " ^ e)));
      exit 1
  | Ok payload ->
    match validate_payload payload with
    | Error e ->
        print_string (Yojson.Safe.to_string (make_error_response (describe_error e)));
        exit 1
    | Ok clean ->
        print_string (Yojson.Safe.to_string (make_ok_response clean));
        exit 0


(*
  =========================
  THE PYTHON SIDE (reference -- not OCaml)
  =========================

  This is the function you add to your framework.
  Eight lines. That is the entire integration.

      import subprocess, json

      def validate_with_ocaml(payload: dict) -> dict:
          result = subprocess.run(
              ["./validator"],
              input=json.dumps(payload),
              capture_output=True,
              text=True
          )
          response = json.loads(result.stdout)
          if result.returncode != 0:
              raise ValueError(response["message"])
          return response["payload"]

  In BaseNode.post():

      def post(self, shared, prep_res, exec_res):
          return validate_with_ocaml(exec_res)

  In LangChain:

      from langchain_core.runnables import RunnableLambda
      validate = RunnableLambda(validate_with_ocaml)
      chain = fetch_node | validate | llm_node

  OCaml handles correctness. Python handles orchestration.
*)


(*
  =========================
  KEY TAKEAWAYS
  =========================

  YOJSON TYPE:
  - JSON object  -> `Assoc [(key, value); ...]
  - JSON string  -> `String s
  - JSON int     -> `Int n
  - JSON null    -> `Null
  - JSON list    -> `List [...]
  - Backtick constructors = polymorphic variants
  - Match on them exactly like regular variants

  THREE FUNCTIONS:
  - Yojson.Safe.from_string  string -> Yojson.Safe.t    (parse)
  - Yojson.Safe.to_string    Yojson.Safe.t -> string    (serialize)
  - List.assoc_opt            safe key lookup -> option

  DESERIALIZATION PATTERN:
  - Wrap from_string in try to catch invalid JSON
  - Match on `Assoc fields at the top level
  - Extract each field with helpers that return Result
  - Chain: stop at first error
  - Keep parsing and validation as separate steps

  THE VALIDATOR SHAPE:
  1. Read stdin
  2. parse_payload    -> Result
  3. validate_payload -> Result
  4. Print JSON to stdout
  5. exit 0 or exit 1

  PYTHON INTEGRATION:
  - subprocess.run(["./validator"], input=json_str)
  - returncode 0 = ok, 1 = error
  - stdout = JSON with status + payload or message
  - Hook into BaseNode.post() or LangChain RunnableLambda
*)
