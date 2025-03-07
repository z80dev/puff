#lang racket/base
;;; events.rkt - Event signature generation phase for the Puff compiler
;;;
;;; This file implements the event signature generation phase of the Puff compiler.
;;; It calculates the Keccak-256 hashes of event signatures used in the Ethereum ABI
;;; for emitting events. These are full 32-byte hashes of the event signature.

(require "../analysis.rkt")    ; Program data structures
(require "../utils.rkt")       ; Utility functions
(require "./hexvals.rkt")      ; Hex value handling
(require "./abi-base.rkt")     ; ABI encoding utilities
(require threading)            ; Threading macros
(require racket/list)          ; List operations
(require racket/match)         ; Pattern matching
(require racket/string)        ; String operations

;; get-eventsig: string list -> string
;; Gets or calculates the event signature hash for an event with given name and arguments
;; Uses a cache to avoid recalculating the same signatures
;;
;; Unlike function selectors which use 4 bytes, event signatures use the full 32-byte hash
(define get-eventsig
  (make-callsig-cache))

;; handle-eventsig-call: any program-data -> any
;; Processes an event signature call, replacing it with its calculated hash
;;
;; Parameters:
;; - code: The code element to process
;; - data: The program-data structure containing event definitions
;;
;; Returns:
;; - If the code is an event signature call, returns its hash as a PUSH instruction
;;   Otherwise, returns the code unchanged
(define (handle-eventsig-call code data)
  (match code
    ;; If it's an event signature call (__EVENT_HASH), calculate the hash
    [(list 'fncall "__EVENT_HASH" args)
     (let* (
            ;; Extract the event name from the arguments
            [ident (second args)]
            
            ;; Get the event definitions hash map
            [eventdefs (program-data-eventdefs data)]
            
            ;; Look up the argument types for this event
            [args (hash-ref eventdefs ident #f)]
            
            ;; Calculate the event signature hash
            [sig (get-eventsig ident args)])
       
       ;; Convert the hash to a PUSH instruction
       (hex->instrs sig))]
    
    ;; For other code elements, return unchanged
    [_ code]))

;; make-handler: program-data -> (any -> any)
;; Creates a handler function that processes event signature calls
;;
;; Parameters:
;; - data: The program-data structure
;;
;; Returns:
;; - A function that processes code elements for event signature calls
(define (make-handler data)
  (lambda (code)
    (handle-eventsig-call code data)))

;; insert-eventsigs: list program-data -> list
;; Top-level function for the event signature generation phase
;; Replaces event signature calls with their calculated hashes
;;
;; Parameters:
;; - code: The code to process
;; - data: The program-data structure containing event definitions
;;
;; Returns:
;; - The processed code with event signature calls replaced by their hashes
(define (insert-eventsigs code data)
  (map (make-handler data) code))

;; Export the top-level event signature generation function
(provide insert-eventsigs)
