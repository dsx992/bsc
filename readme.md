# Project

ssd_os is an operating system for solid state drives (ssd) equipped with RISC-V
processors, that provides a synchronous and deterministic programming model. A
program is a collection of pipelines; each pipeline is a linear sequence of
stages that execute to completion within a tick, i.e., a fixed period of time.
Ideally, the programming toolchain verifies that a given stage can execute
within a tick. This requires a static analysis of the RISC-V assembly program
to reason about the deterministic nature of a stage or its worst-case execution
time. In this project, we base our approach on typed assembler program. We rely
on the assembly type system to reason about determinism or running time.
 
The intended learning outcomes of the project are:

- A survey of existing typed assembly languages (how they are defined and how
  they are used) and existing approaches to worst-case execution time and
  determinism analysis
- Explore possible properties that can be verified using a typed assembly
  language
- Design a typed version of (a subset of) the RISC-V assembly language
- Design, implement and evaluate a static analysis tool that verifies a chosen
  property of a program in typed RISC-V assembly.
