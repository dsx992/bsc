# Tue Feb  3 09:49:36 AM CET 2026

## outcomes

Getting intuition and about typed assembly

## material

- types for dsp assembler programs

## notes

Dependently typed assembly language (DTAL) introduces expressions on integers
and arrays based on Presburger arithmetic.
Syntax is int(e) or array(e) where e is a presburger expression.

This index context is used to constraint the domain of variables.
> Does this mean memory lookup etc?

> Ken Friis skriver at presburger aritmetik inkluderer multiplikation, men der
> står eksplicit på wikipedia, at den ikke inkluderer multiplikation??


### Idea
DTAL can be used to ensure the size of an array, which is usable for estimating
the cost of cache (time)

Still a problem for a runtime n (perhaps from user input), but maybe the wcet
can output a function of n, in that case? That may be out of scope.

---

- _Type invariance of memory locations_ Type of data at memory location must
  not change during program evaluation.
> only during one scope, surely. Reallocated memory should not adhere to the
> prevously allocated datatype.

Kens DSP TAL uses a do-loop, which is super convenient for determining
runtimes. Is it even really possibly to statically determine WCET without this?
As in, just jumps and branches

If not using an explicit loop notation, how would I register a loop? Jumping to
earlier point in code in general?

If keeping to risc-v, a do-loop notation might just be illegal.
