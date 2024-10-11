#lang racket
(require brag/support rackunit "huffparser.rkt")

(define-lex-abbrevs
  [digits               (:+ (char-set "0123456789"))]
  [str              (:seq "\"" (:+ (char-set "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789./")) "\"")]
  [digitsOrLetters      (:+ (char-set "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_"))]
  [hex-digits           (:+ (char-set "0123456789abcdefABCDEF"))]
  [opcode               (:+ "calldataload" "mstore" "return" "add" "log3" "jump" "sub" "swap1" "codecopy" "stop" "dup1" "dup2" "jumpi" "pop" "mstore" "msize" "revert")]
  [hex-literal          (:seq "0x" hex-digits)]
  [funcdef              (from/stop-before (:seq "#define function ") (:or " /" "\n"))]
  [eventdef             (from/stop-before (:seq "#define event ") (:or " /" "\n"))]
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
   ["#include" (token 'INCLUDE lexeme)]
   ["macro"              (token 'MACRO lexeme)]
   ["function"           (token 'FUNCTION lexeme)]
   ["fn"                 (token 'FN lexeme)]
   ["event"              (token 'EVENT lexeme)]
   ["error"              (token 'ERROR lexeme)]
   ["constant"           (token 'CONSTANT lexeme)]
   ["table"             (token 'TABLE lexeme)]
   ["takes"              (token 'TAKES lexeme)]
   ["returns"            (token 'RETURNS lexeme)]
   ["event"              (token 'EVENT lexeme)]
   ["error"              (token 'ERROR lexeme)]
   ["constant"           (token 'CONSTANT lexeme)]
   ["takes"              (token 'TAKES lexeme)]
   ["returns"            (token 'RETURNS lexeme)]
   ["takes"              (token 'TAKES lexeme)]
   ["returns"            (token 'RETURNS lexeme)]
   ["event"              (token 'EVENT lexeme)]
   ["error"              (token 'ERROR lexeme)]
   ["constant"           (token 'CONSTANT lexeme)]
   ["takes"              (token 'TAKES lexeme)]
   ["returns"            (token 'RETURNS lexeme)]
   [opcode               (token 'OPCODE lexeme)]
   [comment              (token 'COMMENT lexeme)]
   [digits               (token 'NUMBER lexeme)]
   [str                  (token 'STRING lexeme)]
   [hex-literal          (token 'HEX lexeme)]
   [funcdef              (token 'FUNCDEFINE lexeme)]
   [eventdef             (token 'EVENTDEFINE lexeme)]
   [identifier           (token 'IDENTIFIER lexeme)]
   [free-storage-pointer (token 'FREE_STORAGE_POINTER lexeme)]
   ;; else
   [any-char             (token 'OTHER lexeme)]))


;;(provide basic-lexer)

(define (print-parse-tree tree [indent 0])
  (define (print-indent)
    (for ([i (in-range indent)])
      (display "  ")))

  (cond
    [(list? tree)
     (print-indent)
     (printf "(~a\n" (car tree))
     (for ([item (in-list (cdr tree))])
       (print-parse-tree item (add1 indent)))
     (print-indent)
     (display ")\n")]
    [else
     (print-indent)
     (printf "~a\n" tree)]))

(define           (lex str)
  (apply-port-proc basic-lexer str))

(define (print-color text color)
  (define color-code
    (case color
      [(black) "30"]
      [(red) "31"]
      [(green) "32"]
      [(yellow) "33"]
      [(blue) "34"]
      [(magenta) "35"]
      [(cyan) "36"]
      [(white) "37"]
      [else "0"]))  ; default to normal text

  (printf "\033[~am~a\033[0m" color-code text))


;; iterate over each file under examples and parse it
(define (parse-all-examples)
  (for ([file (in-directory "examples")])
    ;; skip if is a directory
    (unless (directory-exists? file)
      (define program (file->string file))
        ;; print filename
      (display "Parsing ")
      (display file)
      (display "... ")
      (define parse-tree (parse (lex program)))
      (print-color "OK" 'green)
      (newline)
      (syntax->datum parse-tree))))

(parse-all-examples)
