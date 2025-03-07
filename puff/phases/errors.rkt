#lang racket/base
;;; errors.rkt - Error signature generation phase for the Puff compiler
;;;
;;; This file implements the error signature generation phase of the Puff compiler.
;;; It calculates the 4-byte selectors for custom error types used in the Ethereum ABI
;;; for reverting with custom errors. Like function selectors, these are the first
;;; 4 bytes of the keccak256 hash of the error signature.

(require "../analysis.rkt")    ; Program data structures
(require "../utils.rkt")       ; Utility functions
(require "./hexvals.rkt")      ; Hex value handling
(require "./abi-base.rkt")     ; ABI encoding utilities
(require threading)            ; Threading macros
(require racket/list)          ; List operations
(require racket/match)         ; Pattern matching
(require racket/string)        ; String operations

;; format-errorsig: string -> string
;; Formats an error signature hash to the correct format for EVM use
;; Takes the first 4 bytes (like function selectors) and zero-pads to the right
;;
;; Parameters:
;; - sig: The full keccak256 hash of an error signature
;;
;; Returns:
;; - The properly formatted 4-byte error selector (with 0x prefix)
(define (format-errorsig sig)
  (~> sig
      (substring 0 10)         ; Take first 10 chars (0x + 8 hex digits = 4 bytes)
      zero-pad-right))         ; Pad with zeros to the right for proper alignment

;; get-errorsig: string list -> string
;; Gets or calculates the error selector for an error with given name and arguments
;; Uses a cache to avoid recalculating the same signatures
;;
;; Parameters:
;; - ident: The error name
;; - args: The list of argument types
;;
;; Returns:
;; - The 4-byte error selector (with 0x prefix)
(define get-errorsig
  ;; Create a closure with a cached signature generator
  (let ([error-sigs (make-callsig-cache)])
    (lambda (ident args)
      (~> ident
          (error-sigs args)    ; Get the hash from the cache
          format-errorsig))))  ; Format it as an error selector

;; handle-errorsig-call: any program-data -> any
;; Processes an error signature call, replacing it with its calculated selector
;;
;; Parameters:
;; - code: The code element to process
;; - data: The program-data structure containing error definitions
;;
;; Returns:
;; - If the code is an error signature call, returns its selector as a PUSH instruction
;;   Otherwise, returns the code unchanged
(define (handle-errorsig-call code data)
  (match code
    ;; If it's an error signature call (__ERROR), calculate the selector
    [(list 'fncall "__ERROR" args)
     (let* (
            ;; Extract the error name from the arguments
            [ident (second args)]
            
            ;; Get the error definitions hash map
            [errordefs (program-data-errordefs data)]
            
            ;; Look up the argument types for this error
            [args (hash-ref errordefs ident #f)]
            
            ;; Calculate the error selector
            [sig (get-errorsig ident args)])
       
       ;; Convert the selector to a PUSH instruction
       (hex->instrs sig))]
    
    ;; For other code elements, return unchanged
    [_ code]))

;; make-handler: program-data -> (any -> any)
;; Creates a handler function that processes error signature calls
;;
;; Parameters:
;; - data: The program-data structure
;;
;; Returns:
;; - A function that processes code elements for error signature calls
(define (make-handler data)
  (lambda (code)
    (handle-errorsig-call code data)))

;; insert-errorsigs: list program-data -> list
;; Top-level function for the error signature generation phase
;; Replaces error signature calls with their calculated selectors
;;
;; Parameters:
;; - code: The code to process
;; - data: The program-data structure containing error definitions
;;
;; Returns:
;; - The processed code with error signature calls replaced by their selectors
(define (insert-errorsigs code data)
  (map (make-handler data) code))

;; Export the top-level error signature generation function
(provide insert-errorsigs)
