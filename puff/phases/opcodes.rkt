#lang racket/base
;;; opcodes.rkt - Opcode translation phase for the Puff compiler
;;;
;;; This file implements the opcode translation phase of the Puff compiler.
;;; It converts opcode names (mnemonics) to their actual byte values for
;;; the final bytecode. This is typically one of the last phases before
;;; final assembly.

(require "../huff-ops.rkt")  ; EVM operation definitions

;; handle-instr: any -> any
;; Processes a single instruction, converting opcode names to their byte values
;; If the input is not a recognized instruction, returns it unchanged
;;
;; Parameters:
;; - instr: The instruction to process
;;
;; Returns:
;; - If the instruction is a recognized opcode, returns its byte value
;;   Otherwise, returns the instruction unchanged
(define (handle-instr instr)
  (cond
   ;; If it's a recognized instruction, convert it to its opcode
   [(instruction? instr) (instruction->opcode instr)]
   ;; Otherwise, return it unchanged
   [else instr]))

;; insert-opcodes: list -> list
;; Top-level function for the opcode translation phase
;; Processes each instruction in the code, converting opcode names to byte values
;;
;; Parameters:
;; - code: The code to process
;;
;; Returns:
;; - The processed code with opcode names converted to byte values
(define (insert-opcodes code)
  (map handle-instr code))

;; Export the top-level opcode translation function
(provide insert-opcodes)
