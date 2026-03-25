(*
  LESSON 3: Pattern Matching, Recursion, and Lists

  This lesson is where OCaml becomes truly powerful.

  Topics:
  - Pattern matching (CORE FEATURE)
  - Recursion (replaces loops)
  - Lists (linked structure)
  - Combining all three

  This is the foundation of real functional programming.
*)

(*
  =========================
  PATTERN MATCHING (CORE)
  =========================

  Pattern matching lets you "deconstruct" values.

  Think of it like:
      "If the value looks like THIS → do THIS"

  Syntax:

      match value with
      | pattern1 -> result1
      | pattern2 -> result2
      | _ -> default
*)

(*
  SIMPLE EXAMPLE
*)

let describe_number n =
  match n with
  | 0 -> "zero"
  | 1 -> "one"
  | _ -> "many"

let () =
  print_endline (describe_number 0);
  print_endline (describe_number 1);
  print_endline (describe_number 5)

(*
  Explanation:

  describe_number 5:

      match 5 with
      | 0 -> no
      | 1 -> no
      | _ -> yes → "many"

  "_" means:
      "match anything"
*)

(*
  =========================
  WHY PATTERN MATCHING MATTERS
  =========================

  It replaces:
  - if/else chains
  - switch statements

  But more importantly:

  It lets you "extract structure"
*)

(*
  =========================
  MATCHING TUPLES
  =========================
*)

let describe_pair (a, b) =
  match (a, b) with
  | (0, 0) -> "both zero"
  | (0, _) -> "first is zero"
  | (_, 0) -> "second is zero"
  | _ -> "no zeros"

let () =
  print_endline (describe_pair (0, 0));
  print_endline (describe_pair (0, 5));
  print_endline (describe_pair (3, 0));
  print_endline (describe_pair (3, 4))

(*
  KEY IDEA:

  Pattern matching is not just checking,
  it's also BINDING values.

  Example:
*)

let sum_pair pair =
  match pair with
  | (a, b) -> a + b

(*
  (a, b) extracts values from the tuple
*)

(*
  =========================
  PATTERN MATCHING + BINDING (DETAILED)
  =========================

  Example:

      let sum_pair pair =
        match pair with
        | (a, b) -> a + b

  This looks simple, but a LOT is happening.

  We will break it down step-by-step.
*)

(*
  VERSION 1: Basic integer tuple
*)

let sum_pair pair =
  match pair with
  | (a, b) ->
      Printf.printf "Binding: a = %d, b = %d\n" a b;
      let result = a + b in
      Printf.printf "Computed result: %d\n" result;
      result

let () =
  Printf.printf "\n--- sum_pair (int * int) ---\n";
  let result = sum_pair (3, 4) in
  Printf.printf "Final returned value: %d\n" result

(*
  WHAT HAPPENS:

  Input:
      (3, 4)

  Pattern:
      (a, b)

  Binding:
      a = 3
      b = 4

  Then:
      result = 3 + 4 = 7

  RETURN:
      7
*)

(*
  =========================
  KEY INSIGHT: PATTERN MATCHING = DESTRUCTURING
  =========================

  The tuple is "taken apart" into pieces.

  (a, b) is NOT creating a tuple,
  it is EXTRACTING values from one.
*)

(*
  VERSION 2: Tuple with strings
*)

let describe_person person =
  match person with
  | (name, age) ->
      Printf.printf "Binding: name = %s, age = %d\n" name age;
      name ^ " is " ^ string_of_int age ^ " years old"

let () =
  Printf.printf "\n--- describe_person (string * int) ---\n";
  let msg = describe_person ("Alice", 25) in
  print_endline msg

(*
  Input:
      ("Alice", 25)

  Binding:
      name = "Alice"
      age  = 25

  Output:
      "Alice is 25 years old"
*)

(*
  =========================
  VERSION 3: MULTIPLE PATTERNS
  =========================

  Pattern matching can also check specific values.
*)

