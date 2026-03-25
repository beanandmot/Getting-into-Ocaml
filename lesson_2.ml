(*
  LESSON 2: Functions, Expressions, Immutability, and Memory

  This lesson goes deeper into how OCaml actually works.

  Topics:
  - Functions (curried vs tuple)
  - Expressions (everything returns a value)
  - Immutability
  - Shadowing (VERY IMPORTANT)
  - Memory model (RAM vs CPU)
  - Modulus operator (mod)
*)

(*
  =========================
  FUNCTIONS
  =========================

  Functions are defined using "let"
*)

let add a b = a + b

(*
  Type (inferred):
  add : int -> int -> int

  This means:
  - takes an int
  - returns a function that takes an int
  - returns an int

  This is called CURRYING.

  Internally, this is closer to:

      let add a =
        fun b -> a + b
*)

(*
  Example usage:
*)

let result = add 2 3

(*
  IMPORTANT:
  OCaml does NOT require parentheses for function calls.

      add 2 3     (* correct *)
      add(2,3)    (* this is tuple style, different meaning *)
*)

(*
  =========================
  EXPRESSIONS (CRITICAL CONCEPT)
  =========================

  In OCaml:
  EVERYTHING is an expression.

  That means:
  - It ALWAYS returns a value
  - There are NO "statements" like in Python/C++
*)

(*
  Example:
*)

let x =
  if true then 10 else 20

(*
  This evaluates to:
  x = 10

  The "if" expression RETURNS a value.

  Compare with Python:

      if condition:
          x = 10
      else:
          x = 20

  In OCaml, the if itself produces the value.
*)

(*
  Example function:
*)

let max a b =
  if a > b then a else b

(*
  Execution:

      max 5 3
      → 5 > 3 = true
      → return a (5)

      max 2 7
      → 2 > 7 = false
      → return b (7)

  The if expression returns either "a" or "b"
*)

(*
  =========================
  IMMUTABILITY
  =========================

  Values in OCaml do NOT change after creation.
*)

let value = 10

(*
  This is NOT allowed:

      value = 20   ❌

  Because OCaml does not mutate values.
*)

(*
  Instead:
*)

let value = 20

(*
  This creates a NEW value.

  This leads to the concept of SHADOWING.
*)

(*
  =========================
  SHADOWING (DETAILED)
  =========================

  Shadowing means:
  A new variable with the SAME NAME replaces the old one.

      let value = 10
      let value = 20

  This does NOT modify 10 → 20.

  Instead:

      Step 1:
        value → 10  (stored in memory)

      Step 2:
        value → 20  (new binding)

  The old value (10) is now inaccessible.
*)

(*
  MEMORY EXPLANATION:

  - Values are stored in RAM (not CPU)
  - The CPU executes operations on those values

  Step-by-step:

      let value = 10
      → allocate memory for 10 in RAM
      → bind name "value" to that memory

      let value = 20
      → allocate NEW memory for 20
      → bind NEW "value" to new location

      old 10 is now unused

  OCaml uses GARBAGE COLLECTION:
  - unused values are cleaned up automatically
*)

(*
  WHY SHADOWING EXISTS:

  1. Immutability
     → values never change

  2. Safer code
     → no accidental modification

  3. Easier reasoning
     → each value is fixed

  4. Compiler optimizations
*)

(*
  WHEN TO USE SHADOWING:

  Good:
      let x = 10
      let x = x + 5   (* x = 15 *)

  Avoid:
      Too many reuses of same name (confusing)
*)

(*
  COMPARISON:

  Python (mutable):
      x = 10
      x = 20   # overwrites

  C++:
      int x = 10;
      x = 20;  // mutation

  OCaml:
      let x = 10
      let x = 20   (* new binding *)
*)

(*
  =========================
  BINDINGS (VERY IMPORTANT)
  =========================

  A "binding" means:

      name → value

  When you write:

      let x = 10

  You are NOT creating a "variable" like in Python/C++.

  You are creating a binding:
      x → 10

  This binding connects the NAME "x"
  to a VALUE stored in memory.
*)

(*
  =========================
  SHADOWING + BINDINGS (DEEP DIVE)
  =========================

  Example:
*)

