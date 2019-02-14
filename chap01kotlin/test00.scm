(display (case (+ 1 2)
    ((1) "one")
    ((2) "two")
    ((3) "three")
    ((4) "four")
    (else "other number")))

(display (case (+ 7 5)
      ((1 2 3) 'small)
      ((10 11 12) 'big)))
;'big

(display
    (case (- 7 5)
        ((1 2 3) 'small)
        ((10 11 12) 'big)))
;'small

(display (case (string-append "do" "g")
      (("cat" "dog" "mouse") "animal")
      (else "mineral or vegetable")))
;"animal"

(display (case (list 'y 'x)
      (((a b) (x y)) 'forwards)
      (((b a) (y x)) 'backwards)))
;'backwards

(display (case 'x
      ((x) "ex")
      (('x) "quoted ex")))
;"ex"

(display (case (list 'quote 'x)
      ((x) "ex")
      (('x) "quoted ex")))
;"quoted ex"
