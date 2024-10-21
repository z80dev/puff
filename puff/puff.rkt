#lang racket
(require racket/list
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

(define (make-phases-pipeline data)
  (lambda~>
   (insert-constants data)
   (insert-funcsigs data)
   flatten))

(define (compile-macro macro-data)
  (let ([args (macro-data-args macro-data)]
        [takes (macro-data-takes macro-data)]
        [returns (macro-data-returns macro-data)]
        [body  (macro-data-body macro-data)])
    (handle-tree body)))

(define (compile-program-data-runtime data)
  (let* ([main-macro (hash-ref (program-data-macros data) "MAIN")]
         [phases (make-phases-pipeline data)]
         [constants (program-data-constants data)])
    (~> main-macro
        make-macro-data
        compile-macro
        phases
        assemble-opcodes)))

(define (compile-program-data data)
  (let* ([compiled-runtime (compile-program-data-runtime data)])
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
