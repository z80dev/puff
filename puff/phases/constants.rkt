#lang racket/base

(require "../codegen.rkt")
(require "../analysis.rkt")
(require racket/match)

;; replace all `(const-ref const) with the actual value of the constant from the hashmap
(define (handle-const-ref code constants)
  (match code
    [(list 'const-ref const)
     (hash-ref constants const)]
    [_ code]))

(define (make-handler constants)
  (lambda (code)
    (handle-const-ref code constants)))

(define (insert-constants code data)
  (let* ([constants (program-data-constants data)]
         [handler (make-handler constants)])
    (map handler code)))

(provide insert-constants)
