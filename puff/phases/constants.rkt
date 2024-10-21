#lang racket

(require "../codegen.rkt")
(require "../analysis.rkt")

;; replace all `(const-ref const) with the actual value of the constant from the hashmap
(define (handle-const-ref code constants)
  (match code
    [(list 'const-ref const)
     (handle-tree (hash-ref constants const))]
    [_ code]))

(define (make-const-handler constants)
  (lambda (code)
    (handle-const-ref code constants)))

(define (insert-constants code data)
  (let* ([constants (program-data-constants data)]
         [handler (make-const-handler constants)]
         [res  (map handler code)])
    res))

(provide insert-constants)
