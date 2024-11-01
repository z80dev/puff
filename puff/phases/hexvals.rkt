#lang racket/base

(require racket/string)
(require racket/match)

(define (pad-if-odd hex-str)
  (if (odd? (string-length hex-str))
      (string-append "0x0" (string-trim hex-str "0x"))
      hex-str))

(define (hex->instrs val)
  (let ([val (pad-if-odd val)])
    (if (equal? val "0x00")
       (list "PUSH0")
       (let* ([num-bytes (ceiling (/ (- (string-length val) 2) 2))]
              [push-instr (string-append "PUSH" (number->string num-bytes))])
        (list push-instr val)))))

(define (handle-instr instr)
  (match instr
    [(list 'hex num) (hex->instrs num)]
    [_ instr]))

(define (insert-hexvals code)
  (map handle-instr code))

(provide insert-hexvals hex->instrs)
