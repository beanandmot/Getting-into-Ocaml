(*
  LESSON 4: Tail Recursion, Memory Model, and the Type System

  This lesson covers three deeply connected topics:

  1. The call stack — why normal recursion can crash
  2. Tail recursion — how to fix it using accumulators
  3. The type system — variants, the REAL power of OCaml

  By the end you will understand:
  - Why stack overflow happens
  - How tail recursion eliminates it
  - How to define your own types and match on them

  Run everything on: https://ocaml.org/play
*)


(*
  =========================
  PART 1: MEMORY — STACK vs HEAP
  =========================

  Before we talk about recursion, we need to understand
  WHERE things live in memory.

  There are two regions:

  ┌──────────────────────────────────────────┐
  │  STACK                                   │
  │  - Function call frames                  │
  │  - Fixed size (usually ~1-8 MB)          │
  │  - Managed automatically (LIFO)          │
  │  - Fast                                  │
  ├──────────────────────────────────────────┤
  │  HEAP                                    │
  │  - Long-lived allocated values           │
  │  - Lists, tuples, closures, strings      │
  │  - Managed by Garbage Collector (GC)     │
  │  - Larger, slower to allocate            │
  └──────────────────────────────────────────┘

  STACK (call frames):

    When a function is called, the runtime pushes
    a "frame" onto the stack.

    A frame contains:
      - The function's local bindings
      - Where to return to when done

    When the function returns, the frame is POPPED.

    LIFO = Last In, First Out
    (the most recent frame is always removed first)

  HEAP (allocated values):

    When you create a list like [1;2;3],
    the nodes are allocated on the HEAP.

    They stay there until nothing references them,
    then the GC cleans them up.

    OCaml lists, tuples, strings, closures —
    all live on the heap.

  WHY DOES THIS MATTER?

    The stack is SMALL.

    If you call a function recursively 1,000,000 times,
    you push 1,000,000 frames.

    That will CRASH with:

        Stack_overflow

    Tail recursion is the solution.
*)


(*
  =========================
  PART 2: NORMAL RECURSION — THE STACK PROBLEM
  =========================

  Let's look at a normal recursive sum.
*)

let rec sum_normal lst =
  match lst with
  | [] -> 0
  | x :: xs -> x + sum_normal xs

(*
  This looks fine. Let's trace what happens in memory.

  sum_normal [1; 2; 3]

  ─────────────────────────────────────────────────────
  CALL STACK (grows downward as we recurse)
  ─────────────────────────────────────────────────────

  Frame 1:  sum_normal [1;2;3]   → waiting: 1 + ???
              calls sum_normal [2;3]
  Frame 2:  sum_normal [2;3]     → waiting: 2 + ???
              calls sum_normal [3]
  Frame 3:  sum_normal [3]       → waiting: 3 + ???
              calls sum_normal []
  Frame 4:  sum_normal []        → RETURNS 0

  ─────────────────────────────────────────────────────
  NOW WE UNWIND (frames pop, additions happen)
  ─────────────────────────────────────────────────────

  Frame 4 returns 0
  Frame 3 computes: 3 + 0 = 3,  pops
  Frame 2 computes: 2 + 3 = 5,  pops
  Frame 1 computes: 1 + 5 = 6,  pops

  RESULT: 6

  ─────────────────────────────────────────────────────

  KEY INSIGHT:

  The "+ " part cannot be computed UNTIL we come back up.
  So all frames must stay on the stack simultaneously.

  For a list of 1,000,000 elements:
      → 1,000,000 frames on the stack
      → Stack overflow ❌

  The problem: there is PENDING WORK after each recursive call.

      x + sum_normal xs
           ↑
      This addition is "pending" until sum_normal xs returns.
      So the frame cannot be removed yet.
*)

let () =
  Printf.printf "sum_normal [1;2;3] = %d\n" (sum_normal [1;2;3])


