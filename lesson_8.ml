(*
  LESSON 8: Modules and ppx_deriving

  So far every lesson has been a single file.
  Real OCaml programs are split across many files.

  This lesson covers two things that make that possible
  and that directly improve your validator:

  1. MODULES
     - What they are and why they exist
     - How to define your own
     - How to use them (dot notation, open, include)
     - How files ARE modules automatically
     - Signatures: controlling what a module exposes

  2. PPX_DERIVING (specifically ppx_deriving_yojson)
     - What ppx is and why it exists
     - How to auto-generate JSON parsers from types
     - Before and after: the validator with and without boilerplate
     - The 10-line validator vs the 80-line validator

  By the end of this lesson you will:
  - Understand what List.map, Yojson.Safe etc. actually ARE
  - Be able to define and use your own modules
  - Know how to eliminate all the hand-written JSON parsing code
    from the validator using ppx_deriving_yojson

  NOTE ON RUNNING:
  Part 1 (modules) can run on https://ocaml.org/play
  Part 2 (ppx) requires Colab. See COLAB_SETUP.md.
  Install command for Part 2:
      opam install ppx_deriving_yojson
*)


(*
  =========================
  PART 1: WHAT IS A MODULE
  =========================

  You have been using modules since lesson 1.

  Every time you wrote:

      List.map
      List.filter
      List.fold_left
      Yojson.Safe.from_string
      Printf.printf
      String.length

  ...you were using a module.

  The DOT means:
      ModuleName.thing_inside_it

  A module is a NAMED COLLECTION of:
  - Values (let bindings)
  - Functions
  - Types
  - Other modules (nested)

  Think of it like a namespace in Python or C++:
      Python:   os.path.join(...)
      C++:      std::vector<int>
      OCaml:    List.map (...)

  WHY DO MODULES EXIST?

  Without modules, every function in the standard library
  would need a unique name to avoid collisions:

      list_map, list_filter, list_fold_left
      string_length, string_uppercase
      array_get, array_set ...

  With modules:

      List.map, List.filter, List.fold_left
      String.length, String.uppercase_ascii
      Array.get, Array.set ...

  Clean. Clear. No collisions.

  The module name tells you WHERE a function comes from.

  QUICK REFERENCE: modules you already know

  List       -- List.map, List.filter, List.fold_left, List.iter,
                List.length, List.assoc_opt, List.exists, List.nth
  String     -- String.length, String.uppercase_ascii, String.sub
  Printf     -- Printf.printf, Printf.sprintf
  Buffer     -- Buffer.create, Buffer.add_channel, Buffer.contents
  Yojson     -- Yojson.Safe.from_string, Yojson.Safe.to_string
*)


(*
  =========================
  PART 2: DEFINING YOUR OWN MODULE
  =========================

  SYNTAX:

      module ModuleName = struct
        (* values, types, functions here *)
      end

  NAMING CONVENTION:
  Module names ALWAYS start with a capital letter.
  This is enforced by OCaml -- lowercase is a compiler error.

  SIMPLE EXAMPLE: a Math module
*)

module Math = struct

  let pi = 3.14159

  let square x = x *. x

  let circle_area r = pi *. square r

  let abs x = if x < 0 then -x else x

end

(*
  Now use it:
*)

let () =
  Printf.printf "pi         = %f\n" Math.pi;
  Printf.printf "square 4   = %f\n" (Math.square 4.0);
  Printf.printf "circle r=3 = %f\n" (Math.circle_area 3.0);
  Printf.printf "abs -5     = %d\n" (Math.abs (-5))

(*
  TRACE:

  Math.pi         -> 3.14159
  Math.square 4.0 -> 4.0 *. 4.0 = 16.0
  Math.circle_area 3.0
    -> pi *. square 3.0
    -> 3.14159 *. 9.0
    -> 28.27...

  NOTE:
  Inside the module, functions refer to each other by SHORT name:
      circle_area calls square directly (not Math.square)

  Outside the module, you use the full path:
      Math.square
      Math.circle_area
*)


(*
  =========================
  PART 3: TYPES INSIDE MODULES
  =========================

  Modules can contain TYPE DEFINITIONS too.
  This is very common -- group the type with the functions that use it.

  EXAMPLE: a module for a 2D point
*)

