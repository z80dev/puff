#lang racket

(require "../codegen.rkt")

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

(provide insert-constants)
