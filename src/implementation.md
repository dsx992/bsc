# TAL

## Coercion

It is important to be able to coerce memory from scratch/shared arrays to just
arrays.

If a register contains an address, then this should be able to be coerced into
either scratch or shared memory.

# Syntax of TAL risc-v programs

    Program = Text
    Text    = Label Text
            | Insn Text
            | EOF

    Insn    := add rd, rs1, rs2
            | addi ...
    Reg     := ra | t0 | t1 ...

    Type    = int
            | float
            | Type array
    Op      = < | > | <= | >= | ==

    Label   = name: { Depend } [ Map ]
    Mapping = Map | Map, Mapping
    Map     = Reg: Type
            | Reg: Type(v)
    Depend  = Vars '|' Conds
    Var     = v: Type
    Vars    = Var | Var, Vars
    Cond    = v Op w
    Conds   = Cond | Cond, Conds

where `v` and `w` are values (constants?).

# abstract machine

Consists of memory and something that runs instructions -- here the pipeline.
Pipelines could be (from compsys) 5 way, 9 way out of order, whatever, what
have you.

As in DTAL paper, model as register, heap, stack; Split heap into scratch and
shared.


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
