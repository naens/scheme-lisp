(define (print-all element . elements)
 (display element)
 (if (not (null? elements))
  (apply print-all elements)))
(print-all 300)
(print-all 10 20)
(print-all 1 2 3 4)