let classify_pair pair =
  match pair with
  | (0, 0) ->
      print_endline "Both are zero";
      "zero-zero"

  | (0, y) ->
      Printf.printf "First is zero, second = %d\n" y;
      "first-zero"

  | (x, 0) ->
      Printf.printf "Second is zero, first = %d\n" x;
      "second-zero"

  | (x, y) ->
      Printf.printf "General case: x = %d, y = %d\n" x y;
      "general"

let () =
  Printf.printf "\n--- classify_pair ---\n";
  ignore (classify_pair (0,0));
  ignore (classify_pair (0,5));
  ignore (classify_pair (7,0));
  ignore (classify_pair (3,4))

(*
  IMPORTANT:

  Patterns are checked TOP → DOWN

  First match wins.

  So order matters.
*)

(*
  =========================
  MEMORY + BINDING EXPLANATION
  =========================

  When you pass:

      (3, 4)

  Memory (conceptually):

      [tuple block]
        ├── 3
        └── 4

  Pattern matching does NOT create new values.

  Instead:

      a → points to 3
      b → points to 4

  So:

  - No copying
  - Just new bindings (names → existing values)
*)

(*
  =========================
  COMPARISON WITH OTHER LANGUAGES
  =========================

  Python:

      a, b = (3, 4)

  C++ (structured bindings):

      auto [a, b] = pair;

  OCaml:

      match pair with
      | (a, b) -> ...

  Difference:

  OCaml does this inside expressions
  and integrates it into control flow.
*)

(*
  =========================
  KEEP IN MIND, PATTERN MATCHING IS NOT JUST TUPLES
  =========================

  Pattern matching works on MANY structures:

  - integers
  - booleans
  - strings
  - lists
  - tuples
  - (later: custom types)

  It is NOT specific to tuples.
*)

(*
  Example 1: Matching integers
*)

let describe_int n =
  match n with
  | 0 -> "zero"
  | 1 -> "one"
  | _ -> "something else"

let () =
  print_endline "\n--- describe_int ---";
  print_endline (describe_int 0);
  print_endline (describe_int 5)

(*
  Example 2: Matching booleans
*)

let describe_bool b =
  match b with
  | true -> "it is true"
  | false -> "it is false"

let () =
  print_endline "\n--- describe_bool ---";
  print_endline (describe_bool true)

(*
  Example 3: Matching strings
*)

let greet name =
  match name with
  | "Alice" -> "Hello Alice!"
  | "Bob" -> "Hey Bob!"
  | _ -> "Hello stranger"

let () =
  print_endline "\n--- greet ---";
  print_endline (greet "Alice");
  print_endline (greet "John")

(*
  KEY IDEA:

  Pattern matching is NOT about tuples.

  It is about:

      "Does this value match this SHAPE or VALUE?"
*)

(*
  =========================
  LISTS (VERY IMPORTANT)
  =========================

  Lists are NOT arrays.

  They are linked structures.

  Example:
*)

let my_list = [1; 2; 3]

(*
  Internally (conceptually):

      1 :: 2 :: 3 :: []

  Each element points to the next.

  This is why:
  - fast to add to front
  - slower to access by index
*)

(*
  Pattern matching lists:
*)

let describe_list lst =
  match lst with
  | [] -> "empty list"
  | [x] -> "one element"
  | x :: xs -> "multiple elements"

let () =
  print_endline (describe_list []);
  print_endline (describe_list [1]);
  print_endline (describe_list [1;2;3])

(*
  IMPORTANT PATTERNS:

  []        → empty list
  x :: xs   → head + tail

  Example:

      [1;2;3]

  becomes:

      x = 1
      xs = [2;3]
*)

(*
  =========================
  HOW :: BUILDS LISTS (MEMORY)
  =========================

  The operator:

      x :: xs

  means:

      "create a NEW node with x,
       and point it to xs"
*)

let build_list () =
  let lst1 = [] in
  let lst2 = 3 :: lst1 in
  let lst3 = 2 :: lst2 in
  let lst4 = 1 :: lst3 in

  List.iter (fun x -> Printf.printf "%d " x) lst4;
  print_newline ()

let () =
  print_endline "\n--- build_list ---";
  build_list ()

