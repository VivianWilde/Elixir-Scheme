(define list (lambdav (args) args))

(define nil '())

(define cadr (lambda (x) (car (cdr x))))


;;; HOFs
(define map
  (lambda (f s) (if (null? s)
       s
       (cons (f (car s)) (map f (cdr s))))))


(define filter
  (lambda (f s) (if (null? s)
       s
       (if (f? (car s))
           (cons (car s) (filter f? (cdr s)))))))

(define all
  (lambda (f? s) (if (null? s)
       #t
       (if (f? (car s)) (all f? (cdr s)) (#f))
       )))

(define any
  (lambda (f? s) (if (null? s)
       #f
       if (f? (car s)
              #t
              (any f? (cdr s)))
       ))
  )