module Point = struct

  (* The type lives inside the module *)
  type t = {
    x : float;
    y : float;
  }

  (* Functions that work on the type *)
  let make x y = { x; y }

  let distance p1 p2 =
    let dx = p1.x -. p2.x in
    let dy = p1.y -. p2.y in
    sqrt (dx *. dx +. dy *. dy)

  let to_string p =
    Printf.sprintf "(%.2f, %.2f)" p.x p.y

end

(*
  USAGE:
*)

let () =
  let p1 = Point.make 0.0 0.0 in
  let p2 = Point.make 3.0 4.0 in
  Printf.printf "p1 = %s\n" (Point.to_string p1);
  Printf.printf "p2 = %s\n" (Point.to_string p2);
  Printf.printf "distance = %f\n" (Point.distance p1 p2)

(*
  TRACE:

  Point.make 0.0 0.0 -> { x = 0.0; y = 0.0 }
  Point.make 3.0 4.0 -> { x = 3.0; y = 4.0 }

  Point.distance p1 p2:
    dx = 3.0 - 0.0 = 3.0
    dy = 4.0 - 0.0 = 4.0
    sqrt(9.0 + 16.0) = sqrt(25.0) = 5.0

  NOTE: The type is Point.t
  The convention in OCaml is to call the MAIN TYPE of a module "t".
  So: Point.t, List.t would be the list type, etc.
  You will see this everywhere in real OCaml code.
*)


(*
  =========================
  PART 4: open -- BRINGING A MODULE INTO SCOPE
  =========================

  Writing the module prefix every time can get verbose.
  "open" brings everything from a module into the current scope.

  SYNTAX:
      open ModuleName

  BEFORE open:
*)

let area_before =
  Math.pi *. Math.square 5.0

(*
  AFTER open:
*)

let () =
  let open Math in
  let area = pi *. square 5.0 in
  Printf.printf "area = %f\n" area

(*
  WHAT HAPPENS:
  Inside the "let open Math in" block,
  you can write pi and square directly
  without the Math. prefix.

  Outside that block, you still need Math.pi.

  WHY USE LOCAL open INSTEAD OF GLOBAL?

  Global open (at the top of a file) is risky:
  - It might shadow names you already have
  - Hard to tell where a function comes from

  Local open (inside a let ... in block) is safer:
  - Only affects that one expression
  - Clear about where names come from

  REAL EXAMPLE: you already saw this style in the validator

      `Assoc [
        ("status", `String "ok");
        ...
      ]

  The backtick constructors are from Yojson.Safe.
  Opening it locally would let you write them without the backtick.

  ANOTHER SYNTAX: module alias

  If a module name is long, you can give it a short alias:
*)

module Y = Yojson.Safe

(*
  Now instead of Yojson.Safe.from_string
  you can write Y.from_string.

  This is exactly what you will do with ppx in Part 2.
*)


(*
  =========================
  PART 5: NESTED MODULES
  =========================

  Modules can contain other modules.
  This is why Yojson.Safe works -- Safe is a MODULE inside Yojson.

  EXAMPLE: a Validator module that contains sub-modules
*)

module Validator = struct

  module Errors = struct
    type t =
      | PiiFieldPresent      of { field_name : string }
      | RequiredFieldMissing of { field_name : string }
      | FieldTooLong         of { field_name : string; max_len : int; actual_len : int }

    let to_string err =
      match err with
      | PiiFieldPresent { field_name } ->
          Printf.sprintf "PII field '%s' must not be present" field_name
      | RequiredFieldMissing { field_name } ->
          Printf.sprintf "Required field '%s' is missing or empty" field_name
      | FieldTooLong { field_name; max_len; actual_len } ->
          Printf.sprintf "Field '%s' is too long: max %d, got %d"
            field_name max_len actual_len
  end

  module Checks = struct
    type payload = {
      user_id     : string;
      user_name   : string;
      query       : string;
      ssn         : string option;
      credit_card : string option;
    }

    let no_ssn p =
      match p.ssn with
      | None   -> Ok p
      | Some _ -> Error (Errors.PiiFieldPresent { field_name = "ssn" })

    let no_credit_card p =
      match p.credit_card with
      | None   -> Ok p
      | Some _ -> Error (Errors.PiiFieldPresent { field_name = "credit_card" })

    let query_not_empty p =
      if String.length p.query = 0
      then Error (Errors.RequiredFieldMissing { field_name = "query" })
      else Ok p
  end

  let run payload =
    match Checks.no_ssn payload with
    | Error e -> Error e
    | Ok p ->
      match Checks.no_credit_card p with
      | Error e -> Error e
      | Ok p ->
        Checks.query_not_empty p

