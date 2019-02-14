(define (mksum a . b)
  (if (null? b) a (+ a (apply mksum b))))

(define (map fun list)
 (if (pair? list)
  (cons (fun (car list)) (map fun (cdr list)))
  nil))

