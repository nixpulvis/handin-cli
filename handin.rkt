#lang racket

(require racket/file racket/class pl/client)
(require racket/gui/base)  ; TODO: Remove need for this.

;; This is a command line interface for the PL handin server. To use this
;; program you MUST have the pl package installed in your distribution of
;; Racket.

;; General
;; -------


;; A [Listof A] -> Boolean
(define (member? element list)
  (ormap (lambda (e) (equal? e element)) list))


;; -> Symbol
(define (get-symbol)
  (string->symbol (read-line (current-input-port))))


; String [Listof A] -> A  TODO: More info on A.
; A is one of:
; - 'yes-no
; - ...
(define (prompt msg styles)
  (printf "~a~n" msg)
  (cond [(member? 'yes-no styles)
         (printf "(yes/no)~n")
         (get-symbol)]
        [else 'no]))


;; Submission Structure.
(define-struct submission (username password assignment filename))


;; Commands
;; --------

;; List the avalible assignments.
(define (list connection)
  ;; Retrieve the active assignments available for hand in, and bind them
  ;; to `available-assignments`.
  ;; available-assignments : [List-of String]
  (define available-assignments (retrieve-active-assignments connection))

  ;; Display the available assignments.
  (printf "~a~n" available-assignments))


;; Submit some homework.
(define (submit connection)
  ;; Retrieve the submission structure from the command line.
  ;; user-submission : #<submission>
  (define user-submission (command-line
                            #:program "handin submit"
                            #:argv (vector-drop (current-command-line-arguments) 1)
                            #:args (username password assignment filename)
                            (make-submission username password assignment filename)))

  ;; Make a text GUI element.
  (define text (new text%))
  (send text insert (file->string (submission-filename user-submission)))
  (send text save-file ".out" 'same #f)

  ;; Submit a file to scratch assignment.
  (submit-assignment connection
                     (submission-username user-submission)
                     (submission-password user-submission)
                     (submission-assignment user-submission)
                     (file->bytes ".out")
                     (lambda ()  (printf "committing~n"))
                     (lambda (m) (printf "~a~n" m))
                     (lambda (m) (printf "! ~a~n" m) #t)
                     prompt))


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
(unless (member? command commands)
  (error "bad command" command))


;; Command Running
;; ---------------


;; Connect to the handin server, and bind the connection to `connection`.
;; connection : #<handin>
(define connection (handin-connect "pl.barzilay.org" 9770))


(cond [(string=? command "list") (list connection)]
      [(string=? command "submit") (submit connection)])


; ;;; PLAYGROUND

; ;; Reform the connection.
; (set! connection (handin-connect "pl.barzilay.org" 9770))

; ;; Get the handin server's copy of the submission for scratch assignment.
; (define file (retrieve-assignment connection "nixpulvis" password "hw02"))

; ;; Write the file.
; (define out (open-output-file ".in"))
; (write-bytes file out)

; ;;;