;;; Arithmetic expressions
(writeln 'arithmetic-expressions)
(writeln 0)
; 0

(write "abc")
(writeln (+ 3 4 5))
; abc12

(writeln (* -3 (- 1 8)))
; 21

(writeln (*))
; 1

(writeln (/ 10 5))
; 2

;;; Value/type check
(writeln 'value-type)
(writeln (number? 3))
; #t

(writeln (number? "abc"))
; #f

(writeln (symbol? 3))
; #f

(write 'empty)
(writeln (symbol? '()))
; EMPTY#f

(write '(list))
(writeln (symbol? (list)))
; (LIST)#f

(write '(list 2))
(writeln (symbol? (list 2)))
; (LIST 2)#f

(writeln (null? (list)))
; #t

(writeln (null? (list 2)))
; #f

;;; Logical expressions, comparisons
(writeln 'logical-expressions)
(writeln (and))
; #t

(writeln (or))
; #f

(writeln (and (> 5 3) (< 2 3)))
; #t

(writeln (or #f #f #f))
; #f

;;; List and Cons
(writeln 'list-and-cons)
(writeln (car (cons (list) 4)))
; '()

(writeln (car (list 4)))
; 4

(writeln (cdr (list 4)))
; '()

(writeln (car (cons 'a 'b)))
; A

(writeln (cdr (cons 'a 'b)))
; B

(writeln '(5 . ((6 . ()) (9 . ()))))
 (5 (6) (9))
(quote (5 . ((6 . ()) (9 . ()))))

'(5 . ((6 . ()) (9 . ())))
