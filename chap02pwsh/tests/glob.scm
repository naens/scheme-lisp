;;; variables
(define y 5)
(writeln y)
; 4

(define t "abcde")
(writeln t)
; "abcd"


(writeln 'functions)
(define ly 1)
(define (lf x)
 (writeln (list 'lf ly))
 (set! ly (* x 10))
 (writeln (list 'lf ly))
 (lg 7)
 (writeln (list 'lf ly)))
(define (lg a)
 (writeln (list 'lg ly))
 (set! ly a)
 (writeln (list 'lg ly)))

(writeln (list 'ltop ly))
; (LTOP 1)

(set! ly 3)
(writeln (list 'ltop ly))
; (LTOP 3)

(lf 5)
; (LF 3)
; (LF 50)
; (LG 50)
; (LG 7)
; (LF 7)

(writeln (list 'ltop ly))
; (LTOP 7)

(writeln 'Let)
(let ((a 2)
      (b 3))
 (writeln a)
 (let ((a 3))
  (writeln a)
  (writeln (+ a b)))
 (writeln (+ a b)))
; 2
; 3
; 6
; 5


(writeln 'recursion)
(define (fact x)
 (cond ((<= x 2) x)
  (#t  (* x (fact (- x 1))))))
(writeln (fact 1))
; 1

(writeln (fact 2))
; 2

(writeln (fact 3))
; 6

(writeln (fact 4))
; 24

(writeln (fact 5))
; 120


(writeln 'mutual-recursion)
(define (even lst)
 (cond
  ((empty? lst) empty)
  (else (cons (car lst) (odd (cdr lst))))))

(define (odd lst)
 (cond
  ((empty? lst) empty)
  (else (even (cdr lst)))))

(writeln (even '(1 2 3 4 5)))
; (2 4)

(writeln (odd '(1 2 3 4 5)))
; (1 3 5)
