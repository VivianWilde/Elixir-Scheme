# Interpreter

A simple Scheme interpreter made in Elixir. Supports primitives, as well as function and variable definitions (both standard and lambda syntax) and application, along with a few other neat features such as variadic lambdas.

To run it, run `iex -S mix` and then `Interpreter.main`. This should open up a scheme REPL you can work with. It uses words rather than symbols for some functions such as `add` rather than `+`.

``` scheme<!--  -->
iex(1)> Interpreter.main
Welcome to Scheme, Elixir edition
> (define map (lambda (f s) (if (null? s) s (cons (f (car s)) (map f (cdr s))))))
:map
> (define list (lambdav (args) args))
:list
> (map (lambda (x) (add x x)) (list 1 2 3 4 5))
[2, 4, 6, 8, 10]
> (add 5 6)
11
> (define x 5)
:x
> (add x 6)
11
```
