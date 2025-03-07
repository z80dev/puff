#lang racket/base
;;; constants.rkt - Constant resolution phase for the Puff compiler
;;;
;;; This file implements the constant resolution phase of the Puff compiler.
;;; It replaces constant references in the code with their actual values from
;;; the constants hash map built during the analysis phase. This allows for
;;; defining constants once and using them throughout the code.

(require "../codegen.rkt")   ; Code generation utilities
(require "../analysis.rkt")  ; Program data structures
(require racket/match)       ; Pattern matching

;; handle-const-ref: any hash -> any
;; Handles a single constant reference by replacing it with its value
;; If the input is not a constant reference, returns it unchanged
;;
;; Parameters:
;; - code: The code element to check
;; - constants: Hash map of constant names to their values
;;
;; Returns:
;; - The constant value if the code is a constant reference, otherwise the original code
(define (handle-const-ref code constants)
  (match code
    ;; If the code element is a constant reference, replace it with the constant value
    [(list 'const-ref const)
     (hash-ref constants const)]
    ;; Otherwise, return the code element unchanged
    [_ code]))

;; make-handler: hash -> (any -> any)
;; Creates a handler function that processes constant references
;; This is a factory function that binds the constants hash map
;;
;; Parameters:
;; - constants: Hash map of constant names to their values
;;
;; Returns:
;; - A function that processes code elements for constant references
(define (make-handler constants)
  (lambda (code)
    (handle-const-ref code constants)))

;; insert-constants: list program-data -> list
;; Top-level function for the constant resolution phase
;; Replaces all constant references in the code with their actual values
;;
;; Parameters:
;; - code: The code to process
;; - data: The program-data structure containing the constants hash map
;;
;; Returns:
;; - The processed code with all constant references replaced by their values
(define (insert-constants code data)
  (let* (
         ;; Extract the constants hash map from the program data
         [constants (program-data-constants data)]
         
         ;; Create a handler function that processes constant references
         [handler (make-handler constants)])
    
    ;; Apply the handler to each element in the code
    (map handler code)))

;; Export the top-level constant resolution function
(provide insert-constants)