(*
  =========================
  PART 3: TAIL RECURSION — THE FIX
  =========================

  A function call is "tail position" when it is the
  LAST thing the function does.

  There is NO pending work after the call.

  Example — NOT tail position:

      x + sum_normal xs     (* addition is pending after the call *)

  Example — IS tail position:

      sum_tail xs acc       (* nothing happens after this call *)

  When a call is in tail position:
  → OCaml can REUSE the current stack frame
  → No new frame is pushed
  → Stack stays constant size regardless of list length

  This is called:
      TAIL CALL OPTIMIZATION (TCO)

  HOW TO MAKE IT TAIL RECURSIVE:
  Use an ACCUMULATOR — an extra argument that carries
  the "result so far" forward instead of backward.
*)

let rec sum_tail lst acc =
  match lst with
  | [] -> acc                        (* base case: return what we accumulated *)
  | x :: xs -> sum_tail xs (acc + x) (* tail call: result travels FORWARD *)

(*
  TRACE: sum_tail [1;2;3] 0

  ─────────────────────────────────────────────────────
  CALL STACK
  ─────────────────────────────────────────────────────

  sum_tail [1;2;3] 0
      → tail call: sum_tail [2;3] (0+1)
      → tail call: sum_tail [3]   (1+2)
      → tail call: sum_tail []    (3+3)
      → base case: return 6

  ─────────────────────────────────────────────────────

  KEY DIFFERENCE:

  Normal recursion:    computes while COMING BACK UP
  Tail recursion:      computes while GOING DOWN

  With tail recursion:
  - The accumulator carries the answer FORWARD
  - Each call is the LAST thing that happens
  - OCaml reuses the same stack frame every time
  - Stack stays flat, no overflow possible

  COMPARISON:

  Normal:   frame 1 → frame 2 → frame 3 → frame 4
                                           ↓
                              frame 3 ← result
                   frame 2 ← result
        frame 1 ← result

  Tail:     frame (reused) → frame (reused) → frame (reused)
                                                      ↓
                                              result returned directly

  ─────────────────────────────────────────────────────

  COMMON PATTERN:

  Expose a clean interface by wrapping the tail-recursive
  function. The user doesn't need to pass 0 themselves.
*)

let sum lst = sum_tail lst 0

(*
  Now:
      sum [1;2;3]   → calls sum_tail [1;2;3] 0
*)

let () =
  Printf.printf "sum [1;2;3] = %d\n" (sum [1;2;3]);
  Printf.printf "sum [] = %d\n" (sum [])


(*
  =========================
  TRICKY EXAMPLE: REVERSE A LIST
  =========================

  Goal: reverse [1;2;3] → [3;2;1]

  NON-TAIL-RECURSIVE version (bad for large lists):
*)

let rec reverse_slow lst =
  match lst with
  | [] -> []
  | x :: xs -> reverse_slow xs @ [x]

(*
  PROBLEM:
  - @ (append) is O(n) — it copies the left list
  - Called on each element → O(n²) total
  - NOT tail recursive

  TRACE: reverse_slow [1;2;3]

      reverse_slow [2;3] @ [1]
      (reverse_slow [3] @ [2]) @ [1]
      ((reverse_slow [] @ [3]) @ [2]) @ [1]
      (([] @ [3]) @ [2]) @ [1]
      ([3] @ [2]) @ [1]
      [3;2] @ [1]
      [3;2;1]

  All those frames wait on the stack. Bad.

  ─────────────────────────────────────────────────────

  TAIL-RECURSIVE version (fast, O(n)):
*)

let rec reverse_tail lst acc =
  match lst with
  | [] -> acc
  | x :: xs -> reverse_tail xs (x :: acc)

(*
  TRACE: reverse_tail [1;2;3] []

  Step 1: x=1, xs=[2;3], acc=[]
      → reverse_tail [2;3] (1 :: [])
      → reverse_tail [2;3] [1]

  Step 2: x=2, xs=[3], acc=[1]
      → reverse_tail [3] (2 :: [1])
      → reverse_tail [3] [2;1]

  Step 3: x=3, xs=[], acc=[2;1]
      → reverse_tail [] (3 :: [2;1])
      → reverse_tail [] [3;2;1]

  Step 4: [] → return acc = [3;2;1]

  RESULT: [3;2;1] ✅

  KEY INSIGHT:
  We build the reversed list in the accumulator by
  prepending (::) each element as we go.
  Since we process left to right and prepend,
  we naturally reverse the order.
*)