end

(*
  USAGE:

  Notice how this is now organized and readable.
  Each sub-module has a clear job:
  - Validator.Errors contains all error types
  - Validator.Checks contains all check functions
  - Validator.run chains them together

  Types are accessed with their full path:
      Validator.Checks.payload
      Validator.Errors.t
*)

let () =
  let p : Validator.Checks.payload = {
    user_id     = "u_1";
    user_name   = "Alice";
    query       = "What is the weather?";
    ssn         = None;
    credit_card = None;
  } in
  match Validator.run p with
  | Ok _    -> print_endline "[u_1] PASSED"
  | Error e -> Printf.printf "[u_1] FAILED: %s\n" (Validator.Errors.to_string e)

(*
  COMPARE to the flat version in lesson 6/7:
  Everything was at the top level.
  Now it is organized into namespaces.
  Large codebases need this.
*)


(*
  =========================
  PART 6: HOW FILES BECOME MODULES
  =========================

  This is CRITICAL to understand.

  In real OCaml projects (compiled with Dune),
  EVERY .ml FILE is automatically a MODULE.

  If you have:

      validator.ml
      checks.ml
      errors.ml
      main.ml

  Then in main.ml you can write:

      Checks.no_ssn payload
      Errors.to_string e
      Validator.run payload

  WITHOUT any "module X = struct ... end" boilerplate.

  The file IS the module.
  The filename becomes the module name (capitalized).

  EXAMPLE:

  File: math.ml
  +--------------------------+
  | let pi = 3.14159         |
  | let square x = x *. x   |
  +--------------------------+

  File: main.ml
  +--------------------------+
  | let () =                 |
  |   Printf.printf "%f\n"   |
  |     Math.pi              |
  +--------------------------+

  main.ml can access Math.pi because
  math.ml compiled to the Math module automatically.

  THIS IS WHY your Yojson module exists:
  The yojson library has files like:
      yojson.ml    -> Yojson module
      safe.ml      -> Yojson.Safe sub-module

  And your code uses them via:
      Yojson.Safe.from_string

  KEY POINT:
  You do NOT need to write "module X = struct ... end"
  for files in a real project.
  Each file is already its own module.
  You only write "module X = struct" for INLINE modules
  (defined inside another file, like we did above).
*)


(*
  =========================
  PART 7: SIGNATURES -- CONTROLLING WHAT A MODULE EXPOSES
  =========================

  A module signature is like an INTERFACE.
  It declares WHAT is visible from outside the module.
  Anything not in the signature is PRIVATE.

  SYNTAX:

      module type SIGNATURE_NAME = sig
        val function_name : type
        type t
        ...
      end

  Then attach it:

      module ModuleName : SIGNATURE_NAME = struct
        ...
      end

  EXAMPLE:
*)

module type MATH_SIG = sig
  val pi        : float
  val square    : float -> float
  val circle_area : float -> float
  (* abs is NOT listed here -- it will be private *)
end

module SafeMath : MATH_SIG = struct
  let pi = 3.14159
  let square x = x *. x
  let circle_area r = pi *. square r
  let abs x = if x < 0 then -x else x  (* private -- not in sig *)
end

(*
  WHAT HAPPENS:

  SafeMath.pi          -> 3.14159   (public -- in sig)
  SafeMath.square 4.0  -> 16.0      (public -- in sig)
  SafeMath.abs (-5)    -> COMPILE ERROR  (private -- not in sig)

  WHY THIS MATTERS:

  In a large codebase, you do not want users calling internal
  helper functions they should not depend on.

  The signature says:
  "These are the ONLY things you should use from this module."
  Everything else is an implementation detail.

  This is exactly like a public/private interface in Java or Python.
  But in OCaml it is enforced by the TYPE CHECKER at compile time.
*)

