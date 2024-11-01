#lang racket

(require "../utils.rkt")

;; very simple. we start a counter at 0, and for each call to FREE_STORAGE_POINTER, we return the counter value then inc
;; values should be hex strings

(define counter 0)

(define (free-storage-pointer)
  (let ([result counter])
    (set! counter (+ counter 1))
    (list 'hex (number->hex result))))

(define (fsp-call? code)
  (eq? code "FREE_STORAGE_POINTER()"))

(define (handle-fsp-call code)
   (if (fsp-call? code)
       (free-storage-pointer)
       code))

(define (insert-fsp code)
  (map handle-fsp-call code))

(provide insert-fsp fsp-call? free-storage-pointer)