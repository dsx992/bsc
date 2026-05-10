# Usecase

The goal of using typed assembly for wcet is twofold
- typed memory (scratch/shared) for load/save instructions to statically
  determine how many cycles the instruction will take (different memory takes
  different cycles)
- Control flow
  The language can make the halting problem decidable by only allowing well
  typed programs where branches are well defined in the index context.

# stacks and arrays

The memory region allocated stacks expand into high address ranges, while the
risc-v stack expands into lower addresses.
However, the region stacks are already fully allocated, so "allocation" really
just spits out the tail of the stack.

```c
uint8_t *arena_alloc(struct arena_allocator *alloc, size_t size, size_t alignment)
{
    uint8_t *free_region_start = alloc->region.start + alloc->allocated;
    const size_t alignment_padding =
            (alignment - (((size_t) free_region_start) % alignment)) %
            alignment;
    const size_t size_to_alloc = size + alignment_padding;

    const size_t remaining =
            (alloc->region.start + alloc->region.size) - free_region_start;

    if (remaining < size_to_alloc)
        return NULL;

    uint8_t *allocated = free_region_start + alignment_padding;
    alloc->allocated += size_to_alloc;
    return allocated;
}
```

for an arena initialized as
```c
struct arena_allocator arena =
{
    .region =
    {
        .start = SCRATCH,
        .size = 0x2000
    },
    .allocated = 0
};
```
start will have the stack type of the entire region that `SCRATCH` points to,
regardless of the size.

an allocation then returns a pointer with the same type as `.start +
.allocated`, essentially the nth tail of the region.

To get an array of a certain size, then first must be the "tail-stack" coerced
into a smaller stack of appropriate size.
This will be done with a coercion judgment, basically

    [t0 :: .. tn] <= [t0 :: .. tn :: r]

note: only allow word size types. This is what TAL is presented with, and it
makes everything simpler. God knows I need that.

then we can coerce into the array type iff all t0 .. tn are the same type.

Then types should be able to be lifted into regions, where every type but stack
type and arrays evaluate to themselves. () like the R^ in tal-0.

    region type variable    ::= ρ
    region type rt          ::= scratch | shared | ρ
    lifted                  ::= rt τ | rt stacktype

initialize stack variables as `top` which can be coerced into any type, such
that casting to an array of any type is trivial (given the right size)

if `rs` contains a stack of type `'r` and wordsize is 4 bytes, then

            subi        rd, rs, 8
    coerce1: [rd: top :: top :: []]
    coerce2: [rd: int :: int :: []]
    coerce3: [rd: int array(2)]

sets the type of `rd` to `top :: top :: 'r`, where `top` gets coerced into
integers, and then finally coerced into an array of some size.

for functionality, the stack should be lifted into region type, so if `rs`
contains `shared 'r` then

            subi        rd, rs, 8
    coerce1: [rd: sractch(top :: top :: [])]
    coerce2: [rd: scratch(int :: int :: [])]
    coerce3: [rd: scratch(int array(2))]


how can i restrict the type system to disallow arrays and stacks to exist in a
non lifted way?

---


# idea (no)

Using dependent types 

# specification

    Block ::= \Δ.\Φ.\((Σ, I), (Σ', I'))

is a function of a typevariable context, index context and two pairs of type
states and instructions; the entry and the transition.

observation: modelling stack frame such as `[s0: int(n) :: int array(m) :: 'r]`
highlights an issue with my array representation. Is the array in place, as in,
does s0 refer to 1 + m integers followed by 'r, or does it refer to an integer
and a pointer to an array?

To distinguish between these two, I will extend types with pointer(τ), maybe
notated as *(τ)?
In this pointer I will encode what type of memory it resides in, such as
scratch or shared. Μ ptr(τ)

What are the rules for instructions in transitions?
- if an instruction changes the type of a variable, then it is killed in the
  transition.
  - for practicality, it is only killed _after_ the instruction, so `mv t0, t0`
    is valid.
- Registers can only be read if they have not yet been killed.

A consequence of this is that the instructions

    lw      a4, -24(s0)
    slli    a4, a4, 1

where -24(s0) is of type `int(n)` needs to be split into two blocks.

    L0:     (n)
            {n: int}
            [s0: int(n) :: []]
            ->
            [a4: int(n), s0: int(n) :: []]
            lw      a4, -24(s0)

    L1:     (n)
            {n: int}
            [a4: int(n), s0: int(n) :: []]
            ->
            [a4: int(n * 2), s0: int(n) :: []]
            slli    a4, a4, 1

