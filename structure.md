All thesis with me have a variant of the following structure:

1. Introduction

Context - what the thesis is about
Problem - the specific problem you focus on
Approach - experimental, designing/implementing/evaluating a system
Contribution - an itemized list of what you have done

[Part 1 - "What others have done"]

2. Background

Any existing work (system, prog. language, algorithm) relevant to what you have
done

3. Related Work

Existing work focusing on the same problem as you do.


[Part 2 - "What you have done"]

4*. Requirements

A specification of the functional and non-functional requirements (performance,
security, availability, ...) for your system, derived from an in-depth analysis
of the problem definition. Note that requirements might be part of the Problem
subsection of the introduction and may not require a full section.

5. Design

A description of the architecture of your system (interfaces and internal
components with their relationships).

A description of the design space (various options throughout the design of
your system, described and compared), and of the design choices (which options
you leave out, which options you decide to consider for your implementation and
why (e.g., pros and cons)).

6*. Implementation

A description of the interesting aspects of the implementation. The parts you
are proud of because they were hard, or because you came up with elegant
solutions. This may be reduced to a subsection under Design.

7. Evaluation

The test of your system, convincing your readers, that you fulfilled the
functional requirements.

The evaluation of your system based on the non-functional requirements. The
evaluation is experimental.

You need to describe (i) the experimental framework, i.e., (a) the system under
test (with the system parameters and possibly various design options described
in 5), (b) the workload (i.e., the input of your system), (c) the metrics (what
you measure), and (d) experiments (varying one system parameter or workload at
a time).

Experimental results. For each experiment, you should describe what you expect,
what you observe and how you explain what you observe.

8. Conclusion and Future work

Note: Part 1 and Part 2 are not part of your Table of Contents. Just a logical
separation in your document. You should never mix what others have done and
what you have done.
 
Note: In a BSc/MSc thesis, you might want to include a summary/discussion
subsection at the end of each section to summarize what you have achieved in
the section and look forward to what is going to happen/be described in the
next section.


---


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

### Problems with cache (in modern systems)

- Possibly use no cache at all (this is the way i'm going)
- Still, how could TAL be used for WCET analysis in cache systems?

## ssd\_os and the machines it runs on

- How expensive are ops, what kind of pipelining is used?
- cache. How many levels? How expensive is a miss?

## Exploration of TAL

### TAL-0 to TAL-4 (as literature describes them (Morrisett and derivatives))

#### Preservation of types (tal-0)

### What is "typed"

- Asserting program state at label jump and memory access; i.e. what is the
  shape of the stack

### discussing syntax

- Formal
    - Maybe this should only come after TALs have been presented?

### TAL86

### DTAL

- Singleton types

they call `int array(n)` a "type index expression". This could be extended with
scratch/shared, so the productions

    e ::= scratch e
        | shared e

to give, e.g., `shared int array(n)`, being an int array of size n in shared
memory.

alternatively one could consider `int array(n)` as also the pointer to the
array, and use bounds checks to assert that it is within bounds of the scratch
or shared memory. This is more verbose, and it requires to somewhat think
differently of th etype index expressions, so I am not confident it is a good
idea.

Type index expressions are themselves typed, but to avoid confusion they refer
to them as sorts.


### TALT (TAL two)

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

PLDI mentions types of loops. This could be an important distinctuion for what
kind of loops I want to permit.

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

### Why focus on memory

From the bsc tool, the process is quite simple, and does not take into account
pipelines and is generally very simplistic in regards to instruction times.

The focus lies in memory time (thankfully the abstract machine in question also
has a simple memory layout), which is - on an instruction basis - the slowest
and most varying part. The biggest bottleneck.
"The DRAM access time is one to two orers of magnitude longer thanthe processor
cycle time (tens of nanoseconds, compared to less than one nanosecond)"
[digital design \& computer architecture, ch. 8]

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

#### Implicitly dependently typed assembly

- Memory can be typed, and lookups will have some subtype of either high or
  lowspeed memory. This information can be carried with the code.

proof carrying code => (worst-case execution) time carrying types

- Maybe this works for caches, too? As well as liveness analysis of pages

- Bounded polymorphism

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
