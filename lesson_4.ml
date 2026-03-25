(*
  LESSON 4: Tail Recursion, Memory Model, and the Type System

  This lesson covers three deeply connected topics:

  1. The call stack -- why normal recursion can crash
  2. Tail recursion -- how to fix it using accumulators
  3. The type system -- variants, the REAL power of OCaml

  By the end you will understand:
  - Why stack overflow happens
  - How tail recursion eliminates it
  - How to define your own types and match on them

  Run everything on: https://ocaml.org/play
*)


(*
  =========================
  PART 1: MEMORY -- STACK vs HEAP
  =========================

  Before we talk about recursion, we need to understand
  WHERE things live in memory.

  There are two regions:

  +------------------------------------------+
  |  STACK                                   |
  |  - Function call frames                  |
  |  - Fixed size (usually ~1-8 MB)          |
  |  - Managed automatically (LIFO)          |
  |  - Fast                                  |
  +------------------------------------------+
  |  HEAP                                    |
  |  - Long-lived allocated values           |
  |  - Lists, tuples, closures, strings      |
  |  - Managed by Garbage Collector (GC)     |
  |  - Larger, slower to allocate            |
  +------------------------------------------+

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

    OCaml lists, tuples, strings, closures --
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
  PART 2: NORMAL RECURSION -- THE STACK PROBLEM
  =========================

  UNDERSTANDING x :: xs

  x :: xs is a PATTERN -- it splits the list:
    x  = the first element (head)
    xs = everything after it (tail)

  The :: here is NOT building a list.
  It is TAKING ONE APART.

  Example:
    [1; 2; 3]  matched against  x :: xs
      x  = 1
      xs = [2; 3]

  [1; 2; 3]  split again on xs:
    x  = 2
    xs = [3]

  And again:
    x  = 3
    xs = []

  POSITION OF EACH PART:

  | x :: xs -> x + sum_normal xs
    |    |     |               |
    |    |     |               +-- recursive call on the tail
    |    |     +------------------ x WAITS here until the call returns
    |    +------------------------ xs: everything after the first element
    +----------------------------- x: the first element (head)
*)

let rec sum_normal lst =
  match lst with
  | []      -> 0
  | x :: xs -> x + sum_normal xs

(*
  TRACE for sum_normal [1; 2; 3]:

    sum_normal [1;2;3]
      1 + sum_normal [2;3]          <- frame 1 WAITING
          2 + sum_normal [3]        <- frame 2 WAITING
              3 + sum_normal []     <- frame 3 WAITING
                  0                 <- base case, returns

    unwind (bottom to top):
      frame 3:  3 + 0 = 3  returns
      frame 2:  2 + 3 = 5  returns
      frame 1:  1 + 5 = 6  returns

    result: 6

  STACK at deepest point (all 4 frames alive at once):

    +---------------------------+  <- top of stack
    | frame 4: sum_normal []   |
    +---------------------------+
    | frame 3: sum_normal [3]  |  waiting on: 3 + ???
    +---------------------------+
    | frame 2: sum_normal [2;3]|  waiting on: 2 + ???
    +---------------------------+
    | frame 1: sum_normal [1;2;3]| waiting on: 1 + ???
    +---------------------------+  <- bottom of stack

  For a list of 1,000,000 elements:
    -> 1,000,000 frames on the stack
    -> Stack_overflow

  THE PROBLEM:
  There is PENDING WORK after each recursive call.
  The addition (x + ???) cannot happen until sum_normal xs returns.
  So the frame cannot be removed yet.
*)

let () =
  Printf.printf "sum_normal [1;2;3] = %d\n" (sum_normal [1;2;3])