let reverse lst = reverse_tail lst []

let () =
  let r = reverse [1;2;3] in
  List.iter (fun x -> Printf.printf "%d " x) r;
  print_newline ()


(*
  =========================
  TRICKY EXAMPLE: FIBONACCI (tail vs normal)
  =========================

  Normal fibonacci — double recursion, NOT tail recursive:
*)

let rec fib_normal n =
  if n <= 1 then n
  else fib_normal (n - 1) + fib_normal (n - 2)

(*
  This is exponential time O(2^n) AND blows the stack.

  Why double recursion is so bad:

      fib 5
      ├── fib 4
      │   ├── fib 3
      │   │   ├── fib 2 ...
      │   │   └── fib 1
      │   └── fib 2 ...
      └── fib 3
          ├── fib 2 ...
          └── fib 1

  Same subproblems computed again and again.

  TAIL RECURSIVE fibonacci using TWO accumulators:
  acc_a = fib(n-1), acc_b = fib(n)
*)

let rec fib_tail n acc_a acc_b =
  if n = 0 then acc_a
  else fib_tail (n - 1) acc_b (acc_a + acc_b)

(*
  TRACE: fib_tail 5 0 1

  n=5: fib_tail 4  1  (0+1)  = fib_tail 4 1 1
  n=4: fib_tail 3  1  (1+1)  = fib_tail 3 1 2
  n=3: fib_tail 2  2  (1+2)  = fib_tail 2 2 3
  n=2: fib_tail 1  3  (2+3)  = fib_tail 1 3 5
  n=1: fib_tail 0  5  (3+5)  = fib_tail 0 5 8
  n=0: return acc_a = 5

  fib(5) = 5 ✅

  The two accumulators "slide" along the fibonacci sequence.
  At each step: new_a = old_b, new_b = old_a + old_b
  This is exactly how fibonacci works, but iteratively.
*)

let fib n = fib_tail n 0 1

let () =
  Printf.printf "fib 5 = %d\n" (fib 5);
  Printf.printf "fib 10 = %d\n" (fib 10)


(*
  =========================
  PART 4: THE TYPE SYSTEM — OCaml's Superpower
  =========================

  OCaml's type system is its most important feature.

  You can define your OWN types.

  The key concept is called:

      ALGEBRAIC DATA TYPE (ADT)
      or
      VARIANT TYPE

  Syntax:

      type my_type =
        | Constructor1
        | Constructor2 of some_type
        | Constructor3 of type_a * type_b

  Each "| Constructor" is called a VARIANT.

  Think of it as:
      "A value of this type is EITHER this OR that OR that..."
*)


(*
  =========================
  SIMPLE VARIANT: NO DATA
  =========================
*)

type direction =
  | North
  | South
  | East
  | West

(*
  A value of type direction is exactly ONE of:
  North, South, East, or West.

  Nothing else.

  Usage:
*)

let describe_dir d =
  match d with
  | North -> "Going north"
  | South -> "Going south"
  | East  -> "Going east"
  | West  -> "Going west"

(*
  WHY THIS IS POWERFUL:

  The compiler FORCES you to handle every case.

  If you forget a case:

      let describe_dir d =
        match d with
        | North -> "north"
        | South -> "south"
        (* forgot East and West *)

  OCaml gives a WARNING:
      Warning 8: this pattern-matching is not exhaustive

  This catches bugs at COMPILE TIME, not at runtime.

  Compare with Python/JS:

      if d == "north": ...
      elif d == "south": ...
      # forgot east — no warning, silent bug ❌

  OCaml: won't let you forget. ✅
*)

let () =
  print_endline (describe_dir North);
  print_endline (describe_dir East)


(*
  =========================
  VARIANT WITH DATA
  =========================

  Variants can CARRY data.

  Syntax:
      | Constructor of type
*)

type shape =
  | Circle    of float               (* radius *)
  | Rectangle of float * float       (* width * height *)
  | Triangle  of float * float       (* base * height *)

