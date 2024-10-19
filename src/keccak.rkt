#lang racket

(require ffi/unsafe ffi/unsafe/define "assembler.rkt" threading)
(require racket/runtime-path)

(define-runtime-path libkeccak "../lib/libkeccak_lib.so")

(define-ffi-definer define-keccak (ffi-lib libkeccak))

(define-keccak keccak256 (_fun _pointer _size _pointer -> _void))

(define (string->keccak256 input)
  (~> input
      string->bytes/utf-8
      bytes->keccak256))

(define (bytes->keccak256 input)
  (let* ([input-len (bytes-length input)]
         [buffer (make-bytes input-len)]
         [output (make-bytes 32)])
    (bytes-copy! buffer 0 input)
    (keccak256 buffer input-len output)
    (subbytes output 0 32)))

(provide string->keccak256 bytes->keccak256)
