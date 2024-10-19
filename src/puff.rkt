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

(define (compile-macro macro-data)
  (let ([args (macro-data-args macro-data)]
        [takes (macro-data-takes macro-data)]
        [returns (macro-data-returns macro-data)]
        [body  (macro-data-body macro-data)])
    (handle-tree body)))

;; replace all `(const-ref const) with the actual value of the constant from the hashmap
(define (handle-const-ref code constants)
  (match code
    [(list 'const-ref const)
     (handle-tree (hash-ref constants const))]
    [_ code]))

(define (make-const-handler constants)
  (lambda (code)
    (handle-const-ref code constants)))

(define (insert-constants code constants)
  (let* ([handler (make-const-handler constants)]
         [res  (map handler code)])
    (flatten res)))

(define (compile-program-data-runtime data)
  (let* ([main-macro (hash-ref (program-data-macros data) "MAIN")]
         [main-macro-data (make-macro-data main-macro)]
         [constants (program-data-constants data)]
         [compiled-macro (compile-macro main-macro-data)])
    (~> compiled-macro
        (insert-constants constants)
        assemble-opcodes)))

(define (compile-program-data data)
  (let* ([compiled-runtime (compile-program-data-runtime data)]
         [sz (byte-length compiled-runtime)]
         [initcode (generate-copy-constructor sz)]
         [assembled-initcode (assemble-opcodes initcode)])
    (append assembled-initcode compiled-runtime)))

(define (compile-src src)
  (~> src
      lex
      parse
      syntax->datum
      analyze-node
      compile-program-data
      bytes->hex))

(define (compile-src-runtime src)
  (~> src
      lex
      parse
      syntax->datum
      analyze-node
      compile-program-data-runtime
      bytes->hex))

(define (compile-filename filename)
  (~> filename
      file->string
      lex
      parse
      syntax->datum
      (analyze-node #f (hash 'filename filename))
      compile-program-data
      bytes->hex))

(define (compile-filename-runtime filename)
  (~> filename
      file->string
      lex
      parse
      syntax->datum
      (analyze-node #f (hash 'filename filename))
      compile-program-data-runtime
      bytes->hex))

(provide compile-filename compile-src compile-filename-runtime compile-src-runtime)
