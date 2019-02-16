(case (+ 7 5)
  ((1 2 3) 'small)
  ((10 11 12) 'big))
;'big

(case (- 7 5)
  ((1 2 3) 'small)
  ((10 11 12) 'big))
;'small

;(case (list 'y 'x)
;  (((a b) (x y)) 'forwards)
;  (((b a) (y x)) 'backwards))
;'backwards

(case 'x
  ((x) "ex")
  (('x) "quoted ex"))
;"ex"

;(case (list 'quote 'x)
;  ((x) "ex")
;  (('x) "quoted ex"))
;"quoted ex"