(*
  A value of type shape is:
  - A Circle carrying a float (the radius)
  - A Rectangle carrying two floats (width, height)
  - A Triangle carrying two floats (base, height)

  Creating values:
*)

let c = Circle 5.0
let r = Rectangle (3.0, 4.0)
let t = Triangle (6.0, 2.0)

(*
  Computing area — pattern matching extracts the data:
*)

let area s =
  match s with
  | Circle r         -> Float.pi *. r *. r
  | Rectangle (w, h) -> w *. h
  | Triangle (b, h)  -> 0.5 *. b *. h

(*
  WHAT HAPPENS STEP BY STEP:

  area (Circle 5.0)
      → matches: Circle r   with r = 5.0
      → computes: pi * 5.0 * 5.0
      → 78.539...

  area (Rectangle (3.0, 4.0))
      → matches: Rectangle (w, h)   with w=3.0, h=4.0
      → computes: 3.0 * 4.0
      → 12.0

  The pattern (w, h) EXTRACTS the values from the variant.
  This is destructuring — same idea as tuples, but for variants.
*)

let () =
  Printf.printf "Circle area: %f\n"    (area c);
  Printf.printf "Rectangle area: %f\n" (area r);
  Printf.printf "Triangle area: %f\n"  (area t)


(*
  =========================
  THE OPTION TYPE (BUILT-IN VARIANT)
  =========================

  One of the most important types in OCaml.

  Defined in the standard library as:

      type 'a option =
        | None
        | Some of 'a

  It represents a value that might NOT exist.

  'a means: "any type" (we will explore this more later)

  USE CASE:

  In Python, if a function might fail to find a value,
  it often returns None:

      def find_user(id):
          if found:
              return user
          return None

  The problem: the caller might forget to check for None.
  → Runtime crash (NullPointerException, AttributeError)

  In OCaml, you MUST check. The type forces you to.
*)

(*
  Example: safe integer division
*)

let safe_divide a b =
  if b = 0 then None
  else Some (a / b)

(*
  Return type is: int option

  Meaning: "either None OR Some int"

  Usage — you MUST pattern match:
*)

let () =
  let result1 = safe_divide 10 2 in
  let result2 = safe_divide 10 0 in

  (match result1 with
  | None   -> print_endline "Division failed"
  | Some v -> Printf.printf "10 / 2 = %d\n" v);

  (match result2 with
  | None   -> print_endline "Cannot divide by zero"
  | Some v -> Printf.printf "Result: %d\n" v)

(*
  IMPORTANT:

  If you try to use the result WITHOUT matching:

      let x = safe_divide 10 2
      Printf.printf "%d" x   ❌

  OCaml will refuse to compile — x is an int option,
  not an int. You must unwrap it.

  Compare Python:
      result = safe_divide(10, 2)
      print(result + 1)   # might crash if None ❌

  OCaml: impossible to forget. The type won't allow it. ✅
*)


(*
  =========================
  RECURSIVE VARIANTS — DEFINING YOUR OWN LIST
  =========================

  This is deep but important.

  OCaml's built-in list is ITSELF a variant type.
  Internally it looks like:

      type 'a list =
        | []
        | (::) of 'a * 'a list

  Which means:
  A list is either:
  - Empty ([])
  - A value of type 'a, followed by another list of 'a

  Let's build our OWN list type to understand this:
*)

type 'a my_list =
  | Empty
  | Cons of 'a * 'a my_list

(*
  'a = "any type" — this list works for int, string, etc.

  Creating a list [1;2;3] using our type:

      Cons (1, Cons (2, Cons (3, Empty)))

  Compare with OCaml's built-in:

      1 :: 2 :: 3 :: []

  Identical structure, different syntax.
*)

let my_numbers = Cons (1, Cons (2, Cons (3, Empty)))

(*
  Summing our custom list:
*)

let rec my_sum lst =
  match lst with
  | Empty        -> 0
  | Cons (x, xs) -> x + my_sum xs

