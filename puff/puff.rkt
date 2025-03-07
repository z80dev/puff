#lang racket/base
;;; puff.rkt - Core compilation pipeline for the Puff compiler
;;;
;;; This file contains the main compilation pipeline for the Puff compiler.
;;; It orchestrates the transformation from Huff source code to EVM bytecode
;;; through a series of phases, including lexing, parsing, analysis,
;;; macro expansion, and bytecode generation.

(require racket/file
         racket/list
         racket/match
         threading
         "lexer.rkt"          ; Tokenization
         "huffparser.rkt"     ; Grammar parsing
         "huff-ops.rkt"       ; EVM operation definitions
         "assembler.rkt"      ; Bytecode assembly
         "keccak.rkt"         ; Keccak hash functions
         "huff-ops.rkt"       ; Duplicate import, can be removed
         "utils.rkt"          ; Common utilities
         "codegen.rkt"        ; Code generation utilities
         "analysis.rkt"       ; AST analysis
         "phases/phases.rkt") ; Compilation phases

;; TODO: This makes a lot of passes over the code
;; In the future, come up with a syntax that allows
;; for combining passes, probably by returning handlers
;;
;; make-phases-pipeline: program-data -> (code -> code)
;; Creates a compilation pipeline function that applies all transformation phases in sequence
;; The pipeline transforms the AST through various phases like macro expansion,
;; constant resolution, and opcode translation
(define (make-phases-pipeline data)
  (lambda~>
   (insert-macros data)        ; Replace macro calls with their bodies
   (insert-constants data)     ; Replace constant references with their values
   insert-fsp                  ; Handle free storage pointer references
   insert-hexvals              ; Convert hex literals to appropriate PUSH instructions
   (insert-funcsigs data)      ; Replace function signature references with their hashes
   (insert-errorsigs data)     ; Replace error signature references with their hashes
   (insert-eventsigs data)     ; Replace event signature references with their hashes
   insert-labels               ; Resolve jump labels with concrete offsets
   insert-opcodes              ; Convert opcode names to their byte values
   flatten))                   ; Flatten nested structures

;; compile-program-data-runtime: program-data -> bytecode
;; Compiles only the runtime code (MAIN macro) to bytecode
;; This excludes the contract deployment code (constructor)
(define (compile-program-data-runtime data)
  (let* ([main-macro (hash-ref (program-data-macros data) "MAIN")]
         [phases (make-phases-pipeline data)])
    (~> main-macro
        fourth ; Fourth element is the macro body
        phases
        assemble-opcodes)))

;; compile-program-data: program-data -> bytecode
;; Compiles a full contract including both constructor and runtime code
;; The constructor copies the runtime code to memory and returns it
(define (compile-program-data data)
  (let ([compiled-runtime (compile-program-data-runtime data)])
    (~> compiled-runtime
        byte-length
        generate-copy-constructor ; Create a constructor that copies runtime code to memory
        assemble-opcodes
        (append compiled-runtime)))) ; Join constructor and runtime code

;; compile-src: string -> string
;; Compiles Huff source code (as a string) to hexadecimal bytecode
;; This includes both constructor and runtime code
(define (compile-src src)
  (~> src
      lex                  ; Convert source to tokens
      parse                ; Parse tokens to AST
      syntax->datum        ; Convert syntax objects to plain data
      analyze-node         ; Build program-data structure
      compile-program-data ; Generate bytecode with constructor
      concat-hex))         ; Convert bytecode to hex string

;; compile-src-runtime: string -> string
;; Compiles Huff source code (as a string) to runtime bytecode only
;; This excludes the constructor code
(define (compile-src-runtime src)
  (~> src
      lex
      parse
      syntax->datum
      analyze-node
      compile-program-data-runtime ; Generate runtime bytecode only
      concat-hex))

;; compile-filename: string -> string
;; Compiles a Huff source file to hexadecimal bytecode
;; This includes both constructor and runtime code
(define (compile-filename filename)
  (~> filename
      file->string         ; Read the file contents
      lex
      parse
      syntax->datum
      (analyze-node #f (hash 'filename filename)) ; Track source filename for imports
      compile-program-data
      concat-hex))

;; compile-filename-runtime: string -> string
;; Compiles a Huff source file to runtime bytecode only
;; This excludes the constructor code
(define (compile-filename-runtime filename)
  (~> filename
      file->string
      lex
      parse
      syntax->datum
      (analyze-node #f (hash 'filename filename))
      compile-program-data-runtime
      concat-hex))

;; Exports the four main compilation functions:
;; - compile-filename: Compile file to full bytecode (constructor + runtime)
;; - compile-src: Compile source string to full bytecode (constructor + runtime)
;; - compile-filename-runtime: Compile file to runtime bytecode only
;; - compile-src-runtime: Compile source string to runtime bytecode only
(provide compile-filename compile-src compile-filename-runtime compile-src-runtime)
