#lang racket/base

(require pl/client)

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

(define semaphore (make-semaphore))

;; Submit a file to scratch assignment.
(submit-assignment connection
                   "nixpulvis"
                   "<no>"
                   "scratch"
                   #"(+ 1 2)"
                   (lambda () (display "yay1?")
                              (semaphore-post semaphore))
                   (lambda () (display "yay2?"))
                   (lambda () (display "yay3?"))
                   (lambda (a b) 1))

(semaphore-wait semaphore)

(set! connection (handin-connect "pl.barzilay.org" 9770))

;; Get the handin server's copy of the submission for scratch assignment.
(retrieve-assignment connection "nixpulvis" "iBookG4lolttyl!" "scratch")

;;;