(*
  lst1 = []

  lst2 = 3 :: []
        Node(3) -> []

  lst3 = 2 :: lst2
        Node(2) -> Node(3) -> []

  lst4 = 1 :: lst3
        Node(1) -> Node(2) -> Node(3) -> []

  IMPORTANT:

  Each "::" creates a NEW node.

  It does NOT modify old lists.

  Lists are IMMUTABLE.
*)

(*
  =========================
  LIST STRUCTURE (DEEP)
  =========================

  Input:
      [1;2;3;4]

  Internally:
      1 :: (2 :: (3 :: (4 :: [])))

  Memory (conceptual):

      Node(1) -> Node(2) -> Node(3) -> Node(4) -> []

  VERY IMPORTANT:

  The LAST NODE looks like:

      Node(4) -> []

  Meaning:
      head = 4
      tail = []

  So pattern matching:

      4 :: []

  NOT:
      4 :: something_else

  This is the BASE CASE boundary.
*)

let inspect_list lst =
  match lst with
  | [] -> "empty"
  | [x] -> "single element (last node)"
  | x :: xs -> "multiple elements"

let () =
  print_endline (inspect_list [1;2;3;4]);
  print_endline (inspect_list [4]);
  print_endline (inspect_list [])

(*
  =========================
  WHY xs IS A LIST
  =========================

  Pattern:
      x :: xs

  Means:
      x = FIRST element
      xs = REST OF THE LIST

  Example:
      [1;2;3;4]

  Step:
      x = 1
      xs = [2;3;4]

  xs is NOT 2
  xs is EVERYTHING AFTER 1
*)

let show_head_tail lst =
  match lst with
  | [] -> print_endline "empty list"
  | x :: xs ->
      Printf.printf "head = %d\n" x;
      Printf.printf "tail length = %d\n" (List.length xs)

let () =
  show_head_tail [1;2;3;4]

(*
  =========================
  HOW LISTS ARE BUILT (::)
  =========================

  Lists are IMMUTABLE → cannot change existing nodes

  So when you "add", you CREATE NEW NODES

  Example:
*)

let original = [2;3;4]

let new_list = 1 :: original

(*
  Memory:

      original:
          Node(2) -> Node(3) -> Node(4)

      new_list:
          Node(1) -> (points to original)

  IMPORTANT:
      original is NOT copied
      it is REUSED

  This is called:
      "structural sharing"
*)

let () =
  Printf.printf "original length = %d\n" (List.length original);
  Printf.printf "new_list length = %d\n" (List.length new_list)


(*
  =========================
  RECURSION (CRITICAL)
  =========================

  OCaml does NOT rely on loops like:
      for / while

  Instead:
      functions call themselves
*)

(*
  BASIC RECURSION EXAMPLE
*)

let rec factorial n =
  match n with
  | 0 -> 1
  | _ -> n * factorial (n - 1)

let () =
  Printf.printf "factorial 5 = %d\n" (factorial 5)

(*
  Execution:

      factorial 5
      → 5 * factorial 4
      → 5 * (4 * factorial 3)
      → ...
      → 5 * 4 * 3 * 2 * 1
*)

(*
  KEY IDEA:

  Every recursive function needs:
  1. Base case (stopping point)
  2. Recursive case
*)

(*
  =========================
  RECURSION + LISTS
  =========================

  This is where everything connects.
*)

(*
  Sum of a list
*)

let rec sum_list lst =
  match lst with
  | [] -> 0
  | x :: xs -> x + sum_list xs

let () =
  Printf.printf "sum_list = %d\n" (sum_list [1;2;3;4])

(*
  Execution:

      sum_list [1;2;3]

      = 1 + sum_list [2;3]
      = 1 + (2 + sum_list [3])
      = 1 + (2 + (3 + sum_list []))
      = 1 + (2 + (3 + 0))
      = 6
*)

(*
  =========================
  RECURSION TRACE (VERY DETAILED)
  =========================
*)

let rec sum_list lst =
  match lst with
  | [] ->
      print_endline "Step: reached [] → return 0";
      0

  | x :: xs ->
      Printf.printf "Step: x = %d, calling sum_list on rest\n" x;

      let recursive_result = sum_list xs in

      Printf.printf "Step: returned from recursion = %d\n" recursive_result;

      let final = x + recursive_result in

      Printf.printf "Step: %d + %d = %d\n" x recursive_result final;

      final