(*
  =========================
  PART 3: TAIL RECURSION -- THE FIX
  =========================

  A function call is in "tail position" when it is the
  LAST thing the function does.

  There is NO pending work after the call.

  NOT tail position:
      x + sum_normal xs     (* addition is pending after the call *)

  IS tail position:
      sum_tail xs acc       (* nothing happens after this call *)

  When a call is in tail position:
  -> OCaml can REUSE the current stack frame
  -> No new frame is pushed
  -> Stack stays constant size regardless of list length

  This is called TAIL CALL OPTIMIZATION (TCO).

  HOW TO MAKE IT TAIL RECURSIVE:
  Use an ACCUMULATOR -- an extra argument that carries
  the "result so far" FORWARD instead of computing on the way back.

  POSITION OF EACH PART:

  | x :: xs -> sum_tail xs (acc + x)
    |    |                 |   |
    |    |                 |   +-- new accumulator: computed NOW, passed forward
    |    |                 +------ xs: the rest of the list
    |    +------------------------ xs: everything after the first element
    +----------------------------- x: the first element (head)

  THE ONLY STRUCTURAL DIFFERENCE vs normal recursion:
    Normal:  x is OUTSIDE the recursive call -> pending, frame stays on stack
    Tail:    acc+x is INSIDE the call        -> computed before the call, no wait
*)

let rec sum_tail lst acc =
  match lst with
  | []      -> acc                    (* base case: return accumulated result *)
  | x :: xs -> sum_tail xs (acc + x)  (* tail call: result travels FORWARD *)

(*
  TRACE for sum_tail [1; 2; 3] 0:

    sum_tail [1;2;3] 0
    sum_tail [2;3]   1    <- acc = 0+1 (computed before the call)
    sum_tail [3]     3    <- acc = 1+2
    sum_tail []      6    <- acc = 3+3
    base case: return 6

  STACK the whole time (only ever 1 frame):

    +---------------------------+
    | frame (reused):           |  acc travels FORWARD
    | sum_tail ... ...          |  no waiting, no pileup
    +---------------------------+

  For 1,000,000 elements -> still just 1 frame -> no overflow.

  KEY DIFFERENCE:
    Normal recursion:  computes while COMING BACK UP
    Tail recursion:    computes while GOING DOWN

  COMMON PATTERN:
  Wrap the tail-recursive function so callers don't need to pass 0.
*)

let sum lst = sum_tail lst 0

let () =
  Printf.printf "sum [1;2;3] = %d\n" (sum [1;2;3]);
  Printf.printf "sum []      = %d\n" (sum [])


(*
  =========================
  ANOTHER EXAMPLE: COUNTING ELEMENTS
  =========================

  Same pattern as sum, but accumulator counts instead of adds.
*)

let rec length_normal lst =
  match lst with
  | []      -> 0
  | _ :: xs -> 1 + length_normal xs

(*
  TRACE: length_normal [10; 20; 30]

    1 + length_normal [20;30]    <- waiting
        1 + length_normal [30]   <- waiting
            1 + length_normal [] <- waiting
                0                <- base case

  unwind: 1+0=1, 1+1=2, 1+2=3
  result: 3

  The _ in (_ :: xs) means:
    "I know there is a head element but I don't need its value."
*)

let rec length_tail lst acc =
  match lst with
  | []      -> acc
  | _ :: xs -> length_tail xs (acc + 1)

(*
  TRACE: length_tail [10; 20; 30] 0

    length_tail [20;30] 1   <- acc = 0+1
    length_tail [30]    2   <- acc = 1+1
    length_tail []      3   <- acc = 2+1
    return 3
*)

let length lst = length_tail lst 0

let () =
  Printf.printf "length_normal [10;20;30] = %d\n" (length_normal [10;20;30]);
  Printf.printf "length        [10;20;30] = %d\n" (length [10;20;30])


(*
  =========================
  TRICKY EXAMPLE: REVERSE A LIST
  =========================

  Goal: reverse [1;2;3] -> [3;2;1]

  NON-TAIL-RECURSIVE version (slow for large lists):
*)

let rec reverse_slow lst =
  match lst with
  | []      -> []
  | x :: xs -> reverse_slow xs @ [x]

