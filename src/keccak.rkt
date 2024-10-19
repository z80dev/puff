#lang racket

(require ffi/unsafe ffi/unsafe/define "assembler.rkt" threading)
(require racket/runtime-path)

(define-runtime-path libdir "../lib")

;; define-runtime-path to each library file depending on system
(define lib-path
  (cond
    [(eq? (system-type 'os) 'unix) (build-path libdir "libkeccak_lib.so")]
    [(eq? (system-type 'os) 'windows) (build-path libdir "libkeccak_lib.dll")]
    [(eq? (system-type 'os) 'macosx) (build-path libdir "libkeccak_lib.dylib")]
    [else (error "Unsupported system type")]))

;;(define-runtime-path libkeccak "../lib/libkeccak_lib")

(define-ffi-definer define-keccak (ffi-lib lib-path))

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
