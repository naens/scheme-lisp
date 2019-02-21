(define (sum a b)
  (if (= a 0)
      b
      (sum (- a 1) (+ 1 b))))

(define (sum-display a b)
  (display a)
  (if (= a 0)
      b
      (sum-display (- a 1) (+ 1 b))))
(sum 4 3)
