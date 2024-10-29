#lang racket/base
(require racket/cmdline
         racket/match
         "puff/puff.rkt")

(define filename "")
(define compilation-output 'bytecode)

(command-line
 #:program "puff"
 #:once-any
 [("-b" "--bytecode") "Output bytecode" (set! compilation-output 'bytecode)]
 [("-r" "--runtime-bytecode") "Output runtime bytecode" (set! compilation-output 'runtime)]
 #:args (f)
 (set! filename f))

(match compilation-output
  ['bytecode (displayln (compile-filename filename))]
  ['runtime (displayln (compile-filename-runtime filename))])