(*
  @ is the APPEND operator.
  It COPIES the entire left list and attaches the right list at the end.

    [1; 2] @ [3]  ->  [1; 2; 3]

  If the left list has 1000 elements, it creates 1000 new nodes.
  That is O(n) work per call.

  reverse_slow calls @ once per element -> O(n^2) total.
  Also NOT tail recursive -> frames pile up on the stack.

  TRACE: reverse_slow [1;2;3]

    reverse_slow [2;3] @ [1]
    (reverse_slow [3] @ [2]) @ [1]
    (([] @ [3]) @ [2]) @ [1]
    [3;2;1]

  TAIL-RECURSIVE version (fast, O(n)):
*)

let rec reverse_tail lst acc =
  match lst with
  | []      -> acc
  | x :: xs -> reverse_tail xs (x :: acc)

(*
  :: (prepend) creates just ONE new node -- O(1).
  We build the reversed list in the accumulator by prepending
  each element as we go.
  Processing left to right and prepending naturally reverses the order.

  TRACE: reverse_tail [1;2;3] []

  Step 1: x=1, xs=[2;3], acc=[]    -> reverse_tail [2;3] [1]
  Step 2: x=2, xs=[3],   acc=[1]   -> reverse_tail [3]   [2;1]
  Step 3: x=3, xs=[],    acc=[2;1] -> reverse_tail []    [3;2;1]
  Step 4: []                       -> return [3;2;1]
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

  Normal fibonacci -- double recursion, NOT tail recursive:
*)

let rec fib_normal n =
  if n <= 1 then n
  else fib_normal (n - 1) + fib_normal (n - 2)

(*
  O(2^n) time AND blows the stack for large n.

  TAIL RECURSIVE fibonacci using TWO accumulators:
    acc_a = fib(n-1)
    acc_b = fib(n)

  At each step:
    new acc_a = old acc_b
    new acc_b = old acc_a + old acc_b

  The two accumulators slide along the fibonacci sequence.
*)

let rec fib_tail n acc_a acc_b =
  if n = 0 then acc_a
  else fib_tail (n - 1) acc_b (acc_a + acc_b)

(*
  TRACE: fib_tail 5 0 1

  n=5: fib_tail 4  1  1    <- new_a=1,   new_b=0+1
  n=4: fib_tail 3  1  2    <- new_a=1,   new_b=1+1
  n=3: fib_tail 2  2  3    <- new_a=2,   new_b=1+2
  n=2: fib_tail 1  3  5    <- new_a=3,   new_b=2+3
  n=1: fib_tail 0  5  8    <- new_a=5,   new_b=3+5
  n=0: return acc_a = 5

  fib(5) = 5
*)

let fib n = fib_tail n 0 1

let () =
  Printf.printf "fib 5  = %d\n" (fib 5);
  Printf.printf "fib 10 = %d\n" (fib 10)


(*
  =========================
  PART 4: THE TYPE SYSTEM -- OCaml's Superpower
  =========================

  You can define your OWN types.

  The key concept is called an ALGEBRAIC DATA TYPE (ADT),
  also called a VARIANT TYPE.

  Syntax:

      type my_type =
        | Constructor1
        | Constructor2 of some_type
        | Constructor3 of type_a * type_b

  Think of it as:
      "A value of this type is EITHER this OR that OR that..."
*)


(*
  =========================
  SIMPLE VARIANT: NO DATA
  =========================

  OCaml knows there are exactly 4 directions because YOU declared them.
  It has zero real-world knowledge -- it just reads your type definition.
  If you wrote only North and South, it would only know two values.
  YOU define the universe of possible values.
*)

type direction =
  | North
  | South
  | East
  | West

let describe_dir d =
  match d with
  | North -> "Going north"
  | South -> "Going south"
  | East  -> "Going east"
  | West  -> "Going west"

(*
  WHY THIS IS POWERFUL:

  The compiler FORCES you to handle every case.

  If you forget East and West:
      OCaml gives Warning 8: this pattern-matching is not exhaustive

  This catches bugs at COMPILE TIME, not at runtime.

  Compare Python:
      if d == "north": ...
      elif d == "south": ...
      # forgot east -- no warning, silent bug at runtime

  WHAT IF YOU GENUINELY WANT TO SKIP CASES?
  Use _ (wildcard) -- it matches anything, no warning:

      let describe_dir d =
        match d with
        | North -> "going north"
        | _     -> "not north"    (* covers South, East, West *)
*)

