#lang racket/base

(require racket/string)
(require racket/match)

(define (hex->instrs val)
  (if (equal? val "0x00")
      (list "PUSH0")
   (let* (
          [num-bytes (ceiling (/ (- (string-length val) 2) 2))]
          [push-instr (string-append "PUSH" (number->string num-bytes))])
     (list push-instr val))))

(define (handle-instr instr)
  (match instr
    [(list 'hex num) (hex->instrs num)]
    [_ instr]))

(define (insert-hexvals code data)
  (map handle-instr code))

(provide insert-hexvals hex->instrs)
