#lang racket/base

(require racket/list)
(require "../analysis.rkt")

(define (is-macro-call code data)
  (and (list? code)
       (eq? 'fncall (first code))
       (hash-has-key? data (second code))))

(define (is-macro-arg code)
  (and (list? code)
       (eq? 'macro-arg (first code))))

(define (fncall? code)
  (and (list? code)
       (eq? 'fncall (first code))))

;; iterate over every element in code
;; if its a '(macro-arg foo) then replace it with the value of foo
(define (insert-args-from-data code data)
  (define (replace-arg element)
    (if (is-macro-arg element)
        (hash-ref data (second element))
        element))
  (map replace-arg code))

(define (insert-macroargs-to-fncall fncall data)
  (list 'fncall (second fncall) (insert-args-from-data (third fncall) data)))

(define (insert-macro-args code data)
  ;; just calls self with rest of the code
  (define (recurse)
    (insert-macro-args (rest code) data))

  ;; this leaves the first element unmodified and recurses
  (define (continue code)
    (cons (first code) (recurse)))

  ;; cons the value of the macro arg with the rest of the code
  (define (handle-macro-arg code)
    ;; (cadar '((1 2 3) 4 5)) = 2, i.e. second element of first element in list
    ;; (cadar '((macro-arg foo))) = 'foo
    (cons (hash-ref data (cadar code)) (recurse)))

  (define (handle-fncall node)
    (cons (insert-macroargs-to-fncall node data) (recurse)))

  ;; here we handle the base case, the macro-arg case, or continue
  (cond
   ((empty? code) '())
   ((fncall? (first code)) (handle-fncall (first code)))
   ((is-macro-arg (first code)) (handle-macro-arg code))
   (else (continue code))))

(define (get-macro-body code data)
  (let* ([name (second code)]
         [args (third code)]
         [macrodef (hash-ref data name)]
         [argsdef (first macrodef)]
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
      (let ([first-element (first code)]
            [rest-code (rest code)])

        (if (is-macro-call first-element data)
            ; If it's a macro call, expand it and continue processing
            ;; NOTE: Figure out how to properly pass args to nested macros
            ;; right now they're ending up with the wrong values
            ;; if the arg itself is a macro-arg,  we need to trickle that down somehow
            (let ([expanded-code (process-macro-element first-element rest-code data)])
              ;; recursive call with expanded code
              (insert-macro expanded-code data))

            ; If it's not a macro, keep this first element and process the rest
            (cons first-element (insert-macro rest-code data))))))

(define (insert-macros code data)
  (insert-macro code (program-data-macros data)))

(provide insert-macros)
