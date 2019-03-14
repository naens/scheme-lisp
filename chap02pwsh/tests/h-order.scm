(define (map l f)
  (cond ((null? l) '())
        (#t (cons (f (car l)) (map (cdr l) f)))))

(define (div2 x) (/ x 2))

(let ((n 4))
 (writeln (map '(4 80 1200) (lambda (x) (/ x n)))))
; (1 20 300)

(writeln (div2 8))
; 4

(writeln (map '(2 4 6 8) div2))
; (1 2 3 4)

(begin
  (define (fact x)
   (cond ((<= x 2) x)
    (#t  (* x (fact (- x 1))))))
  (writeln (fact 5)))
; 120

(define (fact x)
 (cond ((<= x 2) x)
  (#t  (* x (fact (- x 1))))))
(writeln (fact 3))
; 6

(writeln (fact 2))
; 2

(writeln (fact 3))
; 6

(writeln (fact 4))
; 24
