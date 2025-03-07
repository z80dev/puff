#lang racket/base
;;; analysis.rkt - Parse tree analysis for Huff code
;;;
;;; This file contains the code for analyzing the parsed Huff AST
;;; and extracting program data such as macros, functions, constants,
;;; and other definitions. It builds a comprehensive data structure
;;; that represents all the components of a Huff program, which is then
;;; used by the compiler to generate bytecode.

(require "lexer.rkt"        ; Tokenizer
         "huffparser.rkt"   ; Parser
         "utils.rkt"        ; Common utilities
         threading          ; Threading macros (~>)
         racket/list        ; List operations
         racket/match       ; Pattern matching
         racket/file        ; File operations
         racket/path)       ; Path operations

;; program-data: Structure containing all necessary data for compiling a Huff contract
;;
;; Fields:
;; - labels: Hash map of jump labels to their positions
;; - macros: Hash map of macro names to their definitions (args, takes, returns, body)
;; - functions: Hash map of function names to their definitions
;; - fndecls: Hash map of function declarations (used for function signatures)
;; - eventdefs: Hash map of event definitions
;; - errordefs: Hash map of error definitions
;; - constants: Hash map of constant names to their values
;; - errors: Hash map for error tracking
;; - includes: List of included file paths
;; - ctx: Context hash map (e.g., current filename for resolving includes)
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

;; make-program-data: -> program-data
;; Creates a new empty program-data structure with initialized hash maps
(define (make-program-data)
  (program-data (make-hash) ;; labels - Jump labels used in the code
                (make-hash) ;; macros - Macro definitions
                (make-hash) ;; functions - Function definitions
                (make-hash) ;; fndecls - Function declarations
                (make-hash) ;; eventdefs - Event definitions
                (make-hash) ;; errordefs - Error definitions
                (make-hash) ;; constants - Constant definitions
                (make-hash) ;; errors - Error tracking
                (list)      ;; includes - List of included files
                (make-hash)));; ctx - Context for file resolution

