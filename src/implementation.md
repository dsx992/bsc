# TAL

## Coercion

It is important to be able to coerce memory from scratch/shared arrays to just
arrays.

If a register contains an address, then this should be able to be coerced into
either scratch or shared memory.

# abstract machine

Consists of memory and something that runs instructions -- here the pipeline.
Pipelines could be (from compsys) 5 way, 9 way out of order, whatever, what
have you.
May not be relevant.

As in DTAL paper, model as register, heap, stack; Split heap into scratch and
shared.

# Syntax

As Xi's DTAL however with

..
Type memory variable    μ
type memory             Μ := Scratch | Shared | Stack | μ
..
types                   τ := Μ τ array(x)

should Stack be a type constructor?

# semantics



## Memory

Memory is a function of some memory type to time.

In ssd\_os' case, this will be scratch and shared memory

```haskell
    class Memory a where
        read :: a -> Time
        write :: a -> Time

    data Mem = Scratch
             | Shared

    instance Memory (Mem m) where
        read Scratch = some time
        read Shared = some (probably longer) time
        write x = read x
```

In the general case where cashe may be involved, successive memory lookups may
influence the time of the succeeding lookups, this construction is not
sufficient.
NOTE: monads here?

## Pipeline

Taking a series of instructions, a pipeline is a function from `[i] -> Time`

# Parts

From TAL to time

## Lexer

Tokenize input

## Parse

Parse tokens into an abstract syntax tree

## wcet

Probably not the final name? Sum the AST where arithmethic instructions gets pipelined
