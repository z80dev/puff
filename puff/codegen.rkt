#lang racket/base
;;; codegen.rkt - Code generation utilities for the Puff compiler
;;;
;;; This file contains functions for generating EVM bytecode,
;;; primarily for contract constructors that deploy runtime code.
;;; It handles the low-level code generation that isn't part of
;;; the standard compilation phases.

(require "huff-ops.rkt"      ; EVM operation definitions
         "utils.rkt"         ; Utility functions
         "phases/hexvals.rkt") ; Hex value handling functions

;; generate-copy-constructor: number -> list
;; Generates a contract constructor that copies the runtime code to memory
;; and returns it, effectively deploying the contract code.
;;
;; The constructor sequence does the following:
;; 1. Push the runtime code size onto the stack
;; 2. Duplicate the size (for later use)
;; 3. Push the offset to the runtime code in the contract bytecode
;; 4. Use RETURNDATASIZE (which returns 0) as a cheap way to push 0 for memory destination
;; 5. Copy the runtime code to memory starting at position 0
;; 6. Return the memory segment containing the runtime code
;;
;; Parameters:
;; - sz: Size of the runtime code in bytes
;;
;; Returns:
;; - List of EVM instructions for the constructor
(define (generate-copy-constructor sz)
  (let* (
         ;; Convert size to hex string
         [sz-str (number->string sz 16)]
         
         ;; Ensure hex string has even length (for proper byte representation)
         [sz-str (if (odd? (string-length sz-str))
                     (string-append "0" sz-str)
                     sz-str)]
         
         ;; Format as 0x-prefixed hex string
         [sz-hex-str (string-append "0x" sz-str)]
         
         ;; Calculate the number of bytes needed to represent the size
         [length-bytes (ceiling (/ (string-length sz-str) 2))]
         
         ;; Calculate the offset to the runtime code
         ;; Formula: 9 + (size bytes - 1)
         ;; The 9 comes from:
         ;;   1 byte for the PUSH opcode
         ;;   n bytes for the size value
         ;;   1 byte for DUP1
         ;;   1 byte for PUSH1
         ;;   1 byte for the offset value
         ;;   1 byte for RETURNDATASIZE
         ;;   1 byte for CODECOPY
         ;;   1 byte for RETURNDATASIZE
         ;;   1 byte for RETURN
         ;; We subtract 1 from length-bytes because the offset is from
         ;; the end of the offset value itself
         [offset-str (number->string (+ 9 (- length-bytes 1)) 16)]
         
         ;; Ensure offset hex string has even length
         [offset-str (if (odd? (string-length offset-str))
                         (string-append "0" offset-str)
                         offset-str)]
         
         ;; Format offset as 0x-prefixed hex string
         [offset-val (format "0x~a" offset-str)])
    
    ;; Generate the constructor instruction sequence
    (append 
     ;; Push the runtime code size onto the stack
     ;; This will use the appropriate PUSH opcode based on size
     (hex->instrs sz-hex-str) 
     
     ;; The rest of the constructor sequence
     (list 
      "DUP1"           ; Duplicate size for later use
      "PUSH1" offset-val  ; Push offset to runtime code
      "RETURNDATASIZE"    ; Push 0 (destination in memory)
      "CODECOPY"          ; Copy runtime code to memory
      "RETURNDATASIZE"    ; Push 0 (offset in memory)
      "RETURN"))))        ; Return runtime code

;; Export the code generation functions
(provide generate-copy-constructor)
