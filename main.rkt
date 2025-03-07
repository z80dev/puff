#lang racket/base
;;; main.rkt - Command-line interface for the Puff compiler
;;;
;;; This file implements the command-line interface for the Puff compiler.
;;; It processes command-line arguments and routes them to the appropriate
;;; compilation functions. The compiler can output either full bytecode
;;; (including constructor) or runtime bytecode only.

(require racket/cmdline     ; Command-line argument processing
         racket/match       ; Pattern matching
         "puff/puff.rkt")   ; Core compiler functionality

;; Default values for command-line options
(define filename "")                  ; Input file path
(define compilation-output 'bytecode) ; Output type (bytecode or runtime-only)

;; Process command-line arguments
;; The compiler accepts a single file argument and options to control output format
(command-line
 #:program "puff"           ; Program name
 #:once-any                 ; Only one of these options can be specified
 
 ;; -b/--bytecode: Output full bytecode (constructor + runtime)
 ;; This is the default output type
 [("-b" "--bytecode") 
  "Output full bytecode including constructor code"
  (set! compilation-output 'bytecode)]
 
 ;; -r/--runtime-bytecode: Output runtime bytecode only
 ;; This excludes the constructor code used for contract deployment
 [("-r" "--runtime-bytecode") 
  "Output runtime bytecode only (excluding constructor code)"
  (set! compilation-output 'runtime)]
 
 ;; Required positional argument: input filename
 #:args (f)
 (set! filename f))

;; Invoke the appropriate compilation function based on the requested output type
;; and display the result to standard output
(match compilation-output
  ;; Full bytecode output (constructor + runtime)
  ['bytecode 
   (displayln (compile-filename filename))]
  
  ;; Runtime bytecode output only
  ['runtime 
   (displayln (compile-filename-runtime filename))])