let () =
  print_endline "\n--- recursion trace ---";
  Printf.printf "Final result = %d\n" (sum_list [1;2;3])

(*
  sum_list [1;2;3]

  STEP 1:
      x = 1
      call sum_list [2;3]

  STEP 2:
      x = 2
      call sum_list [3]

  STEP 3:
      x = 3
      call sum_list []

  STEP 4:
      [] → return 0

  NOW WE GO BACK UP:

  STEP 5:
      3 + 0 = 3

  STEP 6:
      2 + 3 = 5

  STEP 7:
      1 + 5 = 6

  FINAL:
      6
*)

(*
  =========================
  VISUAL RECURSION (STACK TRACE)
  =========================

  This shows HOW recursion builds and returns.

  depth controls indentation → simulates stack depth
*)

let rec visual_sum lst depth =
  match lst with
  | [] ->
      Printf.printf "%sReturn 0 (base case)\n" (String.make depth ' ');
      0

  | x :: xs ->
      Printf.printf "%sCall: x = %d, going deeper\n"
        (String.make depth ' ') x;

      (*
        Recursive call goes DEEPER FIRST
      *)
      let recursive_result = visual_sum xs (depth + 2) in

      (*
        Only AFTER recursion returns do we compute
      *)
      let final = x + recursive_result in

      Printf.printf "%sCompute: %d + %d = %d\n"
        (String.make depth ' ') x recursive_result final;

      final

let () =
  print_endline "\n--- visual stack ---";
  ignore (visual_sum [1;2;3;4] 0)


(*
  =========================
  VISUAL STACK OUTPUT EXPLAINED
  =========================

  Call: x = 1
      → first element
      → go deeper with [2;3;4]

    Call: x = 2
        → go deeper with [3;4]

      Call: x = 3
          → go deeper with [4]

        Call: x = 4
            → go deeper with []

          Return 0 (base case)
            → reached end of list

        Compute: 4 + 0 = 4
            → now we start computing

      Compute: 3 + 4 = 7

    Compute: 2 + 7 = 9

  Compute: 1 + 9 = 10

  FINAL RESULT:
      10

  --------------------------------------------------

  KEY IDEA:

      STACK grows DOWN:

          1 → 2 → 3 → 4 → []

      THEN shrinks UP:

          0 → 4 → 7 → 9 → 10

  --------------------------------------------------

  THIS IS CALLED:

      "call stack unwinding"
*)


(*
  =========================
  TRICKY EXAMPLE 1
  =========================
*)

let rec tricky lst =
  match lst with
  | [] -> 0
  | x :: xs ->
      tricky xs

let () =
  print_endline "\n--- tricky ---";
  Printf.printf "Result = %d\n" (tricky [1;2;3;4])

(*NOW YOU MAY ASSUME THAT THE ANSWER IS 10 BUT ITS ACTUALLY 0*
  THE STEP BY STEP VISUAL IS PASTED BELOW: *)

(*
  STEP 1:
      tricky [1;2;3;4]
      → ignore 1
      → call tricky [2;3;4]

  STEP 2:
      → ignore 2
      → call tricky [3;4]

  STEP 3:
      → ignore 3
      → call tricky [4]

  STEP 4:
      → ignore 4
      → call tricky []

  STEP 5:
      [] → return 0

  NOTHING was ever added.

  So final result = 0
*)

(*
  =========================
  TRICKY EXAMPLE 2
  =========================
*)

let rec tricky2 lst =
  match lst with
  | [] -> 1
  | x :: xs ->
      x * tricky2 xs

let () =
  print_endline "\n--- tricky2 ---";
  Printf.printf "Result = %d\n" (tricky2 [1;2;3;4])

(*NOW YOU MAY ASSUME THAT THE ANSWER IS 0 BUT ITS ACTUALLY 24*
  THE STEP BY STEP VISUAL IS PASTED BELOW: *)

