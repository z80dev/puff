#lang racket

(require "../codegen.rkt")
(require "../analysis.rkt")
(require "../keccak.rkt")
(require "../utils.rkt")
(require threading)

;; hash table to act as cache for function signatures
(define func-sigs (make-hash))

;; unwraps (typed-arg typ arg) to just its type
;; or handles just typ
;; also replaces "uint" with "uint256"
(define (format-arg arg)
  (let ([arg  (if (list? arg)
                 (second arg)
                 arg)])
    (match arg
      ["uint" "uint256"]
      [_ arg])))

(define (format-funcsig ident args)
  (format "~a(~a)" ident (string-join (map format-arg (rest args)) ",")))

(define (calculate-funcsig ident args)
  (~> ident
      (format-funcsig args)
      string->keccak256
      bytes->list
      bytes->hex
      (substring 0 10)))

;; fn to get funcsig from cache or calculate it
;; sigs are stored in func-sigs by ident
(define (get-funcsig ident args)
  (let ([sig (hash-ref func-sigs ident #f)])
    (if sig
        sig
        (let ([sig (calculate-funcsig ident args)])
          (hash-set! func-sigs ident sig)
          sig))))

(define (handle-fnsig-call code data)
  (match code
    [(list 'fncall "__FUNC_SIG" args)
     (let* ([ident (second args)]
            [fndecls (program-data-fndecls data)]
            [args (hash-ref fndecls ident #f)]
            [sig (get-funcsig ident args)])
       (handle-hex sig))]
    [_ code]))

(define (insert-funcsigs code data)
  (map (lambda (x)
         (handle-fnsig-call x data))
       code))

(provide insert-funcsigs)