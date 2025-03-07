#lang racket/base
;;; hexvals.rkt - Hex value conversion phase for the Puff compiler
;;;
;;; This file implements the hexadecimal value handling phase of the Puff compiler.
;;; It converts hex literals in the code to appropriate PUSH instructions based on
;;; their byte length. This allows Huff code to use hex literals which are translated
;;; to correct EVM push operations.

(require racket/string)      ; String operations
(require racket/match)       ; Pattern matching

;; pad-if-odd: string -> string
;; Ensures a hexadecimal string has an even number of digits
;; This is necessary because each byte is represented by two hex digits
;;
;; Parameters:
;; - hex-str: A hexadecimal string (with 0x prefix)
;;
;; Returns:
;; - The properly padded hexadecimal string
(define (pad-if-odd hex-str)
  (if (odd? (string-length hex-str))
      ;; If odd length, add a 0 after the 0x prefix
      (string-append "0x0" (string-trim hex-str "0x"))
      ;; Otherwise, return unchanged
      hex-str))

;; hex->instrs: string -> list
;; Converts a hexadecimal value to the appropriate PUSH instruction sequence
;; This determines the smallest PUSH instruction that can hold the value
;;
;; Parameters:
;; - val: A hexadecimal string (with 0x prefix)
;;
;; Returns:
;; - A list containing the PUSH instruction and its hexadecimal argument
;;   For example: '("PUSH1" "0xff") or '("PUSH2" "0x1234")
(define (hex->instrs val)
  (let ([val (pad-if-odd val)])
    (if (equal? val "0x00")
        ;; Special case for 0, use PUSH0 (more gas efficient)
        (list "PUSH0")
        ;; For other values, determine the appropriate PUSH instruction
        (let* (
               ;; Calculate number of bytes in the value
               ;; Subtract 2 for "0x" prefix, then divide by 2 for byte count
               [num-bytes (ceiling (/ (- (string-length val) 2) 2))]
               
               ;; Create the PUSH instruction with the appropriate size
               [push-instr (string-append "PUSH" (number->string num-bytes))])
          
          ;; Return the instruction and value as a list
          (list push-instr val)))))

;; handle-instr: any -> any
;; Handles a single instruction, converting hex literals to PUSH instructions
;;
;; Parameters:
;; - instr: The instruction to process
;;
;; Returns:
;; - If the instruction is a hex literal, returns the appropriate PUSH instruction
;;   Otherwise, returns the instruction unchanged
(define (handle-instr instr)
  (match instr
    ;; If the instruction is a hex literal, convert it to a PUSH instruction
    [(list 'hex num) (hex->instrs num)]
    ;; Otherwise, return the instruction unchanged
    [_ instr]))

;; insert-hexvals: list -> list
;; Top-level function for the hex value conversion phase
;; Processes each instruction in the code, converting hex literals to PUSH instructions
;;
;; Parameters:
;; - code: The code to process
;;
;; Returns:
;; - The processed code with hex literals converted to PUSH instructions
(define (insert-hexvals code)
  (map handle-instr code))

;; Export the hex value conversion functions
(provide insert-hexvals    ; Top-level phase function
         hex->instrs)      ; Utility function for other phases
