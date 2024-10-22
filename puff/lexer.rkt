#lang racket/base

(require brag/support rackunit "huffparser.rkt" "utils.rkt" "assembler.rkt" "huff-ops.rkt")

(define-lex-abbrevs
  [digits               (:+ (char-set "0123456789"))]
  [str                  (:seq "\"" (:+ (char-set "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789./")) "\"")]
  [digitsOrLetters      (:+ (char-set "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_"))]
  [hex-digits           (:+ (char-set "0123456789abcdefABCDEF"))]
  [hex-literal          (:seq "0x" hex-digits)]
  [visibility           (:or "payable" "nonpayable" "view")]
  [comment              (:or
                         (from/stop-before "//" "\n")
                         (from/to "/*" "*/"))]
  [free-storage-pointer "FREE_STORAGE_POINTER()"]
  [identifier           (:seq (char-set "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_") (:* digitsOrLetters))])


(define basic-lexer
  (lexer-srcloc
   ["\n"                 (token 'NEWLINE lexeme #:skip? #t)]
   ["("                  (token 'LPAREN lexeme)]
   [")"                  (token 'RPAREN lexeme)]
   ["<"                  (token 'LT lexeme)]
   [">"                  (token 'GT lexeme)]
   ["{"                  (token 'LBRACE lexeme)]
   ["}"                  (token 'RBRACE lexeme)]
   ["["                  (token 'LBRACKET lexeme)]
   ["]"                  (token 'RBRACKET lexeme)]
   [","                  (token 'COMMA lexeme)]
   ["="                  (token 'EQUALS lexeme)]
   [":"                  (token 'COLON lexeme)]
   [";"                  (token 'SEMICOLON lexeme)]
   [whitespace           (token lexeme #:skip? #t)]
   ["#define"            (token 'DEFINE lexeme)]
   ["#include"           (token 'INCLUDE lexeme)]
   ["macro"              (token 'MACRO lexeme)]
   ["function"           (token 'FUNCTION lexeme)]
   ["fn"                 (token 'FN lexeme)]
   ["event"              (token 'EVENT lexeme)]
   ["error"              (token 'ERROR lexeme)]
   ["constant"           (token 'CONSTANT lexeme)]
   ["table"              (token 'TABLE lexeme)]
   ["takes"              (token 'TAKES lexeme)]
   ["returns"            (token 'RETURNS lexeme)]
   [visibility           (token 'VISIBILITY lexeme)]
   [comment              (token 'COMMENT lexeme)]
   [digits               (token 'NUMBER lexeme)]
   [str                  (token 'STRING lexeme)]
   [hex-literal          (token 'HEX lexeme)]
   [identifier           (token 'IDENTIFIER lexeme)]
   [free-storage-pointer (token 'FREE-STORAGE-POINTER lexeme)]
   ;; else
   [any-char             (token 'OTHER lexeme)]))

;; port can be a string or a file
(define (lex port)
  (apply-port-proc basic-lexer port))

(provide lex)