let () =
  Printf.printf "SafeMath.pi = %f\n" SafeMath.pi;
  Printf.printf "SafeMath.circle_area 5.0 = %f\n" (SafeMath.circle_area 5.0)
  (* SafeMath.abs (-5) would be a COMPILE ERROR here *)


(*
  =========================
  PART 8: WHY THIS ALL MATTERS FOR YOUR VALIDATOR
  =========================

  Right now your validator is ONE FILE with everything flat:

      type payload = { ... }
      type validation_error = | ...
      let parse_string_field ...
      let parse_optional_string_field ...
      let parse_payload ...
      let check_no_ssn ...
      ...

  With modules, you would split it:

  +------------------+    +------------------+    +------------------+
  | payload.ml       |    | checks.ml        |    | validator.ml     |
  |                  |    |                  |    |                  |
  | type t = {       |    | open Payload     |    | let run p =      |
  |   user_id : str  |    |                  |    |   Checks.no_ssn p|
  |   ...            |    | let no_ssn p =   |    |   ...            |
  | }                |    |   ...            |    |                  |
  +------------------+    +------------------+    +------------------+

  Each file has ONE job.
  Each file is automatically a module.
  Changes to one file do not break others (signature protects them).

  For now (single file validator) you do not NEED this.
  But when you add more field types, more checks, more rules --
  you will want to split it.
*)