;; analyze-program: (list 'program node ...) program-data -> void
;; Analyzes all top-level nodes in a program, updating the program-data
;; structure with the results
(define (analyze-program program data)
  (for-each (lambda (n) (analyze-node n data)) (rest program)))

;; analyze-defmacro: (list 'defmacro identifier args takes returns body ...) program-data -> void
;; Extracts and stores a macro definition in the program-data
;;
;; Format of macro entry: (list args takes returns body)
;; - args: Macro arguments
;; - takes: Stack inputs
;; - returns: Stack outputs
;; - body: Macro implementation
(define (analyze-defmacro defmacro data)
  (match defmacro
    [(list 'defmacro identifier args takes returns body ...) 
     (hash-set! (program-data-macros data) identifier (list args takes returns body))]
    [_ (error "Invalid defmacro")]))

;; analyze-defn: (list 'defn identifier args takes returns body) program-data -> void
;; Extracts and stores a function definition in the program-data
;;
;; Format of function entry: (list args takes returns body)
;; - args: Function arguments
;; - takes: Stack inputs
;; - returns: Stack outputs
;; - body: Function implementation
(define (analyze-defn defn data)
  (match defn
    [(list 'defn identifier args takes returns body) 
     (hash-set! (program-data-functions data) identifier (list args takes returns body))]
    [_ (error "Invalid defn")]))

;; analyze-defconst: (list 'defconst identifier value) program-data -> void
;; Extracts and stores a constant definition in the program-data
(define (analyze-defconst defconst data)
  (match defconst
    [(list 'defconst identifier value) 
     (hash-set! (program-data-constants data) identifier value)]
    [_ (error "Invalid defconst")]))

;; analyze-declfn: (list 'declfn identifier args vis returns) program-data -> void
;; Extracts and stores a function declaration in the program-data
;; Used primarily for generating function signatures
(define (analyze-declfn declfn data)
  (match declfn
     [(list 'declfn identifier args vis returns)
      (hash-set! (program-data-fndecls data) identifier args)]
     [_ (error "Invalid declfn")]))

;; analyze-deferror: (list 'deferror identifier args) program-data -> void
;; Extracts and stores an error definition in the program-data
(define (analyze-deferror deferror data)
  (match deferror
    [(list 'deferror identifier args) 
     (hash-set! (program-data-errordefs data) identifier args)]
    [_ (error "Invalid deferror")]))

;; analyze-defevent: (list 'defevent identifier args) program-data -> void
;; Extracts and stores an event definition in the program-data
(define (analyze-defevent defevent data)
  (match defevent
    [(list 'defevent identifier args) 
     (hash-set! (program-data-eventdefs data) identifier args)]
    [_ (error "Invalid defevent")]))


;;; IMPORT HANDLING ;;;

;; with-temp-context: program-data hash-map expr ... -> any
;; Temporarily changes the context of program-data for executing expressions
;; This is used for include handling to track the current file path
;; Restores the original context after execution
(define-syntax with-temp-context
  (syntax-rules ()
    [(_ data ctx body ...)
     (let ([old-ctx (program-data-ctx data)])
       (set-program-data-ctx! data ctx)
       (begin
         body ...
         (set-program-data-ctx! data old-ctx)))]))

;; analyze-filename: string program-data -> void
;; Reads a file, lexes it, parses it, and analyzes the parse tree
;; Used for processing included files
(define (analyze-filename filename data)
  (let ([parse-tree (~> filename
                       file->string       ; Read file to string
                       lex                ; Convert to tokens
                       parse              ; Parse tokens to AST
                       syntax->datum)])   ; Convert to plain data
    (with-temp-context data (hash 'filename filename)
      (analyze-node parse-tree data))))

;; analyze-include: (list 'include filename) program-data -> void
;; Processes an include directive by resolving the file path
;; and analyzing the included file's content
(define (analyze-include inc data)
  (let* ([current-file (hash-ref (program-data-ctx data) 'filename)]
         [current-dir (path->string (path-only (path->complete-path current-file)))])
    (parameterize ([current-directory current-dir])
      (match inc
        [(list 'include filename) 
         (let* ([filename (string-append current-dir (format-filename filename))])
           ; Add to the list of included files
           (set-program-data-includes! data (cons filename (program-data-includes data)))
           ; Analyze the included file
           (analyze-filename filename data))]
       [_ (error "Invalid include")]))))

;;; END IMPORT HANDLING ;;;

;; analyze-node: any [program-data] [hash-map] -> program-data
;; Top-level node analysis dispatcher function
;; Analyzes a node from the parse tree and updates the program-data accordingly
;;
;; Parameters:
;; - node: The AST node to analyze
;; - data: Optional program-data to update (creates new if not provided)
;; - ctx: Optional context hash-map for resolving includes
;;
;; Returns:
;; - The updated program-data structure
(define (analyze-node node [data #f] [ctx #f])
  (let ([data (or data (make-program-data))])
    (when ctx (set-program-data-ctx! data ctx))
    ; Dispatch based on the node type
    (match (first node)
      ['program (analyze-program node data)]    ; Program (top-level)
      ['defmacro (analyze-defmacro node data)]  ; Macro definition
      ['include (analyze-include node data)]    ; Include directive
      ['defconst (analyze-defconst node data)]  ; Constant definition
      ['defn (analyze-defn node data)]          ; Function definition
      ['deferror (analyze-deferror node data)]  ; Error definition 
      ['defevent (analyze-defevent node data)]  ; Event definition
      ['declfn (analyze-declfn node data)])     ; Function declaration
    data))

;; Export the program-data struct with accessors/mutators
;; and the functions for creating and analyzing program data
(provide (struct-out program-data)  ; Export program-data structure definition
         make-program-data          ; Export constructor
         analyze-node)              ; Export analysis entry point