let x = 10

let x = x + 5

(*
  This confuses many people.

  Step-by-step:

  Step 1:
      let x = 10
      → binding: x → 10

  Step 2:
      let x = x + 5

      IMPORTANT:
      The RIGHT SIDE uses the OLD x

      So:
          x + 5 = 10 + 5 = 15

      Then:
          create NEW binding: x → 15

  The OLD binding (x → 10) is NOT changed.
  It is simply no longer accessible.

  This is called SHADOWING.
*)

(*
  Let's prove this with values:
*)

let original = 10
let updated = original + 5

(*
  Here:
      original → 10
      updated  → 15

  No mutation happens.
*)

(*
  =========================
  MEMORY MODEL (CLEAR EXPLANATION)
  =========================

  Think of memory (RAM) like storage:

      Address A → 10
      Address B → 15

  Bindings:

      x → Address A   (first binding)
      x → Address B   (second binding)

  The second "x" does NOT overwrite memory.
  It just points to a NEW location.

  The old memory may later be cleaned up
  by the Garbage Collector (GC).
*)

(*
  =========================
  ACCESSING VALUES
  =========================

  You always access the MOST RECENT binding.
*)

let y = 5
let y = y + 2
let y = y * 3

(*
  Step-by-step:

      y = 5
      y = 5 + 2 = 7
      y = 7 * 3 = 21

  Final:
      y = 21
*)

(*
  =========================
  COMPARISON WITH OTHER LANGUAGES
  =========================

  Python:

      x = 10
      x = x + 5

  → mutation (same variable changes)

  OCaml:

      let x = 10
      let x = x + 5

  → new binding (old value unchanged)

  C++:

      int x = 10;
      x = x + 5;

  → mutation
*)

(*
  =========================
  CURRIED FUNCTIONS (RUNNABLE)
  =========================
*)

let add_curried a b = a + b

(*
  Normal usage:
*)

let c1 = add_curried 3 4   (* 7 *)

(*
  PARTIAL APPLICATION:

  This is VERY important.

  When you do:
*)

let add3 = add_curried 3

(*
  What is add3?

  It is a FUNCTION:

      add3 b = 3 + b

  So:
*)

let c2 = add3 10   (* 13 *)

(*
  Explanation:

      add_curried 3
      → returns a function: fun b -> 3 + b

  This is why OCaml is powerful:
  functions can return functions.
*)


(* A MORE CLEAR EXAMPLE *)


(*
  =========================
  CAN WE ACCESS OLD BINDINGS?
  =========================

  Short answer:

      NO — once a binding is shadowed, the old one is not accessible anymore.

  Example:
*)

let x = 10
let x = x + 5   (* x = 15 *)

(*
  At this point:
      x = 15

  The old x (10) is NOT accessible anymore.
*)

let () =
  Printf.printf "Current x = %d\n" x

(*
  Output:
      Current x = 15

  There is NO way to get the old 10 from "x" now.
*)

(*
  =========================
  HOW TO PRESERVE OLD VALUES
  =========================

  If you WANT to keep old values,
  you must store them explicitly.
*)

let original = 10
let updated1 = original + 5
let updated2 = updated1 * 2

let () =
  Printf.printf "original = %d\n" original;
  Printf.printf "updated1 = %d\n" updated1;
  Printf.printf "updated2 = %d\n" updated2

(*
  Output:
      original = 10
      updated1 = 15
      updated2 = 30

  Here we kept ALL versions.
*)

(*
  =========================
  MULTIPLE "VERSIONS" USING NEW NAMES
  =========================

  This is the safest and most common approach.
*)

let v1 = 3
let v2 = v1 + 2
let v3 = v2 * 4

let () =
  Printf.printf "v1 = %d\n" v1;
  Printf.printf "v2 = %d\n" v2;
  Printf.printf "v3 = %d\n" v3

(*
  Output:
      v1 = 3
      v2 = 5
      v3 = 20
*)

(*
  =========================
  USING LISTS TO STORE HISTORY
  =========================

  If you want ALL previous values,
  you can store them in a list.
*)

let history = [3; 5; 20]

