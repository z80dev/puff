#lang racket/base

(require "huff-ops.rkt"
         "utils.rkt"
         "phases/hexvals.rkt"
         threading
         racket/match
         racket/list)

;; in this file: functions to generate actual opcodes
;; this means:
;; - huff instructions like mstore become "MSTORE"
;; - constructor generators

(define (generate-copy-constructor sz)
  (let* ([sz-str (number->string sz 16)]
         [sz-str (if (odd? (string-length sz-str))
                     (string-append "0" sz-str)
                     sz-str)]
         [sz-hex-str (string-append "0x" sz-str)])
    (append (hex->instrs sz-hex-str) '("DUP1" "PUSH1" "0x09" "RETURNDATASIZE" "CODECOPY" "RETURNDATASIZE" "RETURN"))))

(provide
         generate-copy-constructor)
