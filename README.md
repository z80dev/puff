# Huff, in Racket

Puff is an experimental Huff compiler implemented in Racket. It currently supports a small subset of full Huff functionality.

# Current Status

## Implemented

Pretty much everything not mentioned in the next section

## Not Implemented
- Custom constructors
- Functions (no plan on supporting these, functions in huff are kinda weird imo lol)
- Code/Jump Tables

# Usage

## Requirements

- Racket
- Rust

#### Installing Racket

``` sh
# macOS with Homebrew
brew install racket

# Arch/Manjaro
sudo pacman -S racket

# Ubuntu/Debian
sudo apt install racket

# Fedora
sudo dnf install racket
```

## Installation

After installing Racket and Rust, run:

``` sh
make install
```

This will run a [custom install script](install.rkt) which ensures the required Rust dependency is compiled and Racket libraries are installed. Then, it builds an executable and puts it in your PATH. The install script will prompt you for a directory where you want the `puffc` executable to live.

## Run

Compile one of the example contracts:

`puffc -b examples/add_two.huff`

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

## keccak library

Puff depends on the keccak implementation from [Alloy](https://github.com/alloy-rs/core). 

We need a tiny bit of Rust code to build a library we can call from Racket over FFI. This is all handled by the makefile.

This rust code is found under `rust_src`

