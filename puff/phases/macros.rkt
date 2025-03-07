#lang racket/base
;;; macros.rkt - Macro expansion phase for the Puff compiler
;;;
;;; This file implements the macro expansion phase of the Puff compiler.
;;; Macros in Huff allow code reuse by defining parameterized code blocks
;;; that can be expanded at compile time. This phase replaces macro calls
;;; with their expanded definitions, substituting arguments as needed.

(require racket/list)       ; List manipulation utilities
(require "../analysis.rkt") ; Program data structure

;; macro-call?: any hash -> boolean
;; Determines if a code element is a macro call by checking:
;; 1. It's a list structure
;; 2. Its first element is the symbol 'fncall
;; 3. The function name exists in the macros hash
;;
;; Parameters:
;; - code: The code element to check
;; - data: Hash map of macro definitions
;;
;; Returns:
;; - #t if the code element is a macro call, #f otherwise
(define (macro-call? code data)
  (and (list? code)
       (eq? 'fncall (first code))
       (hash-has-key? data (second code))))

;; macro-arg?: any -> boolean
;; Determines if a code element is a macro argument reference
;;
;; Parameters:
;; - code: The code element to check
;;
;; Returns:
;; - #t if the code element is a macro argument reference, #f otherwise
(define (macro-arg? code)
  (and (list? code)
       (eq? 'macro-arg (first code))))

;; fncall?: any -> boolean
;; Determines if a code element is a function call
;;
;; Parameters:
;; - code: The code element to check
;;
;; Returns:
;; - #t if the code element is a function call, #f otherwise
(define (fncall? code)
  (and (list? code)
       (eq? 'fncall (first code))))

;; insert-args-from-data: list hash -> list
;; Replaces macro argument references with their values
;; Iterates over every element in code and if it's a '(macro-arg foo)',
;; replaces it with the value of foo from the data hash
;;
;; Parameters:
;; - code: List of code elements that may contain macro argument references
;; - data: Hash map of argument names to their values
;;
;; Returns:
;; - New list with argument references replaced by their values
(define (insert-args-from-data code data)
  (define (replace-arg element)
    (if (macro-arg? element)
        (hash-ref data (second element))
        element))
  (map replace-arg code))

;; insert-macroargs-to-fncall: list hash -> list
;; Processes a function call's arguments, replacing macro argument references
;;
;; Parameters:
;; - fncall: The function call to process
;; - data: Hash map of argument names to their values
;;
;; Returns:
;; - Updated function call with argument references resolved
(define (insert-macroargs-to-fncall fncall data)
  (list 'fncall 
        (second fncall)                         ; Function name
        (insert-args-from-data (third fncall) data))) ; Process arguments

;; insert-macro-args: list hash -> list
;; Recursively processes a code block, replacing all macro argument references
;;
;; Parameters:
;; - code: The code block to process
;; - data: Hash map of argument names to their values
;;
;; Returns:
;; - Processed code with all argument references resolved
(define (insert-macro-args code data)
  ;; Check if we've reached the end of the code
  (define done?
    (empty? code))
  
  ;; Process the rest of the code recursively
  (define (recurse)
    (insert-macro-args (rest code) data))

  ;; Continue processing with the given node and recurse on the rest
  (define (continue [node (car code)])
    (cons node (recurse)))

  ;; Process a macro argument reference
  (define (handle-macro-arg code)
    ;; (cadar '((1 2 3) 4 5)) = 2, i.e. second element of first element in list
    ;; (cadar '((macro-arg foo))) = 'foo
    (continue (hash-ref data (cadar code))))

  ;; Process a function call by checking its argument list for macro arguments
  (define (handle-fncall node)
    (continue (insert-macroargs-to-fncall node data)))

  ;; Main conditional logic based on the current code element
  (cond
   (done? code)                            ; Base case: empty code
   ((fncall? (first code)) (handle-fncall (first code))) ; Function call
   ((macro-arg? (first code)) (handle-macro-arg code))   ; Macro argument reference
   (else (continue))))                     ; Other code element

;; get-macro-body: list hash -> list
;; Extracts and processes a macro's body, substituting arguments
;;
;; Parameters:
;; - code: The macro call
;; - data: Hash map of macro definitions
;;
;; Returns:
;; - Expanded macro body with arguments substituted
(define (get-macro-body code data)
  (let* ([name (second code)]               ; Macro name
         [args (third code)]                ; Call arguments
         [macrodef (hash-ref data name)]    ; Macro definition
         [argsdef (first macrodef)]         ; Formal parameters
         (macrobody (fourth macrodef))      ; Macro body
         [argsmap (make-hash)])             ; Argument mapping hash
    ;; Map formal parameters to actual arguments
    (for ([k (rest argsdef)]                ; Skip 'args tag
          [v (rest args)])                  ; Skip 'args tag
      (hash-set! argsmap k v))
    ;; Replace argument references in the macro body
    (insert-macro-args macrobody argsmap)))

;; insert-macro: list hash -> list
;; Recursively processes code, expanding all macro calls
;; This is the core of the macro expansion algorithm
;;
;; Parameters:
;; - code: The code to process
;; - data: Hash map of macro definitions
;;
;; Returns:
;; - Fully expanded code with all macros replaced by their implementations
(define (insert-macro code data)
  ;; Helper function to process a macro call and merge with remaining code
  (define (process-macro-element element rest-code data)
    (let ([macro-body (get-macro-body element data)]
          [remaining-code rest-code])
      (append macro-body remaining-code)))
  
  ;; Base case - empty code returns empty
  (if (empty? code)
      code
      ;; For non-empty code, analyze the first element
      (let ([first-element (first code)]
            [rest-code (rest code)])

        (if (macro-call? first-element data)
            ;; If it's a macro call, expand it and continue processing
            ;; Note: we recursively process the expanded code to handle nested macros
            (let ([expanded-code (process-macro-element first-element rest-code data)])
              (insert-macro expanded-code data))

            ;; If it's not a macro, keep this element and process the rest
            (cons first-element (insert-macro rest-code data))))))

;; insert-macros: list program-data -> list
;; Top-level macro expansion function that works with program-data
;;
;; Parameters:
;; - code: The code to process
;; - data: The program-data structure containing all macro definitions
;;
;; Returns:
;; - Fully expanded code with all macros replaced by their implementations
(define (insert-macros code data)
  (insert-macro code (program-data-macros data)))

;; Export the top-level macro expansion function
(provide insert-macros)
