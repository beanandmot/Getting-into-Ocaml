(*
  LESSON 1: Values, Types, and Comments in OCaml

  OCaml is a functional programming language.
  That means:
  - We mostly define values, not changing variables
  - Everything evaluates to a result (an expression)

  This file teaches:
  - How values work
  - Basic types
  - How to write comments (IMPORTANT)
*)

(*
  =========================
  COMMENTS IN OCAML
  =========================

  OCaml uses this format for comments:

      (* comment here *)

  This works for:
  - Single-line comments
  - Multi-line comments
*)

(* This is a single-line comment *)

(*
  This is a multi-line comment.
  You can write as much as you want here.
*)

(*
  NOTE:
  OCaml does NOT use // or # like other languages.
*)

(*
  =========================
  VALUES
  =========================

  We define values using: let
*)

let x = 5

(*
  Here:
  - x is the name
  - 5 is the value
*)

let message = "Hello, OCaml!"
let is_ready = true
let pi = 3.14

(*
  Types:
  - int     → whole numbers (5, 10, -3)
  - float   → decimals (3.14, 2.0)
  - string  → text ("hello")
  - bool    → true or false
*)

(*
  =========================
  TYPE INFERENCE
  =========================

  OCaml automatically figures out types.
*)

let a = 10        (* OCaml knows: int *)
let b = 3.5       (* OCaml knows: float *)
let c = "hi"      (* string *)
let d = false     (* bool *)

(*
  WHY does this work?

  Because OCaml analyzes how values are used
  and deduces the only type that makes sense.

  Example:
*)

let add_one n = n + 1

(*
  OCaml thinks:

  + only works on ints
  → so n must be int
  → result must be int

  So it infers:
  add_one : int -> int

  This is called "type inference".
*)

(*
  ⚠️ When would you write types manually?

  When things get more complex:

  let add (a : int) (b : int) : int = a + b 
  (These a and b are the placeplaceholder values in the add function we just made.
  
  For example, these are some equivatelents in other languages =>

  Python equivalent:

  def add(a, b):
      return a + b
  result = add(2, 3)
  print(result)

  C++ equivalent:

  int add(int a, int b) {
      return a + b;
  }
  int result = add(2, 3);
  std::cout << result << std::endl;

  Go equivalent:

  func add(a int, b int) int {
      return a + b
  }
  result := add(2, 3)
  fmt.Println(result)
  
  
  )

  But for now:
  → you usually DON'T need to write types
*)

(*
  =========================
  OPERATIONS
  =========================
*)

let int_sum = 2 + 3

(*
  IMPORTANT:
  Floats use DIFFERENT operators
*)

let float_sum = 2.0 +. 3.0

(*
  Why +. ?

  OCaml separates int and float operations completely.

  +   → int addition
  +.  → float addition

  This avoids automatic conversions and bugs.
*)

(*
  More examples:
*)

let int_example = 10 + 5
let float_example = 10.0 +. 5.0

(*
  Other operators:
  
  int:    +   -   *   /
  float:  +.  -.  *.  /.
*)

let float_mult = 2.0 *. 4.0   (* ✅ this works *)

(*
  This will FAIL:
  2 + 3.0   ❌ (cannot mix int and float)
*)

(*
  To fix it, convert types:
*)

let fixed = float_of_int 2 +. 3.0

(*
  =========================
  PRINTING
  =========================
*)

let () =
  print_endline message;

  (* %d = integer *)
  Printf.printf "x = %d\n" x;

  (* %f = float *)
  Printf.printf "pi = %f\n" pi;

  (* %b = boolean *)
  Printf.printf "is_ready = %b\n" is_ready;

  (* show float addition result *)
  Printf.printf "2.0 +. 3.0 = %f\n" float_sum
