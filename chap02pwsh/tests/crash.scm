(dynamic (*zero-crasher*) (writeln '*zero-crasher*))

(define (div a b) (if (= b 0) (crash (*zero-crasher*)) (/ a b)))

(div 6 0)
; *ZERO-CRASHER*

(let ((a 5)
      (b 0))
 ;(set! *zero-crasher* (lambda () (writeln 'test:from-let)))
 (dynamic (*zero-crasher*) (writeln 'test:from-let))
 (div a b)
)
; TEST:FROM-LET

(div 6 0)
; *ZERO-CRASHER*
