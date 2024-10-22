#lang racket/base

(require "../analysis.rkt")
(require "../keccak.rkt")
(require "../utils.rkt")
(require "./hexvals.rkt")
(require "./abi-base.rkt")
(require threading)
(require racket/list)
(require racket/match)
(require racket/string)

(define get-eventsig
  (make-callsig-cache))

(define (handle-eventsig-call code data)
  (match code
    [(list 'fncall "__EVENT_HASH" args)
     (let* ([ident (second args)]
            [eventdefs (program-data-eventdefs data)]
            [args (hash-ref eventdefs ident #f)]
            [sig (get-eventsig ident args)])
       (hex->instrs sig))]
    [_ code]))

(define (make-handler data)
  (lambda (code)
    (handle-eventsig-call code data)))

(define (insert-eventsigs code data)
  (map (make-handler data) code))

(provide insert-eventsigs)
