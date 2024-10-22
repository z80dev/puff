#lang racket/base

(require racket/file
         racket/list
         racket/match
         threading
         "lexer.rkt"
         "huffparser.rkt"
         "huff-ops.rkt"
         "assembler.rkt"
         "keccak.rkt"
         "huff-ops.rkt"
         "utils.rkt"
         "codegen.rkt"
         "analysis.rkt")

(require "phases/constants.rkt")
(require "phases/funcsigs.rkt")
(require "phases/errors.rkt")
(require "phases/events.rkt")
(require "phases/hexvals.rkt")
(require "phases/opcodes.rkt")

; TODO: This makes a lot of passes over the code
; In the future, come up with a syntax that allows
; for combining passes, probably by returning handlers
(define (make-phases-pipeline data)
  (lambda~>
   (insert-constants data)
   (insert-hexvals data)
   (insert-funcsigs data)
   (insert-errorsigs data)
   (insert-eventsigs data)
   (insert-opcodes data)
   flatten))

(define (compile-program-data-runtime data)
  (let* ([main-macro (hash-ref (program-data-macros data) "MAIN")]
         [phases (make-phases-pipeline data)]
         [constants (program-data-constants data)])
    (~> main-macro
        fourth ;; fourth element is the macro body
        phases
        assemble-opcodes)))

(define (compile-program-data data)
  (let ([compiled-runtime (compile-program-data-runtime data)])
    (~> compiled-runtime
        byte-length
        generate-copy-constructor
        assemble-opcodes
        (append compiled-runtime))))

(define (compile-src src)
  (~> src
      lex
      parse
      syntax->datum
      analyze-node
      compile-program-data
      concat-hex))

(define (compile-src-runtime src)
  (~> src
      lex
      parse
      syntax->datum
      analyze-node
      compile-program-data-runtime
      concat-hex))

(define (compile-filename filename)
  (~> filename
      file->string
      lex
      parse
      syntax->datum
      (analyze-node #f (hash 'filename filename))
      compile-program-data
      concat-hex))

(define (compile-filename-runtime filename)
  (~> filename
      file->string
      lex
      parse
      syntax->datum
      (analyze-node #f (hash 'filename filename))
      compile-program-data-runtime
      concat-hex))

(provide compile-filename compile-src compile-filename-runtime compile-src-runtime)
