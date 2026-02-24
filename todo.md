# todo

## Next:

read on 
    - TAL lit/tal-toplas.pdf
    - DTAL lit/OGI-CSE-99-008.pdf

Question: What is the system being run on?

---

- read up on risc v, especially stack.

- Dependently Typed Assembler Language (DTAL)

todo based on learning outcomes


- A survey of existing typed assembly languages (how they are defined and how
  they are used) and existing approaches to worst-case execution time and
  determinism analysis
    - TAL
    - explore wcet
- Explore possible properties that can be verified using a typed assembly
  language
    - Cache
        - liveness of pages could have an impact?
    - pipelines
- Design a typed version of (a subset of) the RISC-V assembly language
    - maybe integer arithmetic and some load and store
- Design, implement and evaluate a static analysis tool that verifies a chosen
  property of a program in typed RISC-V assembly.
    - I have a strong urge to do this in haskell. But I don't know haskell. So
      probably f#.


more concise

- TAL
- wcet
- cache
    - How does cache work with the `ssd_os` environment?
    - liveness analysis. I'm thinking dividing address space into pages and
      concider them each a variable and do normal liveness analysis on this
      (IPS)
      Is pages the right word here?
- pipelines
    - again, how is this implemented for `ssd_os`?