let () =
  print_endline (describe_dir North);
  print_endline (describe_dir East)


(*
  =========================
  VARIANT WITH DATA
  =========================

  Variants can CARRY data.
  You declare what type of data each variant holds.
  The * between types means "and" -- like a tuple.

  Rectangle of float * float means "holds two floats."
*)

type shape =
  | Circle    of float              (* holds: radius *)
  | Rectangle of float * float      (* holds: width, height *)
  | Triangle  of float * float      (* holds: base, height *)

let c = Circle 5.0
let r = Rectangle (3.0, 4.0)
let t = Triangle (6.0, 2.0)

(*
  Pattern matching extracts the data from each variant.
  The pattern (w, h) DESTRUCTURES the two floats out of Rectangle.
*)

let area s =
  match s with
  | Circle r         -> Float.pi *. r *. r
  | Rectangle (w, h) -> w *. h
  | Triangle (b, h)  -> 0.5 *. b *. h

(*
  TRACE:

  area (Circle 5.0)
    -> matches Circle r   with r = 5.0
    -> computes pi * 5.0 * 5.0 = 78.539...

  area (Rectangle (3.0, 4.0))
    -> matches Rectangle (w, h) with w=3.0, h=4.0
    -> computes 3.0 * 4.0 = 12.0
*)

let () =
  Printf.printf "Circle area:    %f\n" (area c);
  Printf.printf "Rectangle area: %f\n" (area r);
  Printf.printf "Triangle area:  %f\n" (area t)


(*
  =========================
  THE OPTION TYPE (BUILT-IN VARIANT)
  =========================

  Defined in the standard library as:

      type 'a option =
        | None
        | Some of 'a

  'a is a TYPE VARIABLE -- a placeholder for any concrete type.
  When you write Some 5,       OCaml fills in 'a = int.
  When you write Some "hello", OCaml fills in 'a = string.
  When you write Some 3.14,    OCaml fills in 'a = float.
  You never write 'a yourself -- OCaml infers it from the value.

  Think of Some as a LABELLED BOX:

      Some 5         ->  [ 5 ]        labelled "Some", contains int
      Some "hello"   ->  [ "hello" ]  labelled "Some", contains string
      None           ->  (empty)      no box, no value at all

  Some is NOT like __init__ in Python.
  __init__ initializes a mutable object.
  Some is simpler: just a TAG + a VALUE, read-only, no methods.

  Closest Python comparison -- a tagged tuple:
      Some 5  is like  ("Some", 5)
      None    is like  ("None",)
  Except OCaml enforces the type at compile time.

  REPRESENTS A VALUE THAT MIGHT NOT EXIST.
  Forces you to handle the "missing" case -- you cannot ignore it.
*)

let safe_divide a b =
  if b = 0 then None
  else Some (a / b)

(*
  Return type is: int option
  Meaning: "either None OR Some int"

  If you try to use the result without matching:

      let x = safe_divide 10 2
      Printf.printf "%d" x        <- type error, won't compile

  OCaml refuses because x is an int option, not a plain int.

  You MUST unwrap it:

      match safe_divide 10 2 with
      | None   -> 0
      | Some v -> v * 2    <- v is a plain int here
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
  =========================
  OPTION: MORE EXAMPLES
  =========================

  'a gets filled in automatically based on what you pass.
*)

let first lst =
  match lst with
  | []     -> None
  | x :: _ -> Some x

(*
  first [10; 20; 30]  -> Some 10   (type: int option)
  first []            -> None      (type: int option, but empty)
  first ["a"; "b"]    -> Some "a"  (type: string option)
*)

let () =
  (match first [10; 20; 30] with
  | None   -> print_endline "empty list"
  | Some v -> Printf.printf "first element: %d\n" v);

  (match first ([] : int list) with
  | None   -> print_endline "empty list"
  | Some v -> Printf.printf "first element: %d\n" v)

(*
  A common pattern: transform the value inside Some, leave None alone.
  OCaml's stdlib has Option.map for this -- here it is written out
  so you can see it is just a match.
*)

