#lang racket/base

(require racket/file racket/class racket/gui/base pl/client)

;; This is a command line interface for the PL handin server. To use this
;; program you MUST have the pl package installed in your distribution of
;; Racket.

;; Connect to the handin server, and bind the connection to `connection`.
;; connection : #<handin>
(define connection (handin-connect "pl.barzilay.org" 9770))

;; Retrieve the active assignments available for hand in, and bind them
;; to `available-assignments`.
;; available-assignments : [List-of String]
(define available-assignments (retrieve-active-assignments connection))


;;; PLAYGROUND
(define password "<no>")

;; Get the input file.

; TODO: Better parsing.
(define argv (current-command-line-arguments))
(define argc (vector-length argv))

(unless (= argc 1) (error "No file given"))

(define text (new text%))
(send text insert (file->string (vector-ref argv 0)))
(send text save-file ".out" 'same #f)

;; Print the available assignments.
available-assignments

;; Submit a file to scratch assignment.
(submit-assignment connection
                   "nixpulvis"
                   password
                   "hw02"
                   (file->bytes ".out")
                   (lambda () (printf "Committing..."))
                   (lambda (m) (printf "~a~n" m))
                   (lambda (m) (printf "!! ~a~n" m) #t)
                   (lambda (msg styles) 'yes))

;; Reform the connection.
(set! connection (handin-connect "pl.barzilay.org" 9770))

;; Get the handin server's copy of the submission for scratch assignment.
(define file (retrieve-assignment connection "nixpulvis" password "hw02"))

;; Write the file.
(define out (open-output-file ".in"))
(write-bytes file out)

;;;