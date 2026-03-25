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
  ============================================================
  NORMAL vs TAIL RECURSION — SIDE BY SIDE
  ============================================================
 
  We will use the simplest possible example: summing a list.
  Same goal, two different approaches, very different memory behavior.
*)
 
 
(* ── NORMAL RECURSION ─────────────────────────────────── *)
 
let rec sum_normal lst =
  match lst with
  | []      -> 0
  | x :: xs -> x + sum_normal xs
 
(*
  Read the recursive case as:
      "split the list into x (head) and xs (tail),
       then add x to whatever sum_normal returns for xs"
 
  The problem: OCaml cannot compute (x + ???) until
  sum_normal xs finishes and returns.
  So each frame must STAY on the stack and wait.
 
  TRACE for sum_normal [1; 2; 3]:
 
    call:  sum_normal [1;2;3]
           → 1 + sum_normal [2;3]        ← frame 1 WAITING
                  2 + sum_normal [3]     ← frame 2 WAITING
                         3 + sum_normal []  ← frame 3 WAITING
                                0           ← base case, returns
 
    unwind (bottom to top):
           frame 3:  3 + 0 = 3  returns
           frame 2:  2 + 3 = 5  returns
           frame 1:  1 + 5 = 6  returns
 
    result: 6
 
  STACK at deepest point (all 4 frames alive at once):
 
    ┌─────────────────────────┐  ← top of stack
    │ frame 4: sum_normal []  │
    ├─────────────────────────┤
    │ frame 3: sum_normal [3] │  waiting on: 3 + ???
    ├─────────────────────────┤
    │ frame 2: sum_normal [2;3]│  waiting on: 2 + ???
    ├─────────────────────────┤
    │ frame 1: sum_normal [1;2;3]│ waiting on: 1 + ???
    └─────────────────────────┘  ← bottom of stack
 
  For a list of 1,000,000 elements → 1,000,000 frames
  → Stack_overflow ❌
*)
 
 
(* ── TAIL RECURSION ───────────────────────────────────── *)
 
let rec sum_tail lst acc =
  match lst with
  | []      -> acc
  | x :: xs -> sum_tail xs (acc + x)
 
(*
  Read the recursive case as:
      "split the list into x (head) and xs (tail),
       compute acc + x RIGHT NOW,
       then call sum_tail with xs and the new acc"
 
  The key: (acc + x) is computed BEFORE the recursive call.
  There is NO pending work after the call.
  OCaml reuses the same stack frame every time.
 
  TRACE for sum_tail [1; 2; 3] 0:
 
    call:  sum_tail [1;2;3] 0
           sum_tail [2;3]   1     ← acc = 0+1
           sum_tail [3]     3     ← acc = 1+2
           sum_tail []      6     ← acc = 3+3
           base case: return 6    ← acc returned directly
 
  STACK the whole time (only ever 1 frame):
 
    ┌─────────────────────────┐
    │ frame (reused):         │  acc travels FORWARD
    │ sum_tail ... ...        │  no waiting, no pileup
    └─────────────────────────┘
 
  For a list of 1,000,000 elements → still just 1 frame
  → No overflow 
 
  DIFFERENCE IN ONE LINE:
 
  Normal:  addition is AFTER the recursive call   → pending work → frames pile up
  Tail:    addition is BEFORE the recursive call  → no pending work → frame reused
 
  ─────────────────────────────────────────────────────────
  POSITION OF EACH PART IN THE PATTERN
  ─────────────────────────────────────────────────────────
 
  | x :: xs -> sum_tail xs (acc + x)
    ↑    ↑               ↑   ↑
    │    │               │   └── new accumulator (computed NOW, passed forward)
    │    │               └────── the rest of the list (tail)
    │    └────────────────────── xs: everything after the first element
    └─────────────────────────── x: the first element (head)
 
  | x :: xs -> x + sum_normal xs
    ↑    ↑     ↑               ↑
    │    │     │               └── xs: rest of list, called recursively
    │    │     └────────────────── x sits here WAITING until xs is done
    │    └────────────────────────── xs: rest of list
    └─────────────────────────────── x: head
 
  The only structural difference:
    - Normal:  x is OUTSIDE the recursive call (waiting)
    - Tail:    acc+x is INSIDE the recursive call (done immediately)
*)
 
