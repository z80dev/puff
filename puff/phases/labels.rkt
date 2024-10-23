#lang racket/base

(require racket/list)
(require racket/string)

(require "../huff-ops.rkt")
(require "../utils.rkt")

;; TODO: Lots of hackiness in this pass. Clean up.

#| we will handle labels in this file
- label refs are just plain words like "foo"
- labels are '(label "foo")

in this step we hardcode byte offsets for labels
so it must be the last step before assembling
maybe we should handle this in the assembler?
|#

;; input is ((PUSH13 0x48656c6c6f2c20576f726c6421) (PUSH0) mstore success jump (PUSH0) (PUSH0) revert (label success) (PUSH0) mstore (PUSH1 0x20) (PUSH0) return)
;; we need to replace each '(label name) with a "jmpdest" instruction, and record the byte offset of the label
;; then we need to replace each reference to a label with a push instruction that pushes the byte offset of the label

(define (subexpr-length expr)
  (if (list? expr)
      (if (and (> (length expr) 1)
               (string-prefix? (car expr) "PUSH")
               (string-prefix? (cadr expr) "0x"))
          (+ 1 (string->number (substring (car expr) 4)))
       (length expr))
      (if (instruction? expr)
          1
          2))) ;; we're treating anything that isn't an opcode as a label reference and assuming they're 2 bytes long

(define (record-label-offsets code ht cur)
  (if (empty? code)
      code
      (let ([instr (car code)])
        (if (list? instr)
            (if (eq? 'label (car instr))
                (begin
                  (hash-set! ht (cadr instr) cur)
                  (cons "jumpdest" (record-label-offsets (cdr code) ht (+ 1 cur))))
                (cons instr (record-label-offsets (cdr code) ht (+ cur (subexpr-length instr)))))
            (cons instr (record-label-offsets (cdr code) ht (+ cur 1)))))))

(define (replace-labels code ht)
  (if (empty? code)
      code
      (let ([instr (car code)])
        (if (list? instr)
            (cons instr (replace-labels (cdr code) ht))
            (if (hash-has-key? ht instr)
                (cons (list "PUSH1" (string-append "0x" (byte->hex (hash-ref ht instr)))) (replace-labels (cdr code) ht))
                (cons instr (replace-labels (cdr code) ht)))))))

(define (insert-labels code data)
  (let* ([ht (make-hash)]
         [code (record-label-offsets code ht 0)])
    (replace-labels code ht)))

(provide insert-labels)
