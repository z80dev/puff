#lang racket/base

(require racket/list)
(require "../analysis.rkt")

(define (macro-call? code data)
  (and (list? code)
       (eq? 'fncall (first code))
       (hash-has-key? data (second code))))

(define (macro-arg? code)
  (and (list? code)
       (eq? 'macro-arg (first code))))

(define (fncall? code)
  (and (list? code)
       (eq? 'fncall (first code))))

;; iterate over every element in code
;; if its a '(macro-arg foo) then replace it with the value of foo
(define (insert-args-from-data code data)
  (define (replace-arg element)
    (if (macro-arg? element)
        (hash-ref data (second element))
        element))
  (map replace-arg code))

(define (insert-macroargs-to-fncall fncall data)
  (list 'fncall (second fncall) (insert-args-from-data (third fncall) data)))

(define (insert-macro-args code data)
  (define done?
    (empty? code))
  ;; just calls self with rest of the code
  (define (recurse)
    (insert-macro-args (rest code) data))

  ;; this accepts a processed node and recurses
  (define (continue [node (car code)])
    (cons node (recurse)))

  ;; process macro-arg into its value
  (define (handle-macro-arg code)
    ;; (cadar '((1 2 3) 4 5)) = 2, i.e. second element of first element in list
    ;; (cadar '((macro-arg foo))) = 'foo
    (continue (hash-ref data (cadar code))))

  ;; process fncalls by checking their arg-list for macro-args
  (define (handle-fncall node)
    (continue (insert-macroargs-to-fncall node data)))

  (cond
   (done? code)
   ((fncall? (first code)) (handle-fncall (first code)))
   ((macro-arg? (first code)) (handle-macro-arg code))
   (else (continue))))

(define (get-macro-body code data)
  (let* ([name (second code)]
         [args (third code)]
         [macrodef (hash-ref data name)]
         [argsdef (first macrodef)]
         (macrobody (fourth macrodef))
         [argsmap (make-hash)])
    (for ([k (rest argsdef)]
          [v (rest args)])
      (hash-set! argsmap k v))
    (insert-macro-args macrobody argsmap)))

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

        (if (macro-call? first-element data)
            ; If it's a macro call, expand it and continue processing
            (let ([expanded-code (process-macro-element first-element rest-code data)])
              ;; recursive call with expanded code
              (insert-macro expanded-code data))

            ; If it's not a macro, keep this first element and process the rest
            (cons first-element (insert-macro rest-code data))))))

(define (insert-macros code data)
  (insert-macro code (program-data-macros data)))

(provide insert-macros)