# example typing riscv code from p. 149 in computer organization and design

They don't use ABI names :(
I added the `clear` label

    clear:  (n, i)
            {n: nat, i: nat | i < n}
            [x10: ptr(int array(n))]
            addi    x5, x0, 0       ; i = 0
    loop:   (n, i)
            {n: nat, i: int | 0 <= i < n}
            [x10: ptr(int array(n)), x5: int(i)]
            ->
            [x10: ptr(int array(n)), x5: int(i), x6: int(i * 4)]
            slli    x6, x5, 2       ; x6 = i * 4
            add     x7, x10, x6

if type states are only used within the transition, they need not be explicitly
typed.

ptr is NOT necessary because i confused types with stack types.

coming full circle.. transitions are not needed, as with enough initial type
information, type transitions can be inferred within a block, so the wcet tool
should always be able to know the type of registers and stack.

instructions are also type state constructors, so

            addi    x5, x0, 0       ; i = 0

modifies type state Σ regfile type R so R[x5: int(x0 + 0)]

when it hits `loop`, type variables `n` and `i` will have to be unified with
the current type state (directed graph).
Maybe this can be done with hinley-milner? Will have to be done for all edges.
example on `x5` (repeated for all registers, saving the unified states):

`clear` will have implied the type from addi and `x0`. `x0` will always have
`x0: int(0)`, and `addi` should produce a type of int(r, imm) which will have a
rule producing `int(x + y)`.
    
    int(i) = int(x0 + 0)    (same type constructor)
        i = x0 + 0

then these are both index expressions and will have to be evaluated within the
contexts of the index context.

    Φ = n: 

[!note]
the literature does not make this clear, but I think that for subset sorts 
`{a : γ | P}` `a` is a type variable defined locally makes sense.
so evaluation with index context Φ will evaluate P on `Φ[a: γ]`.


# only do scratch/shared

the chosen property will be calculating runtime of a flat (no control flow, or
conditional branches).
program with two memory regions.

    main:   (r, rt)
            [sp: r, ra: rt, s0: ft]
	        addi	sp, sp, -32
	        sw	    ra, 28(sp)      ; [sp: t1 :: t2 :: .. :: t7 :: rt :: r]
	        sw	    s0, 24(sp)      
	        addi	s0, sp, 32

            addi    a1, zero, 1     ; creates fresh type variable a : int and modifies R[a1: int(a)]
            addi    a2, zero, 2     ; likewise
            addi    a3, zero, 3     
            addi    a4, zero, 4

            sw ...

            mv      a0, sp
            addi    a1, zero, 4

            ; ends with:
            ; [ sp: int(1) :: int(2) :: int(3) :: int(4) :: t5 :: t6 :: ft :: rt :: r
            ; , s0: r
            ; , a0: ..]


    L0:     (mt, n)
            {n: int | n > 0}    ; this will not be implemented
            [a0: mt int array(n), a1: int(n)]

            jr ra

# simple but not complete approach

memory allocation in the system is just offsetting a pointer through program
specific allocator functions.
if this works like malloc, then it should spit out an address to the start of a
`size` block. For this system, it implies the existence of a 

    // pseudo instruction for scratch malloc where .SCRATCH is the current top
    // of the scratch stack, initialized to the address of the start of the
    // region and rs contains the # bytes to allocate and returns (in rd) the
    // start of the allocated block.
    // the stack grows from low values to high values
    scr.malloc      rd, rs
        lw      rd, 0(.SCRATCH)
        add     rd, rd, rs
        sw      rd, 0(.SCRATCH)
        sub     rd, rd, rs

if the two memory regions had a reserved register (saved registers), say saved
scratch `sc` is `s2`, then

    scr.malloc      rd, rs
        mv      rd, sc
        add     sc, sc, rs

and if instead the stack grows from high to low values like the stack in risc-v
does, then malloc could simply move the head, and `sc` would be the start of
the new block as well

    scr.malloc      rs
        sub     sc, sc, rs

so code would look like

    addi    a4, zero, 16
    scr.malloc  a4
    addi    a1, zero, 1
    addi    a2, zero, 2
    addi    a3, zero, 3
    addi    a4, zero, 4
    lw      a1, 0(sc)
    lw      a2, 4(sc)
    lw      a3, 8(sc)
    lw      a4, 12(sc)

