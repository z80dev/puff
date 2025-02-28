#lang racket/base

(require threading)
(require racket/string)

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

(define (bold text)
  (format "\033[1m~a\033[0m" text))

(define (number->hex num)
  (let ([num-str (number->string num 16)])
    (if (even? (string-length num-str))
        (string-append "0x" num-str)
        (string-append "0x0" num-str))))

(define (byte-length code)
  (apply + (for/list ([c code])
             (~> c
                 string-length
                 (/ 2)))))

(define (byte->hex byte)
  (let ([hex (number->string byte 16)])
    (if (odd? (string-length hex))
        (string-append "0" hex)
        hex)))

(define (word->hex word)
  (let ([hex (number->string word 16)])
    (let ([len (string-length hex)])
      (cond
        [(= len 1) (string-append "000" hex)]
        [(= len 2) (string-append "00" hex)]
        [(= len 3) (string-append "0" hex)]
        [else hex]))))

(define (bytes->hex bytes)
  (string-append "0x" (apply string-append (map byte->hex bytes))))

(define (concat-hex hexes)
  (string-append "0x" (apply string-append hexes)))

(define (format-filename filename)
  (~> filename
      (string-trim "\"")
      (string-trim "./")))

(define (display-return val)
  (displayln val)
  val)

(define (trim-0x str)
  (string-trim str "0x"))

(define (zero-pad-left hex [len 64])
  (let* ([hex (trim-0x hex)]
         [hex-len (string-length hex)]
         [padding-len (- len hex-len)]
         [padding (make-string padding-len #\0)])
    (if (< hex-len len)
        (string-append "0x" padding hex)
        (string-append "0x" hex))))

(define (zero-pad-right hex [len 64])
  (let* ([hex (trim-0x hex)]
         [hex-len (string-length hex)]
         [padding-len (- len hex-len)]
         [padding (make-string padding-len #\0)])
    (if (< hex-len len)
        (string-append "0x" hex padding)
        (string-append "0x" hex))))


(provide print-color
         bold
         number->hex
         byte-length
         format-filename
         byte->hex
         word->hex
         bytes->hex
         concat-hex
         zero-pad-right
         zero-pad-left
         display-return)
