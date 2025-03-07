#lang racket/base
;;; abi-base.rkt - Ethereum ABI utilities for the Puff compiler
;;;
;;; This file provides utilities for working with Ethereum ABI encoding,
;;; particularly for calculating function, event, and error signatures.
;;; It handles the formatting and hashing of signatures according to the
;;; Ethereum ABI specification.

(require "../analysis.rkt")    ; Program data structures
(require "../keccak.rkt")      ; Keccak-256 hash function
(require "../utils.rkt")       ; Utility functions
(require "./hexvals.rkt")      ; Hex value handling
(require threading)            ; Threading macros
(require racket/list)          ; List operations
(require racket/match)         ; Pattern matching
(require racket/string)        ; String operations

;; format-arg: any -> string
;; Formats an argument type for use in ABI signatures
;; Handles both simple types and typed arguments with names
;; Also normalizes certain types (e.g., "uint" -> "uint256")
;;
;; Parameters:
;; - arg: The argument to format (string or typed-arg list)
;;
;; Returns:
;; - The formatted argument type as a string
(define (format-arg arg)
  (let (
        ;; Extract the type from typed arguments (format: '(typed-arg type name))
        [arg  (if (list? arg)
                 (second arg)  ; For typed args, use the type (second element)
                 arg)])        ; For simple types, use as-is
    
    ;; Normalize certain types according to Ethereum ABI rules
    (match arg
      ;; "uint" should be treated as "uint256"
      ["uint" "uint256"]
      ;; Other types are used as-is
      [_ arg])))

;; format-call: string list -> string
;; Formats a function/event/error signature according to Ethereum ABI rules
;; The format is: name(type1,type2,...,typeN)
;;
;; Parameters:
;; - ident: The name of the function/event/error
;; - args: The list of argument types (first element is the args tag)
;;
;; Returns:
;; - The formatted signature string
(define (format-call ident args)
  (format "~a(~a)" 
          ident                                   ; Function/event/error name
          (string-join (map format-arg (rest args)) ","))) ; Comma-separated args

;; calculate-callsig: string list -> string
;; Calculates the keccak256 hash of a formatted signature
;; This is used for generating function selectors, event topics, etc.
;;
;; Parameters:
;; - ident: The name of the function/event/error
;; - args: The list of argument types
;;
;; Returns:
;; - The keccak256 hash of the signature as a hex string (with 0x prefix)
(define (calculate-callsig ident args)
  (~> ident
      (format-call args)        ; Format the signature
      string->keccak256         ; Calculate keccak256 hash
      bytes->list              ; Convert to byte list
      bytes->hex))             ; Convert to hex string

;; make-callsig-cache: -> (string list -> string)
;; Creates a cached function for calculating signature hashes
;; This avoids recalculating the same signature multiple times
;;
;; Returns:
;; - A function that accepts an identifier and argument list and returns the hash
;;   The function caches results based on the identifier
(define (make-callsig-cache)
  (let ([cache (make-hash)])  ; Create a hash table for caching
    (lambda (ident args)
      (let (
            ;; Function to calculate the signature if not in cache
            [calc (lambda () (calculate-callsig ident args))])
        
        ;; Get from cache if present, otherwise calculate and cache
        (hash-ref! cache ident calc)))))

;; Export the ABI utility functions
(provide format-arg         ; Argument formatting
         format-call        ; Signature formatting
         make-callsig-cache) ; Cached signature calculation
