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

; dynamic scope test
(dynamic a1 1)
(dynamic (fn1 b)
  (list a1 b))
(let ((a1 2))
 (writeln (fn1 3)))
; (2 3)

; same thing in lexical scope
(define a2 1)
(define (fn2 b)
  (list a2 b))
(let ((a2 2))
 (writeln (fn2 3)))
; (1 3)
