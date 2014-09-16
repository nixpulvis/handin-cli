#lang racket/base

(require racket/file pl/client)

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

;; Print the available assignments.
available-assignments

;; Get the input file.

; TODO: Better parsing.
(define argv (current-command-line-arguments))
(define argc (vector-length argv))

(unless (= argc 1) (error "No file given"))

;; Submit a file to scratch assignment.
(submit-assignment connection
                   "nixpulvis"
                   "<no>"
                   "hw02"
                   (file->bytes (vector-ref argv 0))
                   (lambda () (printf "Committing..."))
                   (lambda (m) (printf "~a~n" m))
                   (lambda (m) (printf "~a~n" m))
                   (lambda (a b) 1))

;; Reform the connection.
(set! connection (handin-connect "pl.barzilay.org" 9770))

;; Get the handin server's copy of the submission for scratch assignment.
(define file (retrieve-assignment connection "nixpulvis" "iBookG4lolttyl!" "hw02"))

;; Write the file.
(define out (open-output-file "foo.txt"))
(write-bytes file out)

;;;