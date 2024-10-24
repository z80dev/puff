# Huff, in Racket

Puff is an experimental Huff compiler implemented in Racket. It currently supports a small subset of full Huff functionality.

# Current Status

Very early WIP!

## Implemented

Not much yet, but we can compile a basic contract that has a single MAIN macro, imports other files, and references constants.

- All opcodes
- `#define function` and `__FUNC_SIG`
- `#define error` and `__ERROR`
- `#define constant` and `[CONSTANT]` syntax for const references

## Not Implemented
- Calling macros/functions from Main
- Custom constructors
- Built-ins like __FUNC_SIG, etc.
- Lots of other stuff!

# Usage

## Requirements

- Racket
- Rust

### Racket Libs

- `threading-lib`
- `brag`

Install with:

`make install_racket_libs`

## Build keccak library

Puff depends on the keccak implementation from [Alloy](https://github.com/alloy-rs/core). 

We need a tiny bit of Rust code to build a library we can call from Racket over FFI. This is all handled by the makefile.

Clone the repository, then from its root, run:

`make deps`

## Run

Compile one of the example contracts:

`racket main.rkt -b examples/add_two.huff`

## [Optional] Compile executable

You can do this already with `raco exe main.rkt -o puffc` and then `raco distribute out puffc`. This gives you a directory (called `out`) containing an executable and the required lib. 

I then ran `ln -s /home/z80/dev/puff/out/bin/puffc /home/z80/.local/bin/puffc` to create a symlink in a directory that's in my path, so I can call puffc from anywhere.

I'll be automating this in some way but if you're interested, that's how you do it

# Technical Documentation

## Compiler Phases

The `compile-src` function illustrates the compilation pipeline

``` racket
(define (compile-src src)
  (~> src
      lex ;; src -> tokens
      parse ;; tokens -> syntax obj
      syntax->datum ;; syntax obj -> AST
      analyze-node ;; AST -> compiler data
      compile-program-data ;; compiler data -> bytes
      bytes->hex)) ;; bytes -> hex string
```

### Lexing

This happens in `puff/lexer.rkt`. In it we define some patterns we want to capture in the source code as specific tokens. This lets us have a much simpler and more explicit grammar. 

### Parsing

We use the `brag` language to define our grammar in `huffparser.rkt`. With this grammar definintion, we get a `parse` function anywhere just by importing `huffparser.rkt`.

### Analysis

We define various phases of analysis in `analysis.rkt`. In this file we do all the work required to go from an AST to a `compiler-data` struct, which is a struct meant to contain all the data required to actually compile a contract. The `compiler-data` object essentiallyu acts as an enhanced AST, all the same data is contained but with the ability to easily and quickly perform lookups on labels, constants, errors, events, etc.

### Compilation

This happens in `puff.rkt`, `codegen.rkt`, and all the phases under `puff/phases`. We coordinate the various steps in `puff.rkt` but most of the actual compilation logic is implemented in various handlers in `codegen.rkt ` and the `phases`.
