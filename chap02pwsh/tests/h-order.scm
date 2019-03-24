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

(define (map-mult l n)
 (writeln (map l (lambda (x) (* x n)))))

(map-mult '(1 2 3 4) 10)
; (10 20 30 40)

(define (fact1 x)
 (cond ((<= x 2) x)
  (#t  (* x (fact1 (- x 1))))))
(writeln (fact1 5))
; 120

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


(define (fold-if l fold-fun filter-fun base-val)
  (cond ((null? l) base-val)
        ((filter-fun (car l))
         (fold-fun (car l)
                   (fold-if (cdr l) fold-fun filter-fun base-val)))
        (else
         (fold-if (cdr l) fold-fun filter-fun base-val))))

(writeln (fold-if '(1 2 3 4 5 6 7 8 9 10)
                  *
                  (lambda (x) (= (modulo x 3) 0))
                  1))
; 162
(fold-if '(9) * (lambda (x) (= (modulo x 3) 0)) 1)

(define (fn f c)
  (+ (f 5) c))

(writeln (fn (lambda (x) (* x 100)) 3))
; 503


(define (make-multiplier n)
  (lambda (x)
    (* x n)))

(let ((mul5 (make-multiplier 5))
      (mul2 (make-multiplier 2)))
  (writeln (+ (mul5 6) (mul2 4))))
; 38
