#lang racket/base
;;; lexer.rkt - Tokenization for Huff source code
;;;
;;; This file implements the lexer for the Huff language, which converts
;;; source code text into a stream of tokens. The lexer recognizes keywords,
;;; identifiers, literals, and other elements of the Huff syntax, and produces
;;; tokens that are consumed by the parser.

(require brag/support        ; Provides lexing utilities for Brag parser
         rackunit            ; Testing framework
         "huffparser.rkt"    ; Parser definitions (for token types)
         "utils.rkt"         ; Utility functions
         "assembler.rkt"     ; Assembler definitions
         "huff-ops.rkt")     ; Huff operations

;; Lexical abbreviations for commonly used patterns
;; These define the basic building blocks of tokens
(define-lex-abbrevs
  ;; Numeric digits (0-9)
  [digits               (:+ (char-set "0123456789"))]
  
  ;; String literals enclosed in double quotes
  ;; Allows letters, numbers, underscores, and some punctuation
  [str                  (:seq "\"" (:+ (char-set "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789./")) "\"")]
  
  ;; Alphanumeric characters plus underscore (used in identifiers)
  [digitsOrLetters      (:+ (char-set "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_"))]
  
  ;; Hexadecimal digits (0-9, a-f, A-F)
  [hex-digits           (:+ (char-set "0123456789abcdefABCDEF"))]
  
  ;; Hexadecimal literals prefixed with "0x"
  [hex-literal          (:seq "0x" hex-digits)]
  
  ;; Function visibility modifiers in Ethereum
  [visibility           (:or "payable" "nonpayable" "view")]
  
  ;; Comment patterns - both single-line (//) and multi-line (/* */)
  [comment              (:or
                         (from/stop-before "//" "\n")  ; Single-line comments
                         (from/to "/*" "*/"))]         ; Multi-line comments
  
  ;; Special built-in function for storage allocation
  [free-storage-pointer "FREE_STORAGE_POINTER()"]
  
  ;; Identifier pattern (must start with letter or underscore, followed by letters, digits, or underscore)
  [identifier           (:seq (char-set "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_") (:* digitsOrLetters))])


;; The main lexer function that converts source text into tokens
;; It includes source location information for better error reporting
(define basic-lexer
  (lexer-srcloc
   ;; Newlines are skipped after tokenization
   ["\n"                 (token 'NEWLINE lexeme #:skip? #t)]
   
   ;; Delimiters and operators
   ["("                  (token 'LPAREN lexeme)]     ; Left parenthesis
   [")"                  (token 'RPAREN lexeme)]     ; Right parenthesis
   ["<"                  (token 'LT lexeme)]         ; Less than
   [">"                  (token 'GT lexeme)]         ; Greater than
   ["{"                  (token 'LBRACE lexeme)]     ; Left brace
   ["}"                  (token 'RBRACE lexeme)]     ; Right brace
   ["["                  (token 'LBRACKET lexeme)]   ; Left bracket
   ["]"                  (token 'RBRACKET lexeme)]   ; Right bracket
   [","                  (token 'COMMA lexeme)]      ; Comma
   ["="                  (token 'EQUALS lexeme)]     ; Equals
   [":"                  (token 'COLON lexeme)]      ; Colon
   [";"                  (token 'SEMICOLON lexeme)]  ; Semicolon
   
   ;; Whitespace is skipped
   [whitespace           (token lexeme #:skip? #t)]
   
   ;; Huff language keywords
   ["#define"            (token 'DEFINE lexeme)]     ; Constant definition
   ["#include"           (token 'INCLUDE lexeme)]    ; File inclusion
   ["macro"              (token 'MACRO lexeme)]      ; Macro definition
   ["function"           (token 'FUNCTION lexeme)]   ; Function declaration
   ["fn"                 (token 'FN lexeme)]         ; Function (short form)
   ["event"              (token 'EVENT lexeme)]      ; Event declaration
   ["error"              (token 'ERROR lexeme)]      ; Error declaration
   ["constant"           (token 'CONSTANT lexeme)]   ; Constant declaration
   ["table"              (token 'TABLE lexeme)]      ; Jump table
   ["takes"              (token 'TAKES lexeme)]      ; Parameter declaration
   ["returns"            (token 'RETURNS lexeme)]    ; Return value declaration
   
   ;; Function visibility modifiers
   [visibility           (token 'VISIBILITY lexeme)]
   
   ;; Comments are retained as tokens but could be skipped if needed
   [comment              (token 'COMMENT lexeme)]
   
   ;; Literals
   [digits               (token 'NUMBER lexeme)]     ; Numeric literals
   [str                  (token 'STRING lexeme)]     ; String literals
   [hex-literal          (token 'HEX lexeme)]        ; Hexadecimal literals
   
   ;; Identifiers and special constructs
   [identifier           (token 'IDENTIFIER lexeme)] ; Variable/function names
   [free-storage-pointer (token 'FREE-STORAGE-POINTER lexeme)] ; Special storage pointer
   
   ;; Catch-all for unrecognized characters
   [any-char             (token 'OTHER lexeme)]))

;; Main lexing function
;; Applies the basic lexer to the input (which can be a string or a file port)
;; Returns a sequence of tokens
;;
;; Parameters:
;;   port - A string or input port containing Huff source code
;;
;; Returns:
;;   A sequence of tokens representing the tokenized source code
(define (lex port)
  (apply-port-proc basic-lexer port))

;; Export the main lexing function
(provide lex)
