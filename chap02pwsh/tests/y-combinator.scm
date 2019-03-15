(define fix
 (let ((d (lambda (w)
           (lambda (f)
            (f (lambda (x) (((w w) f) x)))))))
  (d d)))

(define (meta-fact f)
 (lambda (n)
  (if (= n 0)
   1
   (* n (f (- n 1))))))

(writeln ((fix meta-fact) 3))
; 6

(writeln ((fix meta-fact) 10))
; 3628800
