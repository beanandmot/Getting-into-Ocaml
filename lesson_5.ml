(*
  LESSON 5: List.map, List.filter, List.fold_left, and |>

  In lessons 3 and 4 you wrote recursive list functions by hand.
  Real OCaml code almost never does that.

  Instead it uses three stdlib functions that cover
  the vast majority of list operations:

    List.map        -- transform every element
    List.filter     -- keep elements that pass a test
    List.fold_left  -- reduce a list to a single value

  Plus one operator that makes chaining them clean:

    |>              -- the pipe operator

  By the end of this lesson you will:
  - Understand what each function does and why
  - See how they replace the hand-written recursion from lesson 4
  - Chain them together with |> to write clean, readable code

  Run everything on: https://ocaml.org/play
*)


(*
  =========================
  PART 1: List.map
  =========================

  WHAT IT DOES:
  Takes a function and a list.
  Applies the function to EVERY element.
  Returns a NEW list of the results.

  TYPE:
  List.map : ('a -> 'b) -> 'a list -> 'b list

  Read as:
    - takes a function from 'a to 'b
    - takes a list of 'a
    - returns a list of 'b

  'a and 'b can be the same type or different types.

  SYNTAX:
      List.map (fun x -> ...) my_list

  SIMPLE EXAMPLE:
*)

let nums = [1; 2; 3; 4; 5]

let doubled = List.map (fun x -> x * 2) nums

(*
  WHAT HAPPENS:

  List.map applies (fun x -> x * 2) to each element:

    1 -> 2
    2 -> 4
    3 -> 6
    4 -> 8
    5 -> 10

  Result: [2; 4; 6; 8; 10]

  Compare to the hand-written version from lesson 4:

      let rec double_list lst =
        match lst with
        | []      -> []
        | x :: xs -> (x * 2) :: double_list xs

  List.map replaces this entirely.
  You just describe WHAT to do to each element.
  The recursion is handled for you internally.
*)

let () =
  List.iter (fun x -> Printf.printf "%d " x) doubled;
  print_newline ()


(*
  EXAMPLE: different input and output types

  'a and 'b do NOT have to be the same type.
  Here we go from int list to string list.
*)

let as_strings = List.map (fun x -> string_of_int x) nums

(*
  1 -> "1"
  2 -> "2"
  3 -> "3"
  4 -> "4"
  5 -> "5"

  Result: ["1"; "2"; "3"; "4"; "5"]
*)

let () =
  List.iter (fun s -> Printf.printf "%s " s) as_strings;
  print_newline ()


(*
  EXAMPLE: map over a list of strings
*)

let words = ["hello"; "world"; "ocaml"]

let uppercased = List.map (fun w -> String.uppercase_ascii w) words

(*
  "hello" -> "HELLO"
  "world" -> "WORLD"
  "ocaml" -> "OCAML"

  Result: ["HELLO"; "WORLD"; "OCAML"]
*)

let () =
  List.iter (fun w -> Printf.printf "%s " w) uppercased;
  print_newline ()


(*
  EXAMPLE: map with a named function instead of anonymous

  You can pass any function, not just fun x -> ...
  As long as it has the right type.
*)

let add_one x = x + 1

let incremented = List.map add_one nums

(*
  Same as List.map (fun x -> x + 1) nums
  Just using a named function instead.

  Result: [2; 3; 4; 5; 6]
*)

let () =
  List.iter (fun x -> Printf.printf "%d " x) incremented;
  print_newline ()


(*
  HOW List.map WORKS INTERNALLY
  (you do not need to write this -- just understand it)

  let rec map f lst =
    match lst with
    | []      -> []
    | x :: xs -> f x :: map f xs

  It is the same hand-written recursion from lesson 4,
  just packaged into the standard library.

  KEY INSIGHT:
  map separates the STRUCTURE (iterate over a list)
  from the OPERATION (what to do to each element).

  You only need to supply the operation.
  The structure is always the same.
*)