(*
  ===================================================
  PART 9: PPX AND PPX_DERIVING_YOJSON
  ===================================================

  PPX STANDS FOR:
  PreProcessor eXtension

  WHAT IT DOES:
  PPX is a code generation tool.
  You write an ANNOTATION on your type,
  and ppx AUTOMATICALLY GENERATES functions for that type.

  WHY THIS MATTERS FOR YOUR VALIDATOR:

  Look at how much code you wrote in lesson 7
  just to parse ONE payload type from JSON:

      let parse_string_field key fields = ...
      let parse_optional_string_field key fields = ...
      let parse_payload json_str =
        match json with
        | Ok (`Assoc fields) ->
            (match parse_string_field "user_id" fields with
            | Error e -> Error e
            | Ok user_id ->
              match parse_string_field "user_name" fields with
              ...  <- 30+ more lines

  That was ~40 lines for ONE type with 5 fields.
  If your payload had 20 fields, that would be 160 lines.
  And you would have to UPDATE them every time you add a field.

  WITH PPX_DERIVING_YOJSON:
  You write this:

      type payload = {
        user_id     : string;
        user_name   : string;
        query       : string;
        ssn         : string option;
        credit_card : string option;
      } [@@deriving yojson]

  That [@@deriving yojson] annotation tells ppx to
  AUTOMATICALLY GENERATE:

      payload_of_yojson : Yojson.Safe.t -> (payload, string) result
      payload_to_yojson : payload -> Yojson.Safe.t

  BOTH functions. For free. For ANY type you annotate.
  Add a field? ppx updates the functions automatically.

  THE [@@deriving yojson] ANNOTATION:
  @@  means "attribute on this type definition"
  deriving is the ppx tool name
  yojson is what to derive (JSON functions)

  Other things you can derive:
      [@@deriving show]    -> auto-generates a to_string function
      [@@deriving eq]      -> auto-generates an equality function
      [@@deriving ord]     -> auto-generates a comparison function
      [@@deriving yojson]  -> auto-generates JSON functions

  You can combine them:
      [@@deriving yojson, show, eq]
*)


(*
  =========================
  PART 10: WHAT PPX GENERATES
  =========================

  When you write:

      type payload = {
        user_id  : string;
        query    : string;
        ssn      : string option;
      } [@@deriving yojson]

  PPX generates ROUGHLY this (you never write it):

      let payload_of_yojson json =
        match json with
        | `Assoc fields ->
            (match List.assoc_opt "user_id" fields with
            | Some (`String user_id) ->
              (match List.assoc_opt "query" fields with
              | Some (`String query) ->
                (match List.assoc_opt "ssn" fields with
                | None | Some `Null -> Ok { user_id; query; ssn = None }
                | Some (`String s)  -> Ok { user_id; query; ssn = Some s }
                | Some _            -> Error "ssn: expected string or null")
              | _ -> Error "query: missing or wrong type")
            | _ -> Error "user_id: missing or wrong type")
        | _ -> Error "expected JSON object"

      let payload_to_yojson p =
        `Assoc [
          ("user_id", `String p.user_id);
          ("query",   `String p.query);
          ("ssn",     match p.ssn with
                      | None   -> `Null
                      | Some s -> `String s);
        ]

  This is EXACTLY what you wrote by hand in lesson 7.
  PPX writes it for you.

  WHAT PPX HANDLES AUTOMATICALLY:

  string          -> `String s
  int             -> `Int n
  float           -> `Float f
  bool            -> `Bool b
  string option   -> `String s | `Null
  string list     -> `List [`String ...]
  nested records  -> `Assoc [...] (recursively)

  If your type composes these, ppx handles it all.
*)


(*
  =========================
  PART 11: THE VALIDATOR -- BEFORE AND AFTER PPX
  =========================

  BEFORE ppx (lesson 7 -- what you wrote):

  +---------------------------------------------------------+
  | ~80 lines for parsing alone                             |
  |                                                         |
  | let parse_string_field key fields = ...       (8 lines) |
  | let parse_optional_string_field key fields    (9 lines) |
  | let parse_payload json_str =                            |
  |   match json with                                       |
  |   | Ok (`Assoc fields) ->                               |
  |       (match parse_string_field "user_id" ...           |
  |       | Error e -> Error e                              |
  |       | Ok user_id ->                                   |
  |         match parse_string_field "user_name" ...        |
  |         ...  (30+ more lines of chained matches)        |
  +---------------------------------------------------------+

  AFTER ppx (this lesson):

  +---------------------------------------------------------+
  | ~5 lines for parsing                                    |
  |                                                         |
  | type payload = {                                        |
  |   user_id     : string;                                 |
  |   user_name   : string;                                 |
  |   query       : string;                                 |
  |   ssn         : string option;                          |
  |   credit_card : string option;                          |
  | } [@@deriving yojson]                                   |
  |                                                         |
  | (* Done. payload_of_yojson is now available. *)         |
  +---------------------------------------------------------+

  The validation logic (check_no_ssn, check_no_credit_card etc.)
  does NOT change. Only the parsing boilerplate disappears.
*)


(*
  =========================
  PART 12: COMPLETE VALIDATOR REWRITTEN WITH PPX
  =========================

  This is the FULL validator from lesson 7,
  rewritten using ppx_deriving_yojson.

  Compare line counts:
  Lesson 7 validator: ~130 lines
  This version:       ~60 lines

  The logic is IDENTICAL.
  Only the parsing boilerplate is gone.

  NOTE: This requires ppx_deriving_yojson to be installed.
  See the Colab cell in the notebook version of this lesson.
*)

(*
  STEP 1: Define the type WITH the annotation.
  ppx sees [@@deriving yojson] and generates
  payload_of_yojson and payload_to_yojson automatically.
*)

type payload = {
  user_id     : string;
  user_name   : string;
  query       : string;
  ssn         : string option;  (* option -> handles null/missing *)
  credit_card : string option;
} [@@deriving yojson]

(*
  WHAT IS NOW AVAILABLE FOR FREE:

  payload_of_yojson : Yojson.Safe.t -> (payload, string) result
    - takes a parsed Yojson value
    - returns Ok payload or Error message
    - handles all field types, options, missing fields

  payload_to_yojson : payload -> Yojson.Safe.t
    - takes a payload record
    - returns a Yojson value
    - handles None -> null, Some s -> string
*)


(*
  STEP 2: Validation errors -- also derived.
  [@@deriving yojson] works on variants too.
*)

type validation_error =
  | PiiFieldPresent      of { field_name : string }
  | RequiredFieldMissing of { field_name : string }
  | FieldTooLong         of { field_name : string; max_len : int; actual_len : int }


(*
  STEP 3: Parsing -- now 4 lines instead of 40.

  BEFORE:
      let parse_payload json_str =
        let json = try Ok (Yojson.Safe.from_string ...) ... in
        match json with
        | Ok (`Assoc fields) ->
            (match parse_string_field "user_id" fields with
            ...  <- 30 more lines

  AFTER:
*)

let parse_payload json_str =
  try
    let json = Yojson.Safe.from_string json_str in
    match payload_of_yojson json with
    | Ok p    -> Ok p
    | Error e -> Error ("parse error: " ^ e)
  with _ -> Error "parse error: invalid JSON"

(*
  TRACE:

  Input: {"user_id":"u_1","user_name":"Alice","query":"hi","ssn":null,"credit_card":null}

  Step 1: Yojson.Safe.from_string -> `Assoc [...]
  Step 2: payload_of_yojson (`Assoc [...])
          -> ppx-generated function runs
          -> extracts each field by name
          -> handles ssn: null -> None
          -> handles credit_card: missing -> None
          -> returns Ok { user_id="u_1"; ... }
  Step 3: we return Ok p

  If "user_id" is missing:
  Step 2: payload_of_yojson returns Error "user_id: missing"
  Step 3: we return Error "parse error: user_id: missing"

  Much less code. Same result.
*)


(*
  STEP 4: Validators -- UNCHANGED from lesson 6/7.
  ppx only changes the parsing layer.
  The validation logic stays exactly the same.
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


(*
  STEP 5: JSON output -- also simplified by ppx.

  BEFORE (lesson 7):
      let payload_to_json p =
        `Assoc [
          ("user_id",     `String p.user_id);
          ("user_name",   `String p.user_name);
          ("query",       `String p.query);
          ("ssn",         match p.ssn with None -> `Null | Some s -> `String s);
          ("credit_card", match p.credit_card with None -> `Null | Some s -> `String s);
        ]

  AFTER: ppx generated payload_to_yojson for us already.
  We just use it:
*)

