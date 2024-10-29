#lang racket/base


(require racket/list)
(require "../analysis.rkt")

(define (is-macro-call code data)
  (and (list? code)
       (eq? 'fncall (car code))
       (hash-has-key? data (cadr code))))

(define (is-macro-arg code)
  (and (list? code)
       (eq? 'macro-arg (car code))))

(define (insert-macro-args code data)
  (define (handle-macro-arg code)
    ;; (cadar '((1 2 3) 4 5)) = 2, i.e. second element of first element in list
    ;; (cadar '((macro-arg foo))) = 'foo
    (cons (hash-ref data (cadar code)) (insert-macro-args (cdr code) data)))
  (define (continue code)
    (cons (car code) (insert-macro-args (cdr code) data)))
  (cond
   ((empty? code) '())
   ((is-macro-arg (car code)) (handle-macro-arg code))
   (else (continue code))))

(define (get-macro-body code data)
  (let* ([name (cadr code)]
         [args (caddr code)]
         [macrodef (hash-ref data name)]
         [argsdef (car macrodef)]
         [argsmap (make-hash)])
    (for ([k (rest argsdef)]
          [v (rest args)])
      (hash-set! argsmap k v))
    (insert-macro-args (fourth macrodef) argsmap)))

; Helper function that processes a single code element
(define (insert-macro code data)
  (define (process-macro-element element rest-code data)
    (let ([macro-body (get-macro-body element data)]
          [remaining-code rest-code])
      (append macro-body remaining-code)))
  ; Handle base case - empty code returns empty
  (if (empty? code)
      code
      ; For non-empty code, analyze the first element
      (let ([first-element (car code)]
            [rest-code (cdr code)])

        (if (is-macro-call first-element data)
            ; If it's a macro call, expand it and continue processing
            (let ([expanded-code (process-macro-element first-element rest-code data)])
              ;; recursive call with expanded code
              (insert-macro expanded-code data))

            ; If it's not a macro, keep this first element and process the rest
            (cons first-element (insert-macro rest-code data))))))

(define (insert-macros code data)
  (insert-macro code (program-data-macros data)))

(provide insert-macros)
