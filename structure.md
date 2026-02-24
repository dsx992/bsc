# rapport

- Make an abstract machine to explain TAL (as the literature does) and use this
  as a starting point of Philippes memory banks

## intro

> Well-typed programs don't go wrong
Robin Milner

> Type systems for programming languages are a syntactic mechanism for
> enforcing abstraction
J. Reynolds

compare to SFI (software fault isolation)

## WCET

### What takes time?

- instructions
    - pipelines
- memory
    - bandwidth
    - cache misses
    - load/store
        - handling raw, war, waw (pmph)
            - they may block to not cause a race condition, right?
- function calls? Guessing
- Branch prediction
    - reachability?

## ssd\_os and the machines it runs on

- How expensive are ops, what kind of pipelining is used?
- cache. How many levels? How expensive is a miss?

## Exploration of TAL

### TAL-0 to TAL-4 (as literature describes them (Morrisett and derivatives))

### What is "typed"

- Asserting program state at label jump and memory access; i.e. what is the
  shape of the stack

### discussing syntax

- Formal
    - Maybe this should only come after TALs have been presented?

### TAL86

### DTAL

- Singleton types

## Possible properties of verification with TAL

- Assertions on function call types
    - correct types in registeres
    - correct stack frame memory layout (top of type t)
- instantiation of registers and memory
- Address ranges \*

## Getting from source language to TAL

## Getting from TAL to executable

## For RISC-V and WCET

Ken Friis describes an abstact machine (touring machine basically) with this
TAL, perhaps i should do something similar? Will make sense (or not) later,
when I look at riscv.

- subset of risc
    - not going to implement everything, so what is actually important for my
      purposes.
    - Look at ssd\_os; what do they require -- or what do I require to get a
      minimal working example.

### Constraints

    - Ken Friis uses a do-loop notation which is convenient, but only because
      his hardware supports it.
    - Some way to use DTAL asserts to constrain loops. Need some way to get out
      of endless loops. How to even register all loops?
        - maybe simply a "this is a loop" constraint. However, this is not
          really a type, so maybe it's out of scope?
        - Possibly just assert that there should be some counter and it should
          decrease or increase?
            - In that case, both prefix and postfix conditions for labels?
            -       label: {i : int(v), k : int(w) | pre(i) < post(i) | i reaches k}
                            [r0: int(i) ...
            - Not foolproof
    - What type of machine is it actually being run on?
    - Could loops be restricted to only iterate over arrays? In most cases,
      this is what a loop does, so why not have a label or dependency called
      "iterates over x".

### memory

- cache will probably play a big role, so how can TAL be used to make
  assertions or guesses on memory lookup?
    - Liveness analysis
        - Does TAL even matter here?
            - perhaps constraints on how much memory a label will use?
- stack is typed, too (per Ken friis dissertation), so something like 
  `sp : 't :: int array` denotes some element at the top of a stack (int just
  being the default) All types must have word size, i think.

## WCET analysis tool

### Working with

- I don't think it's realistic at all to make existing ssd\_os programs compile
  to my TAL. They might not even work with my subset. So these will be
  handwritten (perhaps chunks taken and modified from existing programs) in
  risc-v.
- Showcase working in qemu? Or should i prioritize real hardware?
    - The "weights" for cache misses and pipelines will probably differ, so
      tuning is needed. I.e., don't hardcode values.

Section on how compiling _could_ work? Closures etc.

- typed memory addresses?
    - using subtyping, the whole fast lane memory bank for a cpu can be one
      type, and any indexing can be a subtype of this
    - actually mentioned on slide 65 in lit/fritz/TAL-slides.pdf
    - Torbens PLDI region types
    - subranges
- let all label types return an upper bound execution time?

### Program

- I want to use haskell, but that might be unrealistic, so probably f#? It's
  good for parsing and compiler/interpreter work (IPS and PLD) which this kind
  of borders on.

## Limitations / shortcomings

From lit/tal-toplas.pdf

> Neither SPIN nor TAL can enforce other omportant security properties,
> such as termination, that do not follow from type safety

So there needs to be restrictions in how the programs are programmed to
disallow any infinite loops.
