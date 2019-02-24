;(let ((sum (lambda (a b) (+ a b))))
; (writeln (sum 100 10)))
; 110

;(letrec ((f (lambda (x) (+ (g (+ x 1)) 1)))
;         (g (lambda (x) (* x 10)))
;         (x (g 4)))
;  (+ x (f 7)))    ; (+ (g 4) (+ (g 8) 1)) = (+ 40 (+ 80 1)) = 121
; 121

;(letrec ((fib (lambda (n)
;               (if (< n 2)
;                n
;                (+ (fib (- n 1))
;                   (fib (- n 2)))))))
;  (fib 7))
; 13

;(letrec ((fact (lambda (n)
;               (if (< n 2) n (* n (fact (- n 1)))))))
;  (writeln (fact 7)))
; 6

;(letrec ((even
;           (lambda (lst)
;            (cond
;             ((empty? lst) empty)
;             (else (cons (car lst) (odd (cdr lst)))))))
;         (odd
;           (lambda (lst)
;            (cond
;             ((empty? lst) empty)
;             (else (even (cdr lst)))))))
;  (writeln (even '(1 2 3 4 5)))
;  (writeln (odd '(1 2 3 4 5))))
; (2 4)
; (1 3 5)

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

;(define (counter)
; (let ((c 0))
;  (lambda (cmd)
;   (case cmd
;     ((inc) (set! c (+ c 1)))
;     ((dec) (set! c (- c 1)))
;     ((pr) (writeln c))))))
;(define cnt (counter))
;(cnt 'pr)
; 0

; (cnt 'inc)
; (cnt 'pr)
; 1

; (cnt 'inc)
; (cnt 'inc)
; (cnt 'pr)
; 3

; (cnt 'dec)
; (cnt 'pr)
; 2

; (cnt 'dec)
; (cnt 'dec)
; (cnt 'pr)
; 0
