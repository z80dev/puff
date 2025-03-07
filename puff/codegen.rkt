#lang racket/base

(require "huff-ops.rkt"
         "utils.rkt"
         "phases/hexvals.rkt")

;; in this file: functions to generate actual opcodes
;; this means:
;; - constructor generators

(define (generate-copy-constructor sz)
  (let* ([sz-str (number->string sz 16)]
         [sz-str (if (odd? (string-length sz-str))
                     (string-append "0" sz-str)
                     sz-str)]
         [sz-hex-str (string-append "0x" sz-str)]
         ;; Calculate the correct offset based on length bytes
         [length-bytes (ceiling (/ (string-length sz-str) 2))]
         [offset-str (number->string (+ 9 (- length-bytes 1)) 16)]
         [offset-str (if (odd? (string-length offset-str))
                         (string-append "0" offset-str)
                         offset-str)]
         [offset-val (format "0x~a" offset-str)])
    (append (hex->instrs sz-hex-str) (list "DUP1" "PUSH1" offset-val "RETURNDATASIZE" "CODECOPY" "RETURNDATASIZE" "RETURN"))))

(provide
         generate-copy-constructor)