(*
  STEP 1:
      1 * tricky2 [2;3;4]

  STEP 2:
      2 * tricky2 [3;4]

  STEP 3:
      3 * tricky2 [4]

  STEP 4:
      4 * tricky2 []

  STEP 5:
      [] → 1

  RESULT:
      1 * 2 * 3 * 4 * 1 = 24

  WHY 1?

  Because 1 is the "neutral element" for multiplication.

  If it was 0:
      everything would become 0 ❌
*)

(*
  =========================
  TRICKY EXAMPLE 3
  =========================

  Code:
*)


let rec tricky lst =
  match lst with
  | [] -> 0
  | x :: xs ->
      tricky xs + x

let () =
  Printf.printf "\ntricky result = %d\n" (tricky [1;2;3])

(*
  Input:
      [1;2;3]

  Internally:
      1 :: (2 :: (3 :: []))

  --------------------------------------------------
  STEP-BY-STEP EXECUTION (VERY IMPORTANT)
  --------------------------------------------------

  STEP 1:
      tricky [1;2;3]

      pattern match:
          x = 1
          xs = [2;3]

      expression:
          tricky [2;3] + 1

      IMPORTANT:
          OCaml MUST evaluate tricky [2;3] FIRST
          (left side of + must be computed first)

  --------------------------------------------------

  STEP 2:
      tricky [2;3]

      x = 2
      xs = [3]

      expression:
          tricky [3] + 2

      still cannot add yet → go deeper

  --------------------------------------------------

  STEP 3:
      tricky [3]

      x = 3
      xs = []

      expression:
          tricky [] + 3

      still cannot add → go deeper

  --------------------------------------------------

  STEP 4 (BASE CASE):
      tricky []

      matches:
          [] -> 0

      RETURN 0

  --------------------------------------------------
  NOW WE "UNWIND" (COME BACK UP THE STACK)
  --------------------------------------------------

  STEP 5:
      tricky [3]

      we now have:
          tricky [] = 0

      so:
          0 + 3 = 3

      RETURN 3

  --------------------------------------------------

  STEP 6:
      tricky [2;3]

      we now have:
          tricky [3] = 3

      so:
          3 + 2 = 5

      RETURN 5

  --------------------------------------------------

  STEP 7:
      tricky [1;2;3]

      we now have:
          tricky [2;3] = 5

      so:
          5 + 1 = 6

      RETURN 6

  --------------------------------------------------

  FINAL RESULT:
      6

  --------------------------------------------------
  KEY INSIGHT:

      Computation happens AFTER recursion returns.

      NOT:
          1 + 2 + 3 (left → right)

      BUT:
          go down → THEN compute while coming back
*)


(*
  =========================
  MEMORY MODEL (IMPORTANT)
  =========================

  Lists are stored in memory like:

      [1;2;3]

  becomes:

      Node(1) → Node(2) → Node(3) → []

  Each recursive call:

      sum_list xs

  creates a new function frame (stack)

  When base case is reached:
      results "unwind" back up
*)

(*
  =========================
  BUILDING LISTS
  =========================
*)

let rec double_list lst =
  match lst with
  | [] -> []
  | x :: xs -> (x * 2) :: double_list xs

let () =
  let result = double_list [1;2;3] in
  List.iter (fun x -> Printf.printf "%d " x) result;
  print_newline ()

(*
  Explanation:

      double_list [1;2;3]

      = (1*2) :: double_list [2;3]
      = 2 :: (4 :: (6 :: []))
      = [2;4;6]
*)

(*
  =========================
  FILTER EVEN 
  =========================

  Goal:
      Keep only EVEN numbers from a list

  Input:
      [1;2;3;4;5;6]

  Expected Output:
      [2;4;6]

  ---------------------------------
  CODE
  ---------------------------------
*)

let rec filter_even lst =
  match lst with
  | [] ->
      (*
        BASE CASE:
        Empty list → nothing to filter
        Return empty list
      *)
      []

  | x :: xs ->
      (*
        BREAK STRUCTURE:

        x  = first element
        xs = rest of list

        Example:
            [1;2;3;4]

        becomes:
            x  = 1
            xs = [2;3;4]
      *)

      if x mod 2 = 0 then
        (*
          CASE: x is EVEN

          We KEEP it.

          IMPORTANT:
          We DO NOT mutate list.

          We CREATE a NEW list node:

              x :: (result of recursion)

          So this builds the result list.
        *)
        x :: filter_even xs

      else
        (*
          CASE: x is ODD

          We SKIP it.

          Just return recursion result.
        *)
        filter_even xs

