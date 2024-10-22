#lang racket/base

(require "../analysis.rkt")
(require "./hexvals.rkt")
(require "./abi-base.rkt")
(require threading)
(require racket/list)
(require racket/match)
(require racket/string)

(define (format-funcsig sig)
  (substring sig 0 10))

(define get-funcsig
  (let ([func-sigs (make-callsig-cache)])
    (lambda (ident args)
      (format-funcsig (func-sigs ident args)))))

(define (handle-fnsig-call code data)
  (match code
    [(list 'fncall "__FUNC_SIG" args)
     (let* ([ident (second args)]
            [fndecls (program-data-fndecls data)]
            [args (hash-ref fndecls ident #f)]
            [sig (get-funcsig ident args)])
       (hex->instrs sig))]
    [_ code]))

(define (make-handler data)
  (lambda (code)
    (handle-fnsig-call code data)))

(define (insert-funcsigs code data)
  (map (make-handler data)
       code))

(provide insert-funcsigs)
