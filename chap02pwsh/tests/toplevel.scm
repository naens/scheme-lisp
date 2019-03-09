(define (toplevel)
 (writeln (eval (read)))
 (toplevel))
(toplevel)
