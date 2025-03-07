#lang racket/base
;;; funcsigs.rkt - Function signature generation phase for the Puff compiler
;;;
;;; This file implements the function signature generation phase of the Puff compiler.
;;; It calculates the 4-byte function selectors used in the Ethereum ABI for function
;;; calls. These are the first 4 bytes of the keccak256 hash of the function signature.

(require "../analysis.rkt")    ; Program data structures
(require "./hexvals.rkt")      ; Hex value handling
(require "./abi-base.rkt")     ; ABI encoding utilities
(require threading)           ; Threading macros
(require racket/list)         ; List operations
(require racket/match)        ; Pattern matching
(require racket/string)       ; String operations

;; format-funcsig: string -> string
;; Extracts the first 10 characters (4 bytes + 0x prefix) from a function signature hash
;; This corresponds to the EVM ABI function selector format
;;
;; Parameters:
;; - sig: The full keccak256 hash of a function signature
;;
;; Returns:
;; - The 4-byte function selector (with 0x prefix)
(define (format-funcsig sig)
  ;; Take only the first 10 characters (0x + 8 hex digits = 4 bytes)
  (substring sig 0 10))

;; get-funcsig: string list -> string
;; Gets or calculates the function selector for a function with given name and arguments
;; Uses a cache to avoid recalculating the same signatures
;;
;; Parameters:
;; - ident: The function name
;; - args: The list of argument types
;;
;; Returns:
;; - The 4-byte function selector (with 0x prefix)
(define get-funcsig
  ;; Create a closure with a cached signature generator
  (let ([func-sigs (make-callsig-cache)])
    (lambda (ident args)
      ;; Get the function signature and format it to 4 bytes
      (format-funcsig (func-sigs ident args)))))

;; handle-fnsig-call: any program-data -> any
;; Processes a function signature call, replacing it with its calculated selector
;;
;; Parameters:
;; - code: The code element to process
;; - data: The program-data structure containing function declarations
;;
;; Returns:
;; - If the code is a function signature call, returns its selector as a PUSH instruction
;;   Otherwise, returns the code unchanged
(define (handle-fnsig-call code data)
  (match code
    ;; If it's a function signature call (__FUNC_SIG), calculate the selector
    [(list 'fncall "__FUNC_SIG" args)
     (let* (
            ;; Extract the function name from the arguments
            [ident (second args)]
            
            ;; Get the function declarations hash map
            [fndecls (program-data-fndecls data)]
            
            ;; Look up the argument types for this function
            [args (hash-ref fndecls ident #f)]
            
            ;; Calculate the function selector
            [sig (get-funcsig ident args)])
       
       ;; Convert the selector to a PUSH instruction
       (hex->instrs sig))]
    
    ;; For other code elements, return unchanged
    [_ code]))

;; make-handler: program-data -> (any -> any)
;; Creates a handler function that processes function signature calls
;;
;; Parameters:
;; - data: The program-data structure
;;
;; Returns:
;; - A function that processes code elements for function signature calls
(define (make-handler data)
  (lambda (code)
    (handle-fnsig-call code data)))

;; insert-funcsigs: list program-data -> list
;; Top-level function for the function signature generation phase
;; Replaces function signature calls with their calculated selectors
;;
;; Parameters:
;; - code: The code to process
;; - data: The program-data structure containing function declarations
;;
;; Returns:
;; - The processed code with function signature calls replaced by their selectors
(define (insert-funcsigs code data)
  (map (make-handler data)
       code))

;; Export the top-level function signature generation function
(provide insert-funcsigs)
