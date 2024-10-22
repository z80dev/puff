#lang racket/base

(require "../analysis.rkt")
(require "../utils.rkt")
(require "./hexvals.rkt")
(require "./abi-base.rkt")
(require threading)
(require racket/list)
(require racket/match)
(require racket/string)

(define (format-errorsig sig)
  (~> sig
      (substring 0 10)
      zero-pad-right))

(define get-errorsig
  (let ([error-sigs (make-callsig-cache)])
    (lambda (ident args)
      (~> ident
          (error-sigs args)
          format-errorsig))))

(define (handle-errorsig-call code data)
  (match code
    [(list 'fncall "__ERROR" args)
     (let* ([ident (second args)]
            [errordefs (program-data-errordefs data)]
            [args (hash-ref errordefs ident #f)]
            [sig (get-errorsig ident args)])
       (hex->instrs sig))]
    [_ code]))

(define (make-handler data)
  (lambda (code)
    (handle-errorsig-call code data)))

(define (insert-errorsigs code data)
  (map (make-handler data) code))

(provide insert-errorsigs)
