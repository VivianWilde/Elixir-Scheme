(define define-macro (mac (header body) (list 'define (car header) (list 'mac (cdr header) body))))

(define-macro (let* bindings body)
  ; Bind vars in order, later bindings shadow earlier ones, and exprs in later bindings can refer to previous bindings.
  (if (null? bindings)
      body
    `(let ((,(car bindings))) (let* ,(cdr bindings) ,body))
    ))

(define-macro (quasiquote expr)
  (if (atom? expr)
      (list 'quote expr)
      (if (equal? (car expr) 'unquote)
          (eval (car (cdr expr)))
          (list 'cons (list 'quasiquote (car expr)) (list 'quasiquote (cdr expr)))
          )))

(define-macro (quasiquote expr)
  ; This is like let-to-lambda, in that it has to tree-recursively analyse the entire expression.
  (cond
   ((atom? expr) (list 'quote expr))
   ((equal? (car expr) 'unquote) (eval (cadr expr)))
   ;; ((equal? (car expr) 'unquote-splicing) (cons (eval (cdr expr)) ))
   (else (list 'cons (list 'quasiquote (car expr)) (list 'quasiquote (cdr expr))))
  ))

(define-macro (let bindings body)
  `(apply (lambda ,(map car bindings) ,body) ,(map cadr bindings))
  )

(define-macro (expect expr output)
  (let ((result (eval expr)))
    (equal? result output)
    )
)

(define-macro (delay expr)
  `(lambda () ,expr)
  )
(define-macro (proc-as-macro proc args)
  ;; Take a procedure call like let-to-lambda and basically lets it behave like a macro. So you don't need to quote the expr you pass in, and you don't need to manually call eval on the return code
  `(apply ,proc ,(map (lambda (expr) `(quote ,expr)) args))
  )

(define-macro (cond clauses)
  `(let* ((clause ,(car clauses))
         ((test ,(car clause)))
         ((result ,(cadr clause))))
    (if (or test (eq? test 'else))
        result
        (cond ,(cdr clauses)))
    )
)


(define list (lambdav (args)


                      ))

(define-macro (lambdav bindings body)
  `(lambda (seq) ,() )

  )
