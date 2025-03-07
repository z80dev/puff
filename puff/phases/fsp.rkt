#lang racket
;;; fsp.rkt - Free Storage Pointer management for the Puff compiler
;;;
;;; This file implements the Free Storage Pointer (FSP) phase of the Puff compiler.
;;; The FSP is a utility in Huff for automatically allocating storage slots for variables.
;;; Each call to FREE_STORAGE_POINTER() returns a unique storage slot, ensuring
;;; that storage variables don't overlap.

(require "../utils.rkt")      ; Utility functions for hex conversion

;; counter: number
;; Global counter for tracking the next available storage slot
;; Each call to FREE_STORAGE_POINTER() increments this counter
(define counter 0)

;; free-storage-pointer: -> list
;; Generates a unique storage slot and returns it as a hex literal
;; Each call returns the current counter value and increments it for next time
;;
;; Returns:
;; - A hex literal representing a unique storage slot
;;   Format: '(hex "0x...")
(define (free-storage-pointer)
  (let ([result counter])
    ;; Increment the counter for the next call
    (set! counter (+ counter 1))
    
    ;; Return the current slot as a hex literal
    ;; This will be processed by the hexvals phase later
    (list 'hex (number->hex result))))

;; fsp-call?: any -> boolean
;; Determines if a code element is a call to FREE_STORAGE_POINTER()
;;
;; Parameters:
;; - code: The code element to check
;;
;; Returns:
;; - #t if the code is a FREE_STORAGE_POINTER() call, #f otherwise
(define (fsp-call? code)
  (equal? code "FREE_STORAGE_POINTER()"))

;; handle-fsp-call: any -> any
;; Processes a single code element, replacing FREE_STORAGE_POINTER() calls
;; with unique storage slots
;;
;; Parameters:
;; - code: The code element to process
;;
;; Returns:
;; - If the code is a FREE_STORAGE_POINTER() call, returns a unique storage slot
;;   Otherwise, returns the code unchanged
(define (handle-fsp-call code)
   (if (fsp-call? code)
       ;; If it's a FREE_STORAGE_POINTER() call, generate a unique slot
       (free-storage-pointer)
       ;; Otherwise, return the code unchanged
       code))

;; insert-fsp: list -> list
;; Top-level function for the free storage pointer phase
;; Replaces FREE_STORAGE_POINTER() calls with unique storage slots
;;
;; Parameters:
;; - code: The code to process
;;
;; Returns:
;; - The processed code with FREE_STORAGE_POINTER() calls replaced by storage slots
(define (insert-fsp code)
  (map handle-fsp-call code))

;; Export the top-level free storage pointer function
(provide insert-fsp)