let make_ok_response p =
  `Assoc [
    ("status",  `String "ok");
    ("payload", payload_to_yojson p);  (* ppx-generated *)
  ]

let make_error_response msg =
  `Assoc [
    ("status",  `String "error");
    ("message", `String msg);
  ]


(*
  STEP 6: Entry point -- UNCHANGED.
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
      print_string (Yojson.Safe.to_string (make_error_response e));
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
  KEY TAKEAWAYS
  =========================

  MODULES:
  - A module is a named collection of types, values, and functions
  - ModuleName.thing is how you access items inside
  - You define them with: module Name = struct ... end
  - Every .ml FILE is automatically a module in a real project
  - open ModuleName brings names into scope (use locally, not globally)
  - Signatures (module type) control what is public vs private
  - Nested modules: module Yojson.Safe -- Safe is inside Yojson

  FILES AS MODULES (real projects):
  - math.ml   -> Math module, use as Math.pi etc.
  - checks.ml -> Checks module, use as Checks.no_ssn etc.
  - No "module X = struct" needed -- the file IS the module
  - This is how you split a large program into organized pieces

  PPX:
  - PreProcessor eXtension -- code generation via annotations
  - [@@deriving yojson] on a type generates from_yojson and to_yojson
  - [@@deriving show] generates a to_string printer
  - [@@deriving eq] generates an equality function
  - Handles string, int, bool, option, list, nested records automatically
  - Saves ~40 lines of boilerplate per type
  - Keeps parsing code in sync with your type automatically

  PPX_DERIVING_YOJSON SPECIFICALLY:
  - type t = { ... } [@@deriving yojson]
  - Generates: t_of_yojson  : Yojson.Safe.t -> (t, string) result
  - Generates: t_to_yojson  : t -> Yojson.Safe.t
  - string option -> handles null/missing automatically
  - Any type composition of primitives: handled automatically

  BEFORE vs AFTER:
  - Lesson 7 parser: ~40 lines of hand-written chained matches
  - Lesson 8 parser: 4 lines + [@@deriving yojson] annotation
  - Validation logic: UNCHANGED (ppx only affects parsing/serialization)

  WHAT YOU NOW HAVE:
  A clean, maintainable validator where:
  - Adding a new field = add it to the record type
  - ppx re-generates the parser automatically
  - Validators catch the new field automatically
  - No manual JSON field extraction ever again
*)
