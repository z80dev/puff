#lang racket/base
;;; labels.rkt - Jump label resolution for the Puff compiler
;;;
;;; This file handles the resolution of jump labels in Huff code.
;;; Jump labels allow control flow in EVM bytecode by marking locations
;;; that can be the target of jump instructions. This phase:
;;; 1. Replaces each label definition with a JUMPDEST instruction
;;; 2. Records the byte offset of each label
;;; 3. Replaces each label reference with a PUSH instruction containing the label's offset

(require racket/list)        ; List operations
(require racket/string)      ; String operations

(require "../huff-ops.rkt")  ; EVM operation definitions
(require "../utils.rkt")     ; Utility functions

;; NOTE: This implementation handles up to 65535 labels/offsets (2^16 - 1).
;; Each label reference uses PUSH2 + 2 bytes to ensure we can handle larger bytecode.
;; This allows for bytecode sizes up to 65535 bytes.
;;
;; TODO: Lots of hackiness in this pass. Clean up.

;; In Huff code, labels come in two forms:
;; 1. Label definitions: '(label "name") - Where a jump can target
;; 2. Label references: "name" - Where a jump comes from
;;
;; This phase hardcodes byte offsets for labels, so it must be one of the
;; last steps before assembling. The offsets are calculated by traversing
;; the code and summing the byte lengths of each instruction.

;; subexpr-length: any -> number
;; Calculates the byte length of an expression in the compiled bytecode
;;
;; Parameters:
;; - expr: The expression to measure
;;
;; Returns:
;; - The number of bytes the expression will occupy in the compiled bytecode
(define (subexpr-length expr)
  (if (list? expr)
      ;; If it's a list, check if it's a PUSH instruction with a hex value
      (if (and (> (length expr) 1)
               (string-prefix? (car expr) "PUSH")
               (string-prefix? (cadr expr) "0x"))
          ;; PUSH instructions are 1 byte for the opcode + N bytes for the value
          (+ 1 (string->number (substring (car expr) 4)))
          ;; Otherwise, assume the list length approximately reflects its byte size
          ;; TODO: potential bug here. list length might != length of expressions it contains
          (length expr))
      ;; If it's not a list, check if it's a known instruction
      (if (instruction? expr)
          1  ; Standard instructions are 1 byte
          3))) ; Label references are 3 bytes (PUSH2 + 2 bytes for offset)

;; record-label-offsets: list hash number -> list
;; Traverses the code and records the byte offset of each label
;; Also replaces label definitions with JUMPDEST instructions
;;
;; Parameters:
;; - code: The code to process
;; - ht: Hash table to store label offsets
;; - cur: Current byte offset
;;
;; Returns:
;; - Processed code with label definitions replaced by JUMPDEST
(define (record-label-offsets code ht cur)
  ;; Check if we've reached the end of the code
  (define done?
    (empty? code))
  
  ;; Check if a node is a label definition
  (define (label? node)
    (and (list? node) (eq? 'label (car node))))
  
  ;; Process the rest of the code with updated offset
  (define (recurse new-cur)
    (record-label-offsets (cdr code) ht new-cur))
  
  ;; Continue processing with the given node and updated offset
  (define (continue [node (car code)])
    (cons node (recurse (+ cur (subexpr-length node)))))
  
  ;; Handle a label definition by recording its offset and replacing with JUMPDEST
  (define (handle-label node)
    (hash-set! ht (cadr node) cur) ; Record label offset
    (continue "jumpdest"))         ; Replace with JUMPDEST
  
  ;; Main conditional logic
  (cond
    [done? code]                         ; Base case: empty code
    [(label? (car code)) (handle-label (car code))] ; Label definition
    [else (continue)]))                  ; Other code element

;; replace-labels: list hash -> list
;; Replaces label references with PUSH instructions containing their byte offsets
;;
;; Parameters:
;; - code: The code to process
;; - ht: Hash table containing label offsets
;;
;; Returns:
;; - Processed code with label references replaced by PUSH instructions
(define (replace-labels code ht)
  ;; Check if we've reached the end of the code
  (define done?
    (empty? code))
  
  ;; Process the rest of the code
  (define (recurse)
    (replace-labels (cdr code) ht))
  
  ;; Continue processing with the given node
  (define (continue [node (car code)])
    (cons node (recurse)))
  
  ;; Check if a node is a reference to a known label
  (define (labelref? node)
    (hash-has-key? ht node))
  
  ;; Wrap a label offset in a PUSH2 instruction
  (define (wrap-label label)
    (list "PUSH2" (string-append "0x" (word->hex (hash-ref ht label)))))
  
  ;; Handle a label reference by replacing it with a PUSH instruction
  (define (handle-labelref node)
    (continue (wrap-label node)))
  
  ;; Main conditional logic
  (cond
   (done? code)                          ; Base case: empty code
   ((labelref? (car code)) (handle-labelref (car code))) ; Label reference
   (else (continue))))                   ; Other code element

;; insert-labels: list -> list
;; Top-level function that processes code to resolve all jump labels
;;
;; This is a two-pass algorithm:
;; 1. First pass (record-label-offsets): Find all label definitions, record their
;;    offsets, and replace them with JUMPDEST instructions
;; 2. Second pass (replace-labels): Replace all label references with
;;    PUSH instructions containing the label offsets
;;
;; Parameters:
;; - code: The code to process
;;
;; Returns:
;; - Processed code with all labels resolved to concrete byte offsets
(define (insert-labels code)
  (let* ([ht (make-hash)]                      ; Create hash table for label offsets
         [code (record-label-offsets code ht 0)]) ; First pass: record offsets
    (replace-labels code ht)))                  ; Second pass: replace references

;; Export the top-level label resolution function
(provide insert-labels)