let map_option f opt =
  match opt with
  | None   -> None
  | Some v -> Some (f v)

(*
  map_option (fun x -> x * 2) (Some 5)  -> Some 10
  map_option (fun x -> x * 2) None      -> None
*)

let () =
  let doubled = map_option (fun x -> x * 2) (Some 5) in
  match doubled with
  | None   -> print_endline "nothing"
  | Some v -> Printf.printf "doubled: %d\n" v


(*
  =========================
  RECURSIVE VARIANTS -- BUILDING YOUR OWN LIST
  =========================

  OCaml's built-in list is ITSELF a variant type.
  Internally it looks like:

      type 'a list =
        | []
        | (::) of 'a * 'a list

  Let's build our OWN list type to understand this from scratch.
*)

type 'a my_list =
  | Empty
  | Cons of 'a * 'a my_list
(*           |    |
             |    +-- the REST of the list (same type -- recursive)
             +------- the VALUE at this node                       *)

(*
  WHY IS THIS RECURSIVE?

  Cons carries two things:
    1. A value of type 'a           (the current element)
    2. A value of type 'a my_list   (the rest -- also a my_list)

  Every Cons node points to another my_list.
  That next my_list is either another Cons, or Empty.
  Empty is the stopper -- it breaks the chain.

  WHY "Cons"?
  Short for "construct" -- inherited from Lisp (1958).
  OCaml's built-in :: IS cons, just with nicer syntax:

      1 :: [2; 3]                          <- built-in syntax
      Cons (1, Cons (2, Cons (3, Empty)))  <- what it means internally

  BUILDING [1; 2; 3] step by step:

    Cons (1, Cons (2, Cons (3, Empty)))

  MEMORY LAYOUT (conceptual):

    Cons(1, --->  Cons(2, --->  Cons(3, --->  Empty)
      |                |                |
      value=1          value=2          value=3

  Each Cons node is a small block on the HEAP:
    - the value
    - a pointer to the next node
*)

let my_numbers = Cons (1, Cons (2, Cons (3, Empty)))

let rec my_sum lst =
  match lst with
  | Empty        -> 0
  | Cons (x, xs) -> x + my_sum xs

(*
  Pattern Cons (x, xs):
    x  = the value in this node   (an int)
    xs = the rest of the list     (a my_list)

  Mirrors the structure exactly:
    Cons carries (value, rest)  ->  pattern extracts (x, xs)

  TRACE: my_sum (Cons(1, Cons(2, Cons(3, Empty))))

    Cons(1, rest) -> 1 + my_sum (Cons(2, Cons(3, Empty)))
    Cons(2, rest) -> 2 + my_sum (Cons(3, Empty))
    Cons(3, rest) -> 3 + my_sum Empty
    Empty         -> 0

    unwind: 3+0=3, 2+3=5, 1+5=6
    result: 6
*)

let rec my_sum_tail lst acc =
  match lst with
  | Empty        -> acc
  | Cons (x, xs) -> my_sum_tail xs (acc + x)

let my_sum_clean lst = my_sum_tail lst 0

let () =
  Printf.printf "my_sum       = %d\n" (my_sum my_numbers);
  Printf.printf "my_sum_clean = %d\n" (my_sum_clean my_numbers)


(*
  =========================
  COMBINING EVERYTHING: VARIANTS + TAIL RECURSION
  =========================

  Count only Circle shapes in a list, tail-recursively.

  Circle _ means "a Circle with ANY radius" -- _ ignores the value.
*)

let rec count_circles lst acc =
  match lst with
  | []             -> acc
  | Circle _ :: xs -> count_circles xs (acc + 1)
  | _ :: xs        -> count_circles xs acc

let count_c lst = count_circles lst 0

(*
  TRACE: count_c [Circle 1.0; Rectangle(2.0,3.0); Circle 4.0]

  Step 1: Circle _    -> acc = 0+1 = 1, recurse
  Step 2: Rectangle _ -> not a circle, acc stays 1, recurse
  Step 3: Circle _    -> acc = 1+1 = 2, recurse
  Step 4: []          -> return 2
*)

let shapes = [Circle 1.0; Rectangle (2.0, 3.0); Circle 4.0; Triangle (1.0, 1.0)]

let () =
  Printf.printf "Number of circles: %d\n" (count_c shapes)


(*
  =========================
  HIGHER-ORDER FUNCTIONS + OPTION: find_first
  =========================

  Goal: find the FIRST element matching a condition.
  Return Some element, or None if not found.

  This takes a PREDICATE as an argument --
  a function that returns bool.
  This is called a HIGHER-ORDER FUNCTION.

  WHY THIS MATTERS:
  Without higher-order functions you need a separate function
  for every possible condition:
      find_first_even
      find_first_greater_than_100
      find_first_starting_with_b  ...

  With a predicate argument, you write find_first ONCE
  and pass in whatever rule you need each time.
*)

let rec find_first pred lst =
  match lst with
  | []      -> None
  | x :: xs ->
      if pred x then Some x
      else find_first pred xs

(*
  PARTS:

  pred
    - a function passed in as an argument
    - type: 'a -> bool
    - you supply the rule; find_first does the searching

  if pred x then Some x
    - call pred with the current head element x
    - if true: wrap x in Some and return (stop recursing)

  else find_first pred xs
    - pred was false: x does not match
    - recurse on xs; pred is passed forward unchanged

  [] -> None
    - reached the end, nothing matched

  TRACE: find_first (fun x -> x mod 2 = 0) [1; 3; 4; 7; 8]

    x=1: 1 mod 2 = 1 <> 0 -> false -> recurse [3;4;7;8]
    x=3: 3 mod 2 = 1 <> 0 -> false -> recurse [4;7;8]
    x=4: 4 mod 2 = 0 = 0  -> true  -> return Some 4

  Result: Some 4

  TRACE: find_first (fun x -> x > 100) [1; 3; 4; 7; 8]

    x=1,3,4,7,8: all false -> []  -> return None

  Result: None
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
  Predicates work on ANY type, not just ints.
  w.[0] gets the first character of string w.
*)

let () =
  let words = ["apple"; "banana"; "cherry"; "blueberry"] in
  match find_first (fun w -> w.[0] = 'b') words with
  | None   -> print_endline "no word starting with b"
  | Some w -> Printf.printf "first b-word: %s\n" w

(*
  TRACE:
    w="apple":  'a' = 'b' -> false -> recurse
    w="banana": 'b' = 'b' -> true  -> return Some "banana"

  Result: Some "banana"
*)


(*
  =========================
  KEY TAKEAWAYS
  =========================

  TAIL RECURSION:
  - Normal recursion: pending work waits on the stack -> overflow risk
  - Tail recursion: result travels FORWARD in accumulator -> no overflow
  - OCaml reuses the stack frame when the call is in tail position
  - Pattern: add an acc argument, do computation BEFORE the recursive call

  STACK vs HEAP:
  - Stack: function frames, small (~1-8 MB), LIFO, fast
  - Heap: allocated values (lists, tuples, strings), larger, GC-managed
  - Deep recursion crashes the STACK (not the heap)

  VARIANTS:
  - Define types as "this OR that OR that..."
  - Carry data: Constructor of type  or  Constructor of t1 * t2
  - Pattern match to extract values
  - Compiler enforces exhaustiveness -- no forgotten cases at compile time

  OPTION TYPE:
  - Built-in variant: None | Some of 'a
  - Forces you to handle the "missing value" case
  - Cannot use an option value as a plain value -- must unwrap via match
  - Replaces null crashes from Python/JS with compile-time safety

  RECURSIVE TYPES:
  - Types can refer to themselves: Cons of 'a * 'a my_list
  - OCaml's built-in list IS a recursive variant internally
  - :: is just Cons with nicer syntax; [] is just Empty

  HIGHER-ORDER FUNCTIONS:
  - Functions can take other functions as arguments (predicates)
  - Write one general function instead of many specific ones
  - Functions are just values in OCaml
*)
