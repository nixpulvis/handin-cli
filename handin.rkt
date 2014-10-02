#lang racket

(require racket/file racket/class pl/client)
(require racket/gui/base)  ; TODO: Remove need for this.

;; This is a command line interface for the PL handin server. To use this
;; program you MUST have the pl package installed in your distribution of
;; Racket.

;; General
;; -------


;; Submission structure.
(define-struct submission (assignment filename))


;; Auth structure.
(define-struct auth (username password))


;; A [Listof A] -> Boolean
(define (member? element list)
  (ormap (lambda (e) (equal? e element)) list))


;; -> String
(define (get-string)
  (read-line (current-input-port)))


;; -> Auth
(define (get-auth)
  (printf "username: ")
  (define username (get-string))
  (printf "password: ")
  (define password (get-string))  ; TODO: Hide the typing.
  (make-auth username password))


; String [Listof A] -> A  TODO: More info on A.
; A is one of:
; - 'yes-no
; - ...
(define (prompt msg styles)
  (printf "~a~n" msg)
  (cond [(member? 'yes-no styles)
         (printf "(yes/no)~n")
         (string->symbol (get-string))]
        [else 'no]))


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
                            #:args (assignment filename)
                            (make-submission assignment filename)))

  (define tmpfile ".out")

  ;; Ask for username and password.
  ;; user-auth: #<auth>
  (define user-auth (get-auth))

  ;; Make a text GUI element.
  ;; HACK: This is kinda gross, we should be able to convert to the
  ;; proper file format without a GUI.
  (define text (new text%))
  (send text insert (file->string (submission-filename user-submission)))
  (send text save-file tmpfile 'same #f)

  ;; Submit a file to scratch assignment.
  (submit-assignment connection
                     (auth-username user-auth)
                     (auth-password user-auth)
                     (submission-assignment user-submission)
                     (file->bytes ".out")
                     (lambda ()  (printf "committing~n"))
                     (lambda (m) (printf "~a~n" m))
                     (lambda (m) (printf "! ~a~n" m) #t)
                     prompt)

  (delete-file tmpfile))


(define (retrieve connection)
  ;; Retrieve the submission structure from the command line.
  ;; user-submission : #<submission>
  (define user-submission (command-line
                            #:program "handin retrieve"
                            #:argv (vector-drop (current-command-line-arguments) 1)
                            #:args (assignment filename)
                            (make-submission assignment filename)))

  (define tmpfile ".in")

  ;; Create the temporary writing file.
  (define in (open-output-file tmpfile))

  ;; Ask for username and password.
  ;; user-auth: #<auth>
  (define user-auth (get-auth))

  ;; Get the handin server's copy of the submission for scratch assignment.
  (define file (retrieve-assignment connection
                                    (auth-username user-auth)
                                    (auth-password user-auth)
                                    (submission-assignment user-submission)))

  ;; Write the file from the server.
  (write-bytes file in)

  ;; Make a text GUI element.
  ;; HACK: This is kinda gross, we should be able to convert to the
  ;; proper file format without a GUI.
  (define text (new text%))
  (send text load-file tmpfile)

  ;; Create the writing file.
  (define out (open-output-file (submission-filename user-submission)))
  (write-bytes (string->bytes/utf-8 (send text get-text)) out)

  (delete-file tmpfile))


;; Command Line Parsing
;; --------------------


; A command is one of:
;; - list
;; - submit
;; - retrieve
;; commands : [Listof String]
(define commands '("list" "submit" "retrieve"))


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
      [(string=? command "submit") (submit connection)]
      [(string=? command "retrieve") (retrieve connection)])