(* Clean wrapper so callers don't pass 0 manually *)
let sum lst = sum_tail lst 0
 
let () =
  Printf.printf "sum_normal [1;2;3] = %d\n" (sum_normal [1;2;3]);
  Printf.printf "sum        [1;2;3] = %d\n" (sum [1;2;3])
 
 
(*
  ── ANOTHER EXAMPLE: counting elements ───────────────────
 
  Same pattern, different operation.
  Accumulator counts instead of adds.
*)
 
(* Normal version *)
let rec length_normal lst =
  match lst with
  | []      -> 0
  | _ :: xs -> 1 + length_normal xs
 
(*
  TRACE: length_normal [10; 20; 30]
 
    1 + length_normal [20;30]    ← waiting
        1 + length_normal [30]   ← waiting
            1 + length_normal [] ← waiting
                0                ← base case
 
  unwind: 1+0=1, 1+1=2, 1+2=3
  result: 3
*)
 
(* Tail version *)
let rec length_tail lst acc =
  match lst with
  | []      -> acc
  | _ :: xs -> length_tail xs (acc + 1)
 
(*
  TRACE: length_tail [10; 20; 30] 0
 
    length_tail [20;30] 1   ← acc = 0+1
    length_tail [30]    2   ← acc = 1+1
    length_tail []      3   ← acc = 2+1
    return 3
 
  The _ in (_ :: xs) means:
      "I know there is a head element, but I don't need its value.
       I only care that the list is non-empty."
*)
 
let length lst = length_tail lst 0
 
let () =
  Printf.printf "length_normal [10;20;30] = %d\n" (length_normal [10;20;30]);
  Printf.printf "length        [10;20;30] = %d\n" (length [10;20;30])
 
 


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
  ============================================================
  Some AND None — DEEPER EXPLANATION
  ============================================================
 
  The option type is defined in OCaml's standard library as:
 
      type 'a option =
        | None
        | Some of 'a
 
  'a is a TYPE VARIABLE — a placeholder for any concrete type.
  When you write Some 5, OCaml fills in 'a = int.
  When you write Some "hello", OCaml fills in 'a = string.
  You never write 'a yourself when using it — OCaml infers it.
 
  Think of Some as a LABELLED BOX:
 
      Some 5         →   ┌─────────┐
                         │  5      │  labelled "Some", contains int
                         └─────────┘
 
      Some "hello"   →   ┌─────────┐
                         │ "hello" │  labelled "Some", contains string
                         └─────────┘
 
      None           →   ∅  (empty, no box, no value)
 
  Your Python __init__ comparison:
      Close, but not quite.
      __init__ is about initializing an object with mutable state.
      Some is simpler — it is just a TAG + a VALUE, no mutation,
      no methods, no object. It is a labelled container, read-only.
 
  The closest Python comparison is actually a tagged tuple:
      Some 5     ≈    ("Some", 5)
      None       ≈    ("None",)
  Except OCaml enforces the type at compile time and Python does not.
*)
 
(*
  ── EXAMPLES: option with different types ─────────────────
*)
 
(* Returns the first element, or None if list is empty *)
let first lst =
  match lst with
  | []     -> None
  | x :: _ -> Some x
 
(*
  first [10; 20; 30]  → Some 10   (type: int option)
  first []            → None      (type: int option, but empty)
  first ["a"; "b"]    → Some "a"  (type: string option)
 
  Same function works for any list type.
  'a gets filled in by whatever list you pass.
*)
 
let () =
  (match first [10; 20; 30] with
  | None   -> print_endline "empty list"
  | Some v -> Printf.printf "first element: %d\n" v);
 
  (match first ([] : int list) with
  | None   -> print_endline "empty list"
  | Some v -> Printf.printf "first element: %d\n" v)
 
