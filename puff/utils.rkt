#lang racket

(require threading)

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

(define (bytes->hex bytes)
  (string-append "0x" (apply string-append (map byte->hex bytes))))

(define (concat-hex hexes)
  (string-append "0x" (apply string-append hexes)))

(define (format-filename filename)
  (~> filename
      (string-trim "\"")
      (string-trim "./")))

(provide print-color
         bold
         number->hex
         byte-length
         format-filename
         byte->hex
         bytes->hex
         concat-hex)