(*
  =========================
  PART 2: List.filter
  =========================

  WHAT IT DOES:
  Takes a predicate (function returning bool) and a list.
  Returns a NEW list containing only elements where the predicate is true.

  TYPE:
  List.filter : ('a -> bool) -> 'a list -> 'a list

  Note: input and output are the same type.
  filter cannot change the type -- it only decides what to keep.

  SYNTAX:
      List.filter (fun x -> ...) my_list
*)

let evens = List.filter (fun x -> x mod 2 = 0) nums

(*
  WHAT HAPPENS:

  Apply (fun x -> x mod 2 = 0) to each element:

    1 -> false  (removed)
    2 -> true   (kept)
    3 -> false  (removed)
    4 -> true   (kept)
    5 -> false  (removed)

  Result: [2; 4]

  Compare to the hand-written version from lesson 4:

      let rec filter_even lst =
        match lst with
        | []      -> []
        | x :: xs ->
            if x mod 2 = 0 then x :: filter_even xs
            else filter_even xs

  List.filter replaces this entirely.
*)

let () =
  List.iter (fun x -> Printf.printf "%d " x) evens;
  print_newline ()


(*
  EXAMPLE: filter strings by length
*)

let long_words = List.filter (fun w -> String.length w > 4) words

(*
  "hello" -> length 5 -> true  (kept)
  "world" -> length 5 -> true  (kept)
  "ocaml" -> length 5 -> true  (kept)

  All kept here. Try with shorter words to see filtering:
*)

let mixed_words = ["hi"; "hello"; "ok"; "world"; "bye"; "ocaml"]

let long_only = List.filter (fun w -> String.length w > 3) mixed_words

(*
  "hi"    -> 2 -> false
  "hello" -> 5 -> true
  "ok"    -> 2 -> false
  "world" -> 5 -> true
  "bye"   -> 3 -> false
  "ocaml" -> 5 -> true

  Result: ["hello"; "world"; "ocaml"]
*)

let () =
  List.iter (fun w -> Printf.printf "%s " w) long_only;
  print_newline ()


(*
  HOW List.filter WORKS INTERNALLY:

  let rec filter pred lst =
    match lst with
    | []      -> []
    | x :: xs ->
        if pred x then x :: filter pred xs
        else filter pred xs

  Again -- the same hand-written recursion, packaged up.
*)


(*
  =========================
  PART 3: List.fold_left
  =========================

  WHAT IT DOES:
  Takes a function, a starting value (accumulator), and a list.
  Combines all elements into a SINGLE VALUE
  by repeatedly applying the function.

  This is the most powerful and most general of the three.
  Both map and filter can actually be implemented using fold.

  TYPE:
  List.fold_left : ('acc -> 'a -> 'acc) -> 'acc -> 'a list -> 'acc

  Read as:
    - takes a function: (accumulator, element) -> new accumulator
    - takes a starting accumulator value
    - takes a list
    - returns the final accumulator

  SYNTAX:
      List.fold_left (fun acc x -> ...) initial_value my_list

  THE MENTAL MODEL:

  Think of fold as starting with a value (acc)
  and "combining" each list element into it one by one.

  List.fold_left f init [a; b; c]
  is equivalent to:
      f (f (f init a) b) c

  It processes LEFT to RIGHT.
  Each step feeds the result into the next.
*)

(*
  EXAMPLE: sum a list
*)

let total = List.fold_left (fun acc x -> acc + x) 0 nums

(*
  TRACE: List.fold_left (fun acc x -> acc + x) 0 [1;2;3;4;5]

  Start: acc = 0

  Step 1: acc = 0 + 1 = 1
  Step 2: acc = 1 + 2 = 3
  Step 3: acc = 3 + 3 = 6
  Step 4: acc = 6 + 4 = 10
  Step 5: acc = 10 + 5 = 15

  Result: 15

  THIS IS THE SAME AS sum_tail FROM LESSON 4.

  Compare:

      let rec sum_tail lst acc =
        match lst with
        | []      -> acc
        | x :: xs -> sum_tail xs (acc + x)

  List.fold_left (fun acc x -> acc + x) 0 lst
  does exactly the same thing.
  The accumulator travels forward. It is tail recursive internally.
*)

let () =
  Printf.printf "total = %d\n" total


(*
  EXAMPLE: find the maximum value
*)

let numbers = [3; 1; 4; 1; 5; 9; 2; 6]

let maximum =
  match numbers with
  | []      -> failwith "empty list has no maximum"
  | x :: xs -> List.fold_left (fun acc n -> if n > acc then n else acc) x xs

(*
  We use the first element as the starting accumulator.
  Then fold compares each remaining element.

  TRACE: fold max over [3;1;4;1;5;9;2;6] starting with 3

  acc=3, n=1: 1 > 3? no  -> acc=3
  acc=3, n=4: 4 > 3? yes -> acc=4
  acc=4, n=1: 1 > 4? no  -> acc=4
  acc=4, n=5: 5 > 4? yes -> acc=5
  acc=5, n=9: 9 > 5? yes -> acc=9
  acc=9, n=2: 2 > 9? no  -> acc=9
  acc=9, n=6: 6 > 9? no  -> acc=9

  Result: 9
*)

let () =
  Printf.printf "maximum = %d\n" maximum


(*
  EXAMPLE: count elements matching a condition
  (fold can replace filter + length)
*)

let count_evens =
  List.fold_left (fun acc x -> if x mod 2 = 0 then acc + 1 else acc) 0 nums

(*
  TRACE over [1;2;3;4;5]:

  acc=0, x=1: odd  -> acc=0
  acc=0, x=2: even -> acc=1
  acc=1, x=3: odd  -> acc=1
  acc=1, x=4: even -> acc=2
  acc=2, x=5: odd  -> acc=2

  Result: 2
*)

let () =
  Printf.printf "count_evens = %d\n" count_evens


(*
  EXAMPLE: build a reversed list using fold
  (shows that acc does not have to be the same type as the input)

  Wait -- actually here acc IS a list and elements are ints.
  acc type: int list
  element type: int
*)

let reversed = List.fold_left (fun acc x -> x :: acc) [] nums

(*
  TRACE over [1;2;3;4;5]:

  acc=[],    x=1: 1::[]    = [1]
  acc=[1],   x=2: 2::[1]   = [2;1]
  acc=[2;1], x=3: 3::[2;1] = [3;2;1]
  ...
  Result: [5;4;3;2;1]

  This is the same as reverse_tail from lesson 4.
*)

let () =
  List.iter (fun x -> Printf.printf "%d " x) reversed;
  print_newline ()


(*
  HOW List.fold_left WORKS INTERNALLY:

  let rec fold_left f acc lst =
    match lst with
    | []      -> acc
    | x :: xs -> fold_left f (f acc x) xs

  Notice:
  - the recursive call is in TAIL POSITION
  - fold_left is tail recursive by design
  - safe on lists of any size

  KEY INSIGHT:
  fold is the most general operation.
  Any time you want to reduce a list to one value
  -- sum, max, count, concatenate, reverse --
  fold is the right tool.
*)


(*
  =========================
  MAP vs FILTER vs FOLD -- WHEN TO USE WHICH
  =========================

  map:
    - you want a list of the SAME LENGTH back
    - you are transforming each element
    - "convert every element"
    - input list: n elements -> output list: n elements

  filter:
    - you want a SUBSET of the list back
    - you are deciding what to keep
    - "keep only elements that satisfy a condition"
    - input list: n elements -> output list: 0 to n elements

  fold:
    - you want a SINGLE VALUE back (not a list)
    - you are combining elements into one result
    - "reduce the list to one thing"
    - input list: n elements -> output: one value

  QUICK REFERENCE:

      "double every number"          -> map
      "keep only positive numbers"   -> filter
      "sum all numbers"              -> fold
      "find the longest string"      -> fold
      "convert ints to strings"      -> map
      "remove duplicates"            -> fold (or filter with extra state)
      "count elements matching X"    -> fold (or filter + List.length)
*)


(*
  =========================
  PART 4: THE PIPE OPERATOR |>
  =========================

  WHAT IT DOES:
  Takes a value and passes it as the LAST argument
  to the function on the right.

  SYNTAX:
      value |> function

  IS EQUIVALENT TO:
      function value

  SIMPLE EXAMPLE:
*)

let result_a = [1;2;3;4;5] |> List.map (fun x -> x * 2)

(*
  This is identical to:
      List.map (fun x -> x * 2) [1;2;3;4;5]

  The list on the left gets passed as the last argument to List.map.

  On its own |> is not very useful.
  The power comes when CHAINING multiple operations.
*)


(*
  WITHOUT |>: nested calls (hard to read, inside-out)

  Read from innermost to outermost:
*)

let result_without_pipe =
  List.fold_left (fun acc x -> acc + x) 0
    (List.map (fun x -> x * 2)
      (List.filter (fun x -> x mod 2 = 0)
        [1;2;3;4;5;6]))

(*
  To understand this you have to read inside-out:
  1. start with [1;2;3;4;5;6]
  2. filter evens
  3. double each
  4. sum

  But it is written outermost first, so you have to
  scan all the way to the end to find the starting data.
  Confusing.
*)


(*
  WITH |>: left to right, reads like a pipeline (easy to read)
*)

let result_with_pipe =
  [1;2;3;4;5;6]
  |> List.filter (fun x -> x mod 2 = 0)
  |> List.map (fun x -> x * 2)
  |> List.fold_left (fun acc x -> acc + x) 0

(*
  Read top to bottom:
  1. start with [1;2;3;4;5;6]
  2. keep only evens        -> [2;4;6]
  3. double each            -> [4;8;12]
  4. sum                    -> 24

  Same computation. Much clearer.

  TRACE:


  result_with_pipe = 24
 *)

let () =
  Printf.printf "without pipe = %d\n" result_without_pipe;
  Printf.printf "with pipe    = %d\n" result_with_pipe


(*
  ANOTHER PIPE EXAMPLE: process a list of words
*)

let sentence = ["the"; "quick"; "brown"; "fox"; "jumped"]

let result_sentence =
  sentence
  |> List.filter (fun w -> String.length w > 3)
  |> List.map (fun w -> String.uppercase_ascii w)
  |> List.map (fun w -> w ^ "!")

(*
  TRACE:

  ["the"; "quick"; "brown"; "fox"; "jumped"]
  |> filter length > 3     -> ["quick"; "brown"; "jumped"]
  |> map uppercase         -> ["QUICK"; "BROWN"; "JUMPED"]
  |> map (add "!")         -> ["QUICK!"; "BROWN!"; "JUMPED!"]
*)

let () =
  List.iter (fun w -> Printf.printf "%s " w) result_sentence;
  print_newline ()


(*
  HOW |> IS DEFINED:

  let (|>) x f = f x

  That is all it is.
  x |> f   means   f x

  It is just a function that reverses the order of application.
  The power is entirely from readability and chaining.
*)


(*
  =========================
  COMBINING EVERYTHING: REAL EXAMPLES
  =========================

  These are the kinds of operations you will write in real OCaml.
*)


(*
  EXAMPLE 1: get the sum of squares of odd numbers
*)

let sum_of_odd_squares =
  [1;2;3;4;5;6;7;8;9;10]
  |> List.filter (fun x -> x mod 2 <> 0)    (* keep odds: [1;3;5;7;9] *)
  |> List.map (fun x -> x * x)              (* square each: [1;9;25;49;81] *)
  |> List.fold_left (fun acc x -> acc + x) 0 (* sum: 165 *)

let () =
  Printf.printf "sum of odd squares = %d\n" sum_of_odd_squares


(*
  EXAMPLE 2: find lengths of words longer than 4 characters
*)

let word_lengths =
  ["cat"; "elephant"; "dog"; "rhinoceros"; "ant"; "hippopotamus"]
  |> List.filter (fun w -> String.length w > 4)
  |> List.map (fun w -> (w, String.length w))

(*
  TRACE:

  filter length > 4   -> ["elephant"; "rhinoceros"; "hippopotamus"]
  map to (word, len)  -> [("elephant",8); ("rhinoceros",10); ("hippopotamus",12)]

  Note: map can return TUPLES.
  The output type here is (string * int) list.
*)

let () =
  List.iter
    (fun (w, n) -> Printf.printf "%s: %d\n" w n)
    word_lengths


(*
  EXAMPLE 3: count how many numbers are above average
*)

let data = [4; 7; 2; 9; 1; 5; 8; 3; 6]

let above_average_count =
  let total = List.fold_left (fun acc x -> acc + x) 0 data in
  let avg   = total / List.length data in
  data
  |> List.filter (fun x -> x > avg)
  |> List.length

(*
  total = 45
  avg   = 45 / 9 = 5

  filter x > 5  -> [7; 9; 8; 6]
  length        -> 4
*)

let () =
  Printf.printf "above average count = %d\n" above_average_count


(*
  =========================
  TRICKY EXAMPLE: fold to build a map of word frequencies
  =========================

  This one is harder -- it shows fold working on a more
  complex accumulator (a list of pairs).

  Goal: count how many times each word appears.

  Input:  ["a"; "b"; "a"; "c"; "b"; "a"]
  Output: [("a", 3); ("b", 2); ("c", 1)]
*)

let words_input = ["a"; "b"; "a"; "c"; "b"; "a"]

let increment_or_add acc word =
  (*
    Look through acc for an entry matching word.
    If found: increment count.
    If not found: add (word, 1).
  *)
  if List.exists (fun (w, _) -> w = word) acc then
    List.map (fun (w, n) -> if w = word then (w, n + 1) else (w, n)) acc
  else
    acc @ [(word, 1)]

let word_freq =
  List.fold_left increment_or_add [] words_input

(*
  TRACE:

  acc=[],                    word="a" -> not found -> [("a",1)]
  acc=[("a",1)],             word="b" -> not found -> [("a",1);("b",1)]
  acc=[("a",1);("b",1)],     word="a" -> found     -> [("a",2);("b",1)]
  acc=[("a",2);("b",1)],     word="c" -> not found -> [("a",2);("b",1);("c",1)]
  acc=...,                   word="b" -> found     -> [("a",2);("b",2);("c",1)]
  acc=...,                   word="a" -> found     -> [("a",3);("b",2);("c",1)]

  Result: [("a",3); ("b",2); ("c",1)]

  NOTE: List.exists checks if ANY element satisfies a predicate.
  It is another useful stdlib function.
*)

let () =
  List.iter
    (fun (w, n) -> Printf.printf "%s: %d\n" w n)
    word_freq


(*
  =========================
  KEY TAKEAWAYS
  =========================

  List.map:
  - transform every element
  - returns a list of the same length
  - type: ('a -> 'b) -> 'a list -> 'b list

  List.filter:
  - keep elements that pass a test
  - returns a subset of the original list
  - type: ('a -> bool) -> 'a list -> 'a list

  List.fold_left:
  - reduce a list to a single value
  - most general: map and filter can be written using fold
  - type: ('acc -> 'a -> 'acc) -> 'acc -> 'a list -> 'acc
  - always tail recursive, safe on large lists
  - starting value matters: 0 for sum, 1 for product, [] for list building

  |> (pipe):
  - passes value on left as last argument to function on right
  - defined as: let (|>) x f = f x
  - no new computation -- purely about readability
  - lets you write pipelines left-to-right instead of inside-out

  WHEN WRITING REAL OCAML:
  - reach for map / filter / fold before writing manual recursion
  - use |> whenever you are chaining 2 or more operations
  - fold covers anything map and filter do not

  WHAT YOU CAN NOW READ:
  Any OCaml code that processes lists -- which is most OCaml code.
*)