(*
  TRACE: my_sum (Cons(1, Cons(2, Cons(3, Empty))))

  Step 1: Cons(1, rest) → 1 + my_sum (Cons(2, Cons(3, Empty)))
  Step 2: Cons(2, rest) → 2 + my_sum (Cons(3, Empty))
  Step 3: Cons(3, rest) → 3 + my_sum Empty
  Step 4: Empty         → 0

  Unwind:
      3 + 0 = 3
      2 + 3 = 5
      1 + 5 = 6

  This is EXACTLY how OCaml's built-in list works internally.
  You are now looking at the machine from the inside.
*)

let () =
  Printf.printf "my_sum = %d\n" (my_sum my_numbers)


(*
  =========================
  COMBINING EVERYTHING:
  VARIANTS + TAIL RECURSION
  =========================

  Let's count shapes in a list, tail-recursively.
*)

let rec count_circles lst acc =
  match lst with
  | [] -> acc
  | Circle _ :: xs    -> count_circles xs (acc + 1)  (* Circle: increment *)
  | _ :: xs           -> count_circles xs acc         (* anything else: skip *)

let count_c lst = count_circles lst 0

(*
  PATTERN: Circle _ means "a Circle with any radius"
  The _ says: "I don't care about the value inside"

  TRACE: count_c [Circle 1.0; Rectangle(2.0,3.0); Circle 4.0]

  Step 1: Circle _ → acc = 0+1 = 1, recurse on rest
  Step 2: Rectangle _ → not a circle, acc stays 1, recurse
  Step 3: Circle _ → acc = 1+1 = 2, recurse
  Step 4: [] → return acc = 2

  RESULT: 2 ✅
*)

let shapes = [Circle 1.0; Rectangle (2.0, 3.0); Circle 4.0; Triangle (1.0, 1.0)]

let () =
  Printf.printf "Number of circles: %d\n" (count_c shapes)


(*
  =========================
  TRICKY EXAMPLE: OPTION + RECURSION
  =========================

  Goal: find the FIRST element matching a condition.
  Return: Some element, or None if not found.
*)

let rec find_first pred lst =
  match lst with
  | []      -> None
  | x :: xs ->
      if pred x then Some x
      else find_first pred xs

(*
  pred is a FUNCTION passed as an argument.
  This is a higher-order function.

  pred : 'a -> bool
  (takes any value, returns bool)

  Usage:
*)

let () =
  let nums = [1; 3; 4; 7; 8] in

  (match find_first (fun x -> x mod 2 = 0) nums with
  | None   -> print_endline "No even number found"
  | Some v -> Printf.printf "First even: %d\n" v);

  (match find_first (fun x -> x > 100) nums with
  | None   -> print_endline "No number > 100 found"
  | Some v -> Printf.printf "Found: %d\n" v)

(*
  TRACE: find_first (fun x -> x mod 2 = 0) [1;3;4;7;8]

  x=1: 1 mod 2 = 1, not 0 → recurse [3;4;7;8]
  x=3: 3 mod 2 = 1, not 0 → recurse [4;7;8]
  x=4: 4 mod 2 = 0  ✅    → return Some 4

  RESULT: Some 4
*)


(*
  =========================
  KEY TAKEAWAYS
  =========================

  TAIL RECURSION:
  - Normal recursion: pending work waits on the stack
  - Tail recursion: result travels FORWARD in accumulator
  - OCaml reuses the stack frame → no stack overflow
  - Pattern: add an "acc" argument, pass result forward

  STACK vs HEAP:
  - Stack: function frames, small, LIFO
  - Heap: allocated values (lists, tuples), larger, GC-managed
  - Deep recursion crashes the STACK, not the heap

  VARIANTS:
  - Define types as "this OR that OR that"
  - Carry data inside each variant: Constructor of type
  - Pattern match to extract and use
  - Compiler enforces exhaustiveness → no forgotten cases

  OPTION TYPE:
  - Built-in variant: None | Some of 'a
  - Forces you to handle the "missing" case
  - Replaces null/None from Python/JS with compile-time safety

  RECURSIVE TYPES:
  - Types can refer to themselves
  - OCaml's list is a recursive variant internally
  - You can build your own data structures this way
*)
