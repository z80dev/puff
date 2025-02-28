#lang racket

(require "puff/puff.rkt")

;; define some files to skip, like "examples/functions.huff"
(define skip-files (list "examples/functions.huff" "examples/padded.huff"))

;; check if string "included" is in the path
(define (check-if-included p)
  (regexp-match #rx"included" p))


;; iterate over all files in "examples" and call compile-filename for each
(for ([filename (in-directory "examples")])
  (unless (or (check-if-included filename)
              (directory-exists? filename)
              (member (path->string filename) skip-files))
    (printf "compiling ~a\n" filename)
    (compile-filename filename)))
