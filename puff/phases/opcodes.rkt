#lang racket/base

(require "../huff-ops.rkt")

(define (handle-instr instr)
  (cond
   [(instruction? instr) (instruction->opcode instr)]
   [else instr]))

(define (insert-opcodes code data)
  (map handle-instr code))

(provide insert-opcodes)