(*
  WHY YOU MUST MATCH (cannot just "use" the value):
 
  If safe_divide returns an int option,
  and you try to use it as a plain int:
 
      let result = safe_divide 10 2  (* result : int option *)
      let doubled = result * 2       (* ❌ type error *)
 
  OCaml refuses because result might be None,
  and you cannot multiply None by 2.
 
  You MUST unwrap it first:
 
      match safe_divide 10 2 with
      | None   -> 0
      | Some v -> v * 2   (* ✅ v is a plain int here *)
 
  This is the entire point of option:
  it makes the possibility of "no value" VISIBLE in the type,
  so you cannot ignore it by accident.
 
  Python equivalent (no enforcement):
      result = safe_divide(10, 2)   # might be None
      doubled = result * 2          # crashes at runtime if None ❌
*)
 
 
(*
  ── CHAINING option WITH A HELPER ─────────────────────────
 
  A common pattern: transform the value inside Some,
  leave None alone.
*)
 
let map_option f opt =
  match opt with
  | None   -> None
  | Some v -> Some (f v)
 
(*
  map_option (fun x -> x * 2) (Some 5)   → Some 10
  map_option (fun x -> x * 2) None       → None
 
  You don't need to write this yourself —
  OCaml's standard library has Option.map which does exactly this.
  But seeing it written out shows you it is just a match.
*)
 
let () =
  let doubled = map_option (fun x -> x * 2) (Some 5) in
  (match doubled with
  | None   -> print_endline "nothing"
  | Some v -> Printf.printf "doubled: %d\n" v)
 


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
  ============================================================
  SECTION C: Cons AND RECURSIVE TYPES — DEEPER
  ============================================================
 
  Recall the definition:
 
      type 'a my_list =
        | Empty
        | Cons of 'a * 'a my_list
                  ↑    ↑
                  │    └── the REST of the list (same type, recursive)
                  └──────── the VALUE at this position
 
  WHY IS THIS RECURSIVE?
 
  Cons carries two things:
    1. A value of type 'a         (the current element)
    2. A value of type 'a my_list (the rest — which is ALSO a my_list)
 
  So every Cons node points to another my_list.
  That other my_list is either another Cons, or Empty.
  Empty is the stopper — it breaks the chain.
 
  BUILDING [1; 2; 3] step by step:
 
    Step 1: start with Empty
            Empty
 
    Step 2: prepend 3
            Cons (3, Empty)
 
    Step 3: prepend 2
            Cons (2, Cons (3, Empty))
 
    Step 4: prepend 1
            Cons (1, Cons (2, Cons (3, Empty)))
 
  MEMORY LAYOUT (conceptual):
 
    Cons(1, ──►  Cons(2, ──►  Cons(3, ──►  Empty)
      │              │              │
      value=1        value=2        value=3
 
  Each Cons node is a small block on the HEAP containing:
    - the value
    - a pointer to the next node
 
  WHY "Cons"?
 
  It is short for "construct" — from Lisp (1958).
  In Lisp, the function to build a list node was called cons.
  OCaml inherits this tradition.
  OCaml's built-in :: operator IS cons, just with nicer syntax:
 
      1 :: [2; 3]              ← built-in syntax
      Cons (1, Cons (2, ...))  ← what it means internally
 
  They are the same structure.
 
  ── RECURSION ON Cons mirrors the structure ──────────────
 
  Because the type is recursive, the function is recursive too.
  Each Cons case handles one node, then recurses on the tail.
*)
 
type 'a my_list =
  | Empty
  | Cons of 'a * 'a my_list
 
(* Sum a my_list of ints *)
let rec my_sum lst =
  match lst with
  | Empty        -> 0
  | Cons (x, xs) -> x + my_sum xs
 
(*
  Pattern: Cons (x, xs)
    x  = the value in this node  (an int)
    xs = the rest of the list    (a my_list)
 
  This mirrors the structure exactly:
    Cons carries (value, rest)  →  pattern extracts (x, xs)
 
  TRACE: my_sum (Cons(1, Cons(2, Cons(3, Empty))))
 
    Cons(1, rest) → 1 + my_sum (Cons(2, Cons(3, Empty)))
    Cons(2, rest) → 2 + my_sum (Cons(3, Empty))
    Cons(3, rest) → 3 + my_sum Empty
    Empty         → 0
 
    unwind: 3+0=3, 2+3=5, 1+5=6
    result: 6
*)
 
(* Tail-recursive version of my_sum *)
let rec my_sum_tail lst acc =
  match lst with
  | Empty        -> acc
  | Cons (x, xs) -> my_sum_tail xs (acc + x)
 
let my_sum_clean lst = my_sum_tail lst 0
 
let my_numbers = Cons (1, Cons (2, Cons (3, Empty)))
 
let () =
  Printf.printf "my_sum       = %d\n" (my_sum my_numbers);
  Printf.printf "my_sum_clean = %d\n" (my_sum_clean my_numbers)
 
 

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

*
  ============================================================
  SECTION D: find_first — FULL WALKTHROUGH
  ============================================================
 
  Goal: find the first element in a list that satisfies
  some condition. Return Some element or None.
 
  The function takes a PREDICATE — a function that returns bool.
  This is called a HIGHER-ORDER FUNCTION:
  a function that takes another function as an argument.
*)
 