(*
  ---------------------------------
  STEP-BY-STEP EXECUTION TRACE
  ---------------------------------

  filter_even [1;2;3;4;5;6]

  STEP 1:
      x = 1 (odd)
      → skip
      → filter_even [2;3;4;5;6]

  STEP 2:
      x = 2 (even)
      → keep
      → 2 :: filter_even [3;4;5;6]

  STEP 3:
      x = 3 (odd)
      → skip
      → filter_even [4;5;6]

  STEP 4:
      x = 4 (even)
      → keep
      → 4 :: filter_even [5;6]

  STEP 5:
      x = 5 (odd)
      → skip
      → filter_even [6]

  STEP 6:
      x = 6 (even)
      → keep
      → 6 :: filter_even []

  STEP 7:
      [] → return []

  ---------------------------------
  BUILDING BACK (IMPORTANT)
  ---------------------------------

      filter_even [] = []

      filter_even [6] = 6 :: [] = [6]

      filter_even [5;6] = [6]

      filter_even [4;5;6] = 4 :: [6] = [4;6]

      filter_even [3;4;5;6] = [4;6]

      filter_even [2;3;4;5;6] = 2 :: [4;6] = [2;4;6]

      filter_even [1;2;3;4;5;6] = [2;4;6]
*)

let () =
  let result = filter_even [1;2;3;4;5;6] in

  (*
    Print result:
  *)
  print_endline "Filtered even numbers:";

  List.iter (fun x -> Printf.printf "%d " x) result;

  print_newline ()

(*
  =========================
  PATTERN MATCHING vs IF
  =========================

  IF:
      checks conditions

  MATCH:
      checks structure

  Example:
*)

let is_empty lst =
  match lst with
  | [] -> true
  | _ -> false

(*
  Cleaner than:

      if lst = [] then true else false
*)

(*
  =========================
  PATTERN: [_] vs _
  =========================

  [_]  → EXACTLY ONE ELEMENT LIST
  _    → ANY VALUE (wildcard)
*)

let describe_list lst =
  match lst with
  | [] -> "empty list"

  | [_] -> "one element"

      (*
        [_] means:

        A list with EXACTLY ONE element

        Example:
            [5] matches
            [1;2] does NOT match

        Internally:
            x :: []  (one node, then empty)
      *)
      

  | _ -> "multiple elements"

      (*
        _ means:
            "match ANYTHING else"

        This includes:
            [1;2]
            [1;2;3]
            etc.

        IMPORTANT:
            This is a catch-all case
      *)
      

let () =
  print_endline (describe_list []);
  print_endline (describe_list [10]);
  print_endline (describe_list [1;2;3])

(*
  OUTPUT:

      empty list
      one element
      multiple elements
*)

(*
  =========================
  ADVANCED INSIGHT
  =========================

  Pattern matching is powerful because:

  - It is exhaustive (compiler checks cases)
  - It forces you to think about all possibilities
  - It works with ANY data structure
*)

(*
  - Pattern matching works on ANY data, not just tuples
  - x :: xs = head + rest of list (NOT two elements)
  - Lists are linked structures (nodes in memory)
  - :: creates NEW nodes (immutability)
  - Recursion = function calls building a stack
  - Base case controls final result (VERY IMPORTANT)
*)

(*
  =========================
  DEMO SECTION
  =========================
*)

let () =
  print_endline "\n--- Lesson 3 Demo ---";

  print_endline (describe_number 42);

  Printf.printf "factorial 4 = %d\n" (factorial 4);

  Printf.printf "sum_list = %d\n" (sum_list [10;20;30]);

  let doubled = double_list [5;6;7] in
  List.iter (fun x -> Printf.printf "%d " x) doubled;
  print_newline ();

  let evens = filter_even [1;2;3;4;5;6] in
  List.iter (fun x -> Printf.printf "%d " x) evens;
  print_newline ()
