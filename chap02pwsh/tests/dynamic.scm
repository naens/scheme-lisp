(writeln 'variables)
;;; dynamic variables
(dynamic x 4)
(writeln x)
; 4
(dynamic s "abcd")
(writeln s)
; "abcd"


(writeln 'functions)
(dynamic y 1)
(define (f x)
 (writeln (list 'f y))
 (set! y (* x 10))
 (writeln (list 'f y))
 (g 7)
 (writeln (list 'f y)))
(define (g a)
 (writeln (list 'g y))
 (set! y a)
 (writeln (list 'g y)))

(writeln (list 'top y))
; (TOP 1)

(set! y 3)
(writeln (list 'top y))
; (TOP 3)

(f 5)
; (F 3)
; (F 50)
; (G 50)
; (G 7)
; (F 50)

(writeln (list 'top y))
; (TOP 3)
