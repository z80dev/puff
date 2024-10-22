#lang racket/base

(require "../analysis.rkt")
(require "../keccak.rkt")
(require "../utils.rkt")
(require "./hexvals.rkt")
(require threading)
(require racket/list)
(require racket/match)
(require racket/string)

;; this function takes args and formats them into what we need for keccak hashing
;; this will handle things like "address", "uint", "uint256", etc. but also typed-args
;; which look like '(typed-arg typ name)
(define (format-arg arg)
  (let ([arg  (if (list? arg)
                 (second arg)
                 arg)])
    (match arg
      ["uint" "uint256"]
      [_ arg])))

(define (format-call ident args)
  (format "~a(~a)" ident (string-join (map format-arg (rest args)) ",")))

(define (calculate-callsig ident args)
  (~> ident
      (format-call args)
      string->keccak256
      bytes->list
      bytes->hex))

(define (make-callsig-cache)
  (let ([cache (make-hash)])
    (lambda (ident args)
      (let ([calc (lambda () (calculate-callsig ident args))])
        (hash-ref! cache ident calc)))))

(provide format-arg
         format-call
         make-callsig-cache)
