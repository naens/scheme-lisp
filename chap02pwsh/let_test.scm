(let ((a 3)
      (b (+ 5 7))
      (c (* 10 3)))
 (display (+ a b c))  ; 45
 (- c a b))           ; 15

(let ((f 'nil)
      (g 'nil)
      (x 'nil))
 (set! f (lambda (x) (+ (g (+ x 1)) 1)))
 (set! g (lambda (x) (* x 10)))
 (set! x (g 4))
 (display x)
 (display (f 7))
 (+ x (f 7)))
