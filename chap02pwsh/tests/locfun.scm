(let ((sum (lambda (a b) (+ a b))))
 (writeln (sum 100 10)))
; 110

(letrec ((f (lambda (x) (+ (g (+ x 1)) 1)))
         (g (lambda (x) (* x 10)))
         (x (g 4)))
  (writeln (+ x (f 7))))    ; (+ (g 4) (+ (g 8) 1)) = (+ 40 (+ 80 1)) = 121
; 121

(letrec ((f (lambda (x) (+ (g (+ x 1)) 1)))
         (x (g 4))
         (g (lambda (x) (* x 10))))
  (writeln (+ x (f 7))))    ; (+ (g 4) (+ (g 8) 1)) = (+ 40 (+ 80 1)) = 121
; 121

(letrec ((fib (lambda (n)
               (if (< n 2)
                n
                (+ (fib (- n 1))
                   (fib (- n 2)))))))
  (writeln (fib 7)))
; 13

(letrec ((fact (lambda (n)
               (if (< n 2) n (* n (fact (- n 1)))))))
  (writeln (fact 5)))
; 120

; letrec version
(letrec ((odd
           (lambda (lst)
            (cond
             ((empty? lst) empty)
             (else (cons (car lst) (even (cdr lst)))))))
         (even
           (lambda (lst)
            (cond
             ((empty? lst) empty)
             (else (odd (cdr lst)))))))
  (writeln (even '(1 2 3 4 5 6)))
  (writeln (odd '(1 2 3 4 5 6))))
; (2 4 6)
; (1 3 5)

; global version
(define (odd lst)
 (cond
  ((empty? lst) empty)
  (else (cons (car lst) (even (cdr lst))))))
(define (even lst)
 (cond
  ((empty? lst) empty)
  (else (odd (cdr lst)))))
(writeln (even '(1 2 3 4 5 6)))
(writeln (odd '(1 2 3 4 5 6)))
; (2 4 6)
; (1 3 5)

; local version
(begin
  (define (odd lst)
   (cond
    ((empty? lst) empty)
    (else (cons (car lst) (even (cdr lst))))))
  (define (even lst)
   (cond
    ((empty? lst) empty)
    (else (odd (cdr lst)))))
  (writeln (even '(1 2 3 4 5 6)))
  (writeln (odd '(1 2 3 4 5 6))))
; (2 4 6)
; (1 3 5)

(define (f c)
 (define (ic k)
  (set! c (+ c k))
  (writeln c))
 (ic 1)
 (ic 4)
 (ic 9))
(f 0)
; 1
; 5
; 14

(let ((c 0))
 (define (ic k)
  (set! c (+ c k))
  (writeln c))
 (ic 1)
 (ic 4)
 (ic 9))
; 1
; 5
; 14

(define (counter n)
 (let ((c 0))
  (lambda (cmd)
   (case cmd
     ((inc) (set! c (+ c n)))
     ((dec) (set! c (- c n)))
     ((pr) (writeln c))))))
(define cnt (counter 3))
(cnt 'pr)
; 0

(cnt 'inc)
(cnt 'pr)
; 3

(cnt 'inc)
(cnt 'inc)
(cnt 'pr)
; 9

(cnt 'dec)
(cnt 'pr)
; 6

(cnt 'dec)
(cnt 'dec)
(cnt 'pr)
; 0