update: allocation goes through arenas which are structs blah blah discord
conversation given an arena
    
    scratch_arena:
        .word	4096        ; start
        .word	8192        ; size
        .word	0           ; allocated

    scr.malloc[γ]   rd, rs
        lui     rd, %hi(scratch_arena)
        addi    rd, %lo(scratch_arena)
        lw      rd, 8(rd)
        add     rd, rd, rs
        

it is somewhat yucky that `scr.malloc` does not return a pointer. It also makes
type instantiation weird, since it would only instantiate `sc` as a really long
stack type.

`scr.malloc rd rs` using two instructions is the way to go.
As in OGI, newarray contains a type signature, which is really needed to create
a valid type.
The only information I need is index sort γ, such that i can write either
`scr.malloc[int]  rd, rs` or `scr.malloc[{a: γ | P}]` which creates ``


- needs a way to instantiate memory types, i.e. pseudo instructions.

say `.SCRATCH` and `.SHARED` are defined values, then



---

# Memory Syntax

## Example TAL scan routine (addition).

For TAL to be at all usable, the type (or depndent type) needs to hold
throughout the whole block.

```asm
scan: ('mt, n) {n: nat} [a1: 'mt int array(n), a2: int(n)]
        muli    a2, a2, 4
        mv      a3, zero        ; counter
        ; malloc  a0, a2          ; not real risc-v, but typechecker needs to know that some instructios update type state
        jmp     loop

loop: ('mt, n, m) {n: nat, m: nat | m < n * 4} [a1: 'mt int array(n), a2: int(n), a3: int(m)]
        sub     t0, a2, a3
        subi    t0, 4
        bez     t0, end         ; a3 is last elm

        add     t1, a1, a3      ; &A[i]
        lw      t3, 0(t1)       ; A[i]
        addi    a3, a3, 4       ; i++
        add     t2, a1, a3
        lw      t4, 0(t1)
        add     t4, t4, t3

        sw      t4, 0(t2)

        j       loop
end:
```

* `nat` is a shorthand defined in OGI, this needs to be implemented or rewritten
* When an instruction effects some type, this needs to be picked up by the type
  checker. It would be annoying (and error prone) for the programmer to
  manually tell the typechecker when some instruction sets or changes the type
  of a register, so **the typechecker needs to know which instructions change
  type state**
  This would require recompiling malloc, so I don't know how this should be
  accomplished.
* Previous point showcases a problem with this approach, as it really renders
  the assertions pointless. If instructions can change the type state, then
  there is really no reason to have the assertions at all.
  Instead the register types should be immutable under a block.
  (If type state is immutable, the typechecker may still want to actually check
  the types.)
  Then the question becomes 'how to change state?'.
* managing loops by considering a graph of blocks, and iterations by encoding
  the condition

        scan
          |
          | (T)
          v (t0 == 0)
      --loop---> end
      |  ^ (T)
      ---|
Then we have to prove that t0 becomes zero before the branch.

    sub     t0, a2, a3
    subi    t0, 4

which becomes $a2 - a3 -4 = 0$

    muli    a2, a2, 4

a2 is a factor of 4, but otherwise we know nothing, except (from TAL) that it
is non-negative.

    mv      a3, zero        ; counter
    ...
    (bez)
    ...
    addi    a3, a3, 4       ; i++

a3 starts from zero and then increases by 4.

from this we can informally say that it will terminate at some point, but this
should be generalized and formalized.

### Type state transformation

still lacking a way to go from one state to another

