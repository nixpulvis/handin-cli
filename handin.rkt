#lang racket

(require racket/file racket/class pl/client)
(require racket/gui/base)  ; TODO: Remove need for this.

;; Submission Structure.
(define-struct submission (username password filename))

;; This is a command line interface for the PL handin server. To use this
;; program you MUST have the pl package installed in your distribution of
;; Racket.

;; Connect to the handin server, and bind the connection to `connection`.
;; connection : #<handin>
(define connection (handin-connect "pl.barzilay.org" 9770))


;; Command Line Parsing
;; --------------------

; A command is one of:
;; - list
;; - submit
;; commands : [Listof String]
(define commands '("list" "submit"))

;; Retrive the command for the program.
;; command : String
(define command (vector-ref (current-command-line-arguments) 0))

;; Validate `command`.
(unless (ormap (lambda (c) (string=? command c)) commands)
  (error "bad command" command))


;; Commands
;; --------

(define (list)
  ;; Retrieve the active assignments available for hand in, and bind them
  ;; to `available-assignments`.
  ;; available-assignments : [List-of String]
  (define available-assignments (retrieve-active-assignments connection))

  ;; Display the available assignments.
  (displayln available-assignments))

(define (submit)
  ;; Retrieve the submission structure from the command line.
  ;; user-submission : #<submission>
  (define user-submission (command-line
                            #:program "handin submit"
                            #:argv (vector-drop (current-command-line-arguments) 1)
                            #:args (username password filename)
                            (make-submission username password filename)))

  ;; Make a text GUI element.
  (define text (new text%))
  (send text insert (file->string (submission-filename user-submission)))
  (send text save-file ".out" 'same #f)

  ;; Submit a file to scratch assignment.
  (submit-assignment connection
                     (submission-username user-submission)
                     (submission-password user-submission)
                     "hw03"
                     (file->bytes ".out")
                     (lambda () (printf "Committing..."))
                     (lambda (m) (printf "~a~n" m))
                     (lambda (m) (printf "!! ~a~n" m) #t)
                     (lambda (msg styles) 'yes)))


;; Command Running
;; ---------------

(cond [(string=? command "list") (list)]
      [(string=? command "submit") (submit)])


; ;;; PLAYGROUND

; ;; Reform the connection.
; (set! connection (handin-connect "pl.barzilay.org" 9770))

; ;; Get the handin server's copy of the submission for scratch assignment.
; (define file (retrieve-assignment connection "nixpulvis" password "hw02"))

; ;; Write the file.
; (define out (open-output-file ".in"))
; (write-bytes file out)

; ;;;