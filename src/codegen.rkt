#lang racket
(require "huff-ops.rkt"
         "utils.rkt"
         threading)

;; in this file: functions to generate actual opcodes
;; this means:
;; - huff instructions like mstore become "MSTORE"
;; - hex values like "0x20" become "PUSH1 0x20"
;; - constructor generators

(define (handle-val val)
  (cond
    [(instruction? val) (list (instruction->opcode val))]
    [else (begin
            (displayln (format "Unknown value: ~a" val))
            (list (string-upcase (symbol->string val))))]))

(define (handle-hex val)
  (if (equal? val "0x00")
      (list "PUSH0")
   (let* (
          [num-bytes (ceiling (/ (- (string-length val) 2) 2))]
          [push-instr (string-append "PUSH" (number->string num-bytes))])
     (list push-instr val))))

(define (handle-expr expr)
  (match (first expr)
    ['hex (handle-hex (second expr))]
    ['const-ref (list expr)]
    ['body (apply append (map handle-tree (rest expr)))]))

(define (handle-tree tree)
  (if (list? tree)
      (handle-expr tree)
      (handle-val tree)))

(define (generate-copy-constructor sz)
  (let ([sz-hex-str (string-append "0x" (number->string sz 16))])
    (append (handle-hex sz-hex-str) '("DUP1" "PUSH1" "0x09" "RETURNDATASIZE" "CODECOPY" "RETURNDATASIZE" "RETURN"))))

(provide handle-tree
         handle-hex
         handle-val
         generate-copy-constructor)