let () =
  Printf.printf "First value = %d\n" (List.nth history 0);
  Printf.printf "Second value = %d\n" (List.nth history 1);
  Printf.printf "Third value = %d\n" (List.nth history 2)

(*
  Output:
      First value = 3
      Second value = 5
      Third value = 20

  This is how you "track versions" manually.
*)

(*
  =========================
  USING TUPLES TO STORE VERSIONS
  =========================
*)

let versions = (3, 5, 20)

let (a, b, c) = versions

let () =
  Printf.printf "Tuple values: %d %d %d\n" a b c

(*
  =========================
  SCOPE-BASED ACCESS (IMPORTANT)
  =========================

  Sometimes, you CAN access old bindings
  using nested scopes.
*)

let x = 10

let result =
  let x = x + 5 in   (* inner x = 15 *)
  let x = x * 2 in   (* inner x = 30 *)
  x

let () =
  Printf.printf "Outer x = %d\n" x;
  Printf.printf "Result = %d\n" result

(*
  Output:
      Outer x = 10
      Result = 30

  Explanation:

  Outer x = 10 stays unchanged.

  Inner scope creates NEW bindings:
      x = 15
      x = 30

  These do NOT affect the outer x.
*)

(*
  =========================
  KEY TAKEAWAY
  =========================

  - Shadowing hides old bindings
  - Old values are NOT deleted immediately,
    but you cannot access them anymore
  - If you need them → store them explicitly

  Think:

      OCaml does NOT keep "history" for you
      YOU must keep history if needed
*)

(*
  =========================
  COMPARISON WITH OTHER LANGUAGES
  =========================

  Python:

      x = 10
      x = 15

  → old value lost (unless saved manually)

  OCaml:

      let x = 10
      let x = 15

  → same idea, but implemented via new bindings

  The difference is conceptual:
      OCaml NEVER mutates values
      It always creates new ones
*)


(*
  =========================
  MODULUS OPERATOR (mod)
  =========================

  Syntax:

      a mod b

  Returns the remainder of division.
*)

let example1 = 10 mod 2   (* 0 *)
let example2 = 7 mod 2    (* 1 *)

(*
  Explanation:

      7 ÷ 2 = 3 remainder 1

  Internally:

      a mod b = a - (b * (a / b))

      7 mod 2
      = 7 - (2 * 3)
      = 1
*)

(*
  PERFORMANCE:

  - Constant time (O(1))
  - Uses CPU arithmetic instructions
  - No extra memory allocation
*)

(*
  Practical use:
*)

let is_even n = n mod 2 = 0

(*
  =========================
  TUPLES (DEEP EXPLANATION)
  =========================

  A tuple is a fixed-size group of values.
*)

let pair = (3, 4)

(*
  Memory layout:

      [tuple]
        ├── 3
        └── 4

  Stored as a block in RAM.
*)

(*
  Function using tuple:
*)

let add_pair (a, b) = a + b

let result2 = add_pair (3, 4)

(*
  What happens:

  1. (3,4) is created in memory
  2. Passed into function
  3. Pattern matched:
        a = 3
        b = 4
  4. Returns 7
*)

(*
  =========================
  CURRIED vs TUPLE FUNCTIONS
  =========================

  Curried:
*)

let add_curried a b = a + b

(*
  Tuple:
*)

let add_tuple (a, b) = a + b

(*
  DIFFERENCE:

  Curried:
      add_curried 3 4
      supports partial application:
      let add3 = add_curried 3

  Tuple:
      add_tuple (3,4)
      requires both values at once
*)

(*
  WHEN TO USE:

  Curried:
      - more flexible
      - functional programming style

  Tuple:
      - when values belong together
*)

(*
  =========================
  TUPLE FUNCTIONS (RUNNABLE)
  =========================
*)

let add_tuple (a, b) = a + b

let t1 = add_tuple (3, 4)   (* 7 *)

(*
  IMPORTANT DIFFERENCE:

  This does NOT work:

      add_tuple 3   ❌

  Because it expects BOTH values at once.
*)

(*
  =========================
  CURRIED vs TUPLE (CLEAR DIFFERENCE)
  =========================

  Curried:
      let add a b = a + b

      add 3 4
      let add3 = add 3   (* works *)

  Tuple:
      let add (a,b) = a + b

      add (3,4)
      let add3 = add 3   ❌ (not possible)

  WHY?

  Curried:
      takes ONE argument at a time

  Tuple:
      takes BOTH arguments together
*)

