;; This is an attempt at solving the knight tour problem for a 5*5
;; board, unfortunately it takes too long.  So I leave it here just in
;; case.  Of course it's not tested and as I don't know good practice
;; for dynamic scope, I think the coding style is rather bad.  I leave
;; it here for the future.  Perhaps I or someone will need it someday.

(dynamic moves '((2 1) (1 2) (-1 2) (-2 1) (-2 -1) (-1 -2) (1 -2) (2 -1)))

(dynamic n nil)
(dynamic x nil)
(dynamic y nil)
(dynamic r nil)
(dynamic m nil)
(dynamic move nil)
(dynamic move-i nil)
(dynamic sol nil)

(dynamic (member x list)
         (if (null? list)
          #f
          (or (equal? x (car list)) (member x (cdr list)))))

(dynamic (is-safe n x y sol)
  (and (>= x 0)
       (>= y 0)
       (< x n)
       (< y n)
       (not (member (list x y) sol))))

(dynamic (flp m)
  ;;(writeln (list 'for-loop m))
  (cond ((null? m) nil)
        (else
         (set! move (car m))
         (set! r (fn-tr (car m) (+ x (car move)) (+ y (car (cdr move)))))
         (if r r (flp (cdr m))))))

(dynamic (fn-tr m x y)
  ;;(writeln (list 'fn-tr m x y))
  (if (is-safe n x y sol)
   (solve-kt n x y (+ move-i 1) (cons (list x y) sol))
   nil))

(dynamic (solve-kt n x y move-i sol)
  (writeln (list 'solve-kt move-i))
  (if (= move-i (* n n)) sol (flp moves)))

(writeln (solve-kt 5 0 0 1 '((0 0))))
