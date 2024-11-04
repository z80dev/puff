#lang racket/base

(require "lexer.rkt"
         "huffparser.rkt"
         "utils.rkt"
         threading
         racket/list
         racket/match
         racket/file
         racket/path)

;; some structs, for convenience getter/setter methods
;; program-data will contain all the data required to compile a contract
(struct program-data (labels
                      macros
                      functions
                      fndecls
                      eventdefs
                      errordefs
                      constants
                      errors
                      includes
                      ctx) #:mutable)

;; no-arg constructor
(define (make-program-data)
  (program-data (make-hash) ;; labels
                (make-hash) ;; macros
                (make-hash) ;; functions
                (make-hash) ;; fndecls
                (make-hash) ;; eventdefs
                (make-hash) ;; errordefs
                (make-hash) ;; constants
                (make-hash) ;; errors
                (list)      ;; includes
                (make-hash)));; ctx

;; analyze all top-level nodes, outputting into the same data object
(define (analyze-program program data)
  (for-each (lambda (n) (analyze-node n data)) (rest program)))

;; save each macro body in the data object
(define (analyze-defmacro defmacro data)
  (match defmacro
    [(list 'defmacro identifier args takes returns body ...) (hash-set! (program-data-macros data) identifier (list args takes returns body))]
    [_ (error "Invalid defmacro")]))

;; save each function body in the data object
(define (analyze-defn defn data)
  (match defn
    [(list 'defn identifier args takes returns body) (hash-set! (program-data-functions data) identifier (list args takes returns body))]
    [_ (error "Invalid defn")]))

;; save each constant value in the data object
(define (analyze-defconst defconst data)
  (match defconst
    [(list 'defconst identifier value) (hash-set! (program-data-constants data) identifier value)]
    [_ (error "Invalid defconst")]))

(define (analyze-declfn declfn data)
  (match declfn
     [(list 'declfn identifier args vis returns)
      (hash-set! (program-data-fndecls data) identifier args)]
     [_ (error "Invalid declfn")]))

(define (analyze-deferror deferror data)
  (match deferror
    [(list 'deferror identifier args) (hash-set! (program-data-errordefs data) identifier args)]
    [_ (error "Invalid deferror")]))

(define (analyze-defevent defevent data)
  (match defevent
    [(list 'defevent identifier args) (hash-set! (program-data-eventdefs data) identifier args)]
    [_ (error "Invalid defevent")]))


#| IMPORT HANDLING |#
;; macro to save the current context and restore it after the analysis
;; this is used for includes, which need to know the current file's directory
;; so we temporarily set the context to one with the include's filename
(define-syntax with-temp-context
  (syntax-rules ()
    [(_ data ctx body ...)
     (let ([old-ctx (program-data-ctx data)])
       (set-program-data-ctx! data ctx)
       (begin
         body ...
         (set-program-data-ctx! data old-ctx)))]))

(define (analyze-filename filename data)
  (let ([parse-tree (~> filename
                       file->string
                       lex
                       parse
                       syntax->datum)])
    (with-temp-context data (hash 'filename filename)
      (analyze-node parse-tree data))))

(define (analyze-include inc data)
  (let* ([current-file (hash-ref (program-data-ctx data) 'filename)]
         [current-dir (path->string (path-only (path->complete-path current-file)))])
    (parameterize ([current-directory current-dir])
      (match inc
        [(list 'include filename) (let* ([filename (string-append current-dir (format-filename filename))])
                                   (set-program-data-includes! data (cons filename (program-data-includes data)))
                                   (analyze-filename filename data))]
       [_ (error "Invalid include")]))))
#| END IMPORT HANDLING |#

;; top-level node-handler function
(define (analyze-node node [data #f] [ctx #f])
  (let ([data (or data (make-program-data))])
    (when ctx (set-program-data-ctx! data ctx))
    (match (first node)
      ['program (analyze-program node data)]
      ['defmacro (analyze-defmacro node data)]
      ['include (analyze-include node data)]
      ['defconst (analyze-defconst node data)]
      ['defn (analyze-defn node data)]
      ['deferror (analyze-deferror node data)]
      ['defevent (analyze-defevent node data)]
      ['declfn (analyze-declfn node data)])
    data))

(provide (struct-out program-data)
         make-program-data
         analyze-node)
