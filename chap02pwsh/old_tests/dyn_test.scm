(dynamic y 1)
(define (f x)
 (display (list 'f y))
 (set! y (* x 10))
 (display (list 'f y))
 (g 7)
 (display (list 'f y)))
(define (g a)
 (display (list 'g y))
 (set! y a)
 (display (list 'g y)))
(display (list 'top y))
(set! y 3)
(display (list 'top y))
(f 5)
(display (list 'top y))
; top 1
; top 3
; f 3
; f 50
; g 50
; g 7
; f 50
; top 3