(*
  =========================
  WHEN TO USE EACH
  =========================

  Curried (most common):
      - functional programming
      - reusable functions
      - partial application

  Tuple:
      - when values belong together
      - pattern matching
*)


(*
  =========================
  STRING OPERATIONS
  =========================
*)

let greet name = "Hello, " ^ name

(*
  ^ is string concatenation

  Example:
      greet "OCaml"
      → "Hello, OCaml"
*)

(*
  =========================
  PRINTING
  =========================
*)

let () =
  Printf.printf "max 5 3 = %d\n" (max 5 3);
  Printf.printf "is_even 10 = %b\n" (is_even 10);
  Printf.printf "add_pair (3,4) = %d\n" (add_pair (3,4));
  print_endline (greet "OCaml")



(*
  =========================
  MEMORY + GARBAGE COLLECTION DEMO
  =========================

  This section demonstrates:

  - When values stay in memory
  - When values become unreachable
  - How bindings affect memory

  NOTE:
  We cannot directly "see" memory in OCaml,
  but we can understand behavior through examples.
*)

(*
  Example 1: Shadowing (old value becomes unreachable)
*)

let demo_shadowing () =
  let x = 10 in
  let x = x + 5 in
  Printf.printf "Final x = %d\n" x

(*
  What happens:

  Step 1:
      x → 10

  Step 2:
      x → 15 (new binding)

  The old 10 is no longer referenced
  → eligible for garbage collection
*)

(*
  Example 2: Keeping all values (memory grows)
*)

let demo_keep_values () =
  let v1 = 10 in
  let v2 = v1 + 5 in
  let v3 = v2 + 10 in

  Printf.printf "v1 = %d\n" v1;
  Printf.printf "v2 = %d\n" v2;
  Printf.printf "v3 = %d\n" v3

(*
  Here:
      v1 → 10
      v2 → 15
      v3 → 25

  ALL values are still referenced,
  so none can be garbage collected.
*)

(*
  Example 3: Temporary values (cleaned up quickly)
*)

let demo_temporary () =
  let result =
    let x = 10 in
    let x = x + 5 in
    let x = x * 2 in
    x
  in
  Printf.printf "Result = %d\n" result

(*
  What happens:

      x = 10   (temporary)
      x = 15   (temporary)
      x = 30   (final)

  Only 30 survives after the block ends.

  The intermediate values are no longer referenced
  → cleaned by GC
*)

(*
  Example 4: Multiple bindings with same name
*)

let demo_chain () =
  let x = 2 in
  let x = x + 3 in
  let x = x * 4 in
  Printf.printf "Final x = %d\n" x

(*
  Step-by-step:

      x = 2
      x = 5
      x = 20

  Only the final binding is accessible.
*)

(*
  Example 5: Shared values (no extra allocation)
*)

let demo_shared () =
  let a = 42 in
  let b = a in

  Printf.printf "a = %d, b = %d\n" a b

(*
  Important:

  a and b BOTH point to the SAME value.

  No new memory is allocated for b.
*)

(*
  =========================
  RUN ALL DEMOS
  =========================
*)

let () =
  print_endline "---- Shadowing Demo ----";
  demo_shadowing ();

  print_endline "\n---- Keep Values Demo ----";
  demo_keep_values ();

  print_endline "\n---- Temporary Values Demo ----";
  demo_temporary ();

  print_endline "\n---- Chain Shadowing Demo ----";
  demo_chain ();

  print_endline "\n---- Shared Values Demo ----";
  demo_shared ()



(*
  =========================
  SCOPE (IMPORTANT CONCEPT)
  =========================

  Scope determines WHERE a binding is visible.

  Example:
*)

let x = 10

let result =
  let x = 20 in   (* inner scope *)
  x

let () =
  Printf.printf "Outer x = %d\n" x;
  Printf.printf "Inner result = %d\n" result

(*
  Output:
      Outer x = 10
      Inner result = 20

  The inner "x" only exists inside its scope.
*)