garbage value?

    state1: [a1: int]
            addi        a1, a1, 1
    _trans: [a1: int :> int array]       ; prefix _ to denote not real label *
            newarray        a1

    state2: ['m int array]

* perhaps anonymous labels?

Idea: if a register is not present in a type environment, then it may only be
assigned to
    
    malloc: [a1: out blah blah]

    state1: [a1: int]
            addi        a1, a1, 1
    _trans: []          ; loses information for type safety? no matter, because it is overridden (so whatever value is dead)
            call        malloc  ; needs to check that this gives 'm int array

    state2: ['m int array]

### Solution

A block consists of a -label- with type information, a possibly empty sequence of
instructions, and a transformation of `mv` instructions.

It may be better to define transformations not as a tail, but those
instructions in the block that kills a register (reference ips ch. 8.1)

- (something about IPS liveness and overwriting variables kills them)
- dependent types may be transformed by arithmetic instructions, don't yet know
  how to handle this.
and possibly empty sequence of branch instructions.

        sum:    ('n, 'm, 'k, 'mt)
                {'n: nat, 'm: nat | 'm < 'n, 'k : int}
                [a0: 'mt int array('n), a1: int('n)]
                ->
                [a0: 'mt int array('n), a1: int('n), t0: int('m), t1: int('k)]
                mv      t0, zero    ; init i
                mv      t1, zero    ; init accumulator
                j       loop
            
        loop:   ('n, 'm, 'mt)
                {'n: nat, 'm: nat | 'm < 'n, 'k: int}
                [a0: 'mt int array('n), a1: int('n), t0: int('m), t1: int('k)]

        incr:   ('n, 'm, 'mt)           ; changed to leq
                {'n: nat, 'm: nat | 'm <= 'n, 'k: int}
                [a0: 'mt int array('n), a1: int('n), t0: int('m), t1: int('k)]
                ->
                [a0: 'mt int array('n), a1: int('n), t0: int('m + 1), t1: int('k)]

##### Abstract representation

    Block ::= \Δ.\Φ.\((Σ, I), (Σ', I'))

is a function of a typevariable context, index context and two pairs of type
states and instructions; the body and the transition.

Only I' can branch, and only after all type transformations have been executed.
Type transformations are `mv` instructions.
This can be extended to include arithmetic instructions, so we can encode
And `sw` for stack..

        loop:   ('n, 'i, 'k, 'mt)
                {'n: nat, 'i: nat | 'i < 'n, 'k: int}
                [t0: 'mt int array('n), t0: int('i), t2: int('k)]
                ->
                [t0: 'mt int array('n), t0: int('i + 1), t2: int('k)]

I can only contain `mv` instructions if the two registers are the same type.
Arithmetic operations are only permitted on registers containing the same types.

An observation is that bodies can contain no instructions, as
- branching could violate the transition
- arithmetic operations would violate dependent types such as `int(n)`
    - types such as just `int` -- or rather ∃a: int.int(a) (∃a: γ.τ) are safe
      (given that the other operands are of same type), however this is an
      annoying distinction and the following is a cleaner approach
- load and store can change type of registers and stack, respectively.

###### better approach (tentative, this may also be ass)

observation: modelling stack frame such as `[s0: int(n) :: int array(m) :: 'r]`
highlights an issue with my array representation. Is the array in place, as in,
does s0 refer to 1 + m integers followed by 'r, or does it refer to an integer
and a pointer to an array?

To distinguish between these two, I will extend types with pointer(τ), maybe
notated as *(τ)?
In this pointer I will encode what type of memory it resides in, such as
scratch or shared. Μ ptr(τ)

What are the rules for instructions in transitions?
- if an instruction changes the type of a variable, then it is killed in the
  transition.
  - for practicality, it is only killed _after_ the instruction, so `mv t0, t0`
    is valid.
- Registers can only be read if they have not yet been killed.

A consequence of this is that the instructions

    lw      a4, -24(s0)
    slli    a4, a4, 1

where -24(s0) is of type `int(n)` needs to be split into two blocks.

    L0:     (n)
            {n: int}
            [s0: int(n) :: []]
            ->
            [a4: int(n), s0: int(n) :: []]
            lw      a4, -24(s0)

    L1:     (n)
            {n: int}
            [a4: int(n), s0: int(n) :: []]
            ->
            [a4: int(n * 2), s0: int(n) :: []]
            slli    a4, a4, 1

The stackframe `s0` contains only one integer

I note here that if one keeps going in this direction, then you end up not
needing types at all, and just do analysis.

The proper mental model is then two type states Σ and Σ' being the entry state
and the transition state. The entry state need only hold immediately before the
block, while 


    sum =
        \['n, 'm, 'k, 'mt]      // lambda type variable contexts
        // 'mt is a memory type variable, only type variables are present in index contexts
        \['n: {'n: int | 0 <= 'n}, 'n: {'n: int | 0 <= 'n}, 'm < 'n, 'k: int]
        (
            // Body
            (
                // Sigma
                (
                    // R
                    [
                        a0: 'mt (Exists a: int.int(a)) array('n),
                        a1: int('n)
                    ]
                    // S
                    ρ
                ),
                // I
                []
            ),
            // Transitions
            (

            )
        )

---

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