let rec find_first pred lst =
  match lst with
  | []      -> None
  | x :: xs ->
      if pred x then Some x
      else find_first pred xs
 
(*
  PARTS EXPLAINED:
 
  pred
    - a function passed in as an argument
    - type: 'a -> bool  (takes a value, returns true or false)
    - you supply the rule, find_first does the searching
 
  if pred x then Some x
    - call pred with the current head element x
    - if pred returns true: wrap x in Some and return immediately
    - we found what we were looking for, stop recursing
 
  else find_first pred xs
    - pred returned false: x does not match
    - recurse on xs (the rest of the list)
    - NOTE: pred is passed forward unchanged — same rule applies
 
  []  → None
    - reached the end, nothing matched, return None
 
  ── EXAMPLE 1: find first even number ─────────────────────
 
  find_first (fun x -> x mod 2 = 0) [1; 3; 4; 7; 8]
 
  The predicate:  (fun x -> x mod 2 = 0)
  Read as: "given x, return true if x is even"
 
  TRACE:
    x=1:  pred 1  →  1 mod 2 = 1  ≠ 0  →  false  →  recurse [3;4;7;8]
    x=3:  pred 3  →  3 mod 2 = 1  ≠ 0  →  false  →  recurse [4;7;8]
    x=4:  pred 4  →  4 mod 2 = 0  = 0  →  true   →  return Some 4
 
  Result: Some 4  ✅
 
  ── EXAMPLE 2: find first number > 100 ────────────────────
 
  find_first (fun x -> x > 100) [1; 3; 4; 7; 8]
 
  TRACE:
    x=1:  pred 1  →  1 > 100   →  false  →  recurse
    x=3:  pred 3  →  3 > 100   →  false  →  recurse
    x=4:  pred 4  →  4 > 100   →  false  →  recurse
    x=7:  pred 7  →  7 > 100   →  false  →  recurse
    x=8:  pred 8  →  8 > 100   →  false  →  recurse
    []:   base case             →  None
 
  Result: None  ✅
 
  ── EXAMPLE 3: find first string starting with "b" ────────
 
  Predicates work on ANY type, not just ints.
*)
 
let () =
  let words = ["apple"; "banana"; "cherry"; "blueberry"] in
  (match find_first (fun w -> w.[0] = 'b') words with
  | None   -> print_endline "no word starting with b"
  | Some w -> Printf.printf "first b-word: %s\n" w)
 
(*
  w.[0] means: get the first character of string w
  = 'b'  checks if it equals the character 'b'
 
  TRACE:
    w="apple":     'a' = 'b'  →  false  →  recurse
    w="banana":    'b' = 'b'  →  true   →  return Some "banana"
 
  Result: Some "banana"
 
  ── WHY HIGHER-ORDER FUNCTIONS MATTER ─────────────────────
 
  Without higher-order functions, you would need to write:
 
      find_first_even
      find_first_greater_than_100
      find_first_starting_with_b
      ...
 
  One function for every possible condition.
 
  With higher-order functions, you write find_first ONCE
  and pass in whatever condition you need.
  The condition is just data — a function is a value like any other.
 
  This is a core idea in functional programming.
*)
 
let () =
  let nums = [1; 3; 4; 7; 8] in
  (match find_first (fun x -> x mod 2 = 0) nums with
  | None   -> print_endline "no even number"
  | Some v -> Printf.printf "first even: %d\n" v);
 
  (match find_first (fun x -> x > 100) nums with
  | None   -> print_endline "no number > 100"
  | Some v -> Printf.printf "found: %d\n" v)

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
