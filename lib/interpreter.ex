defmodule Interpreter do
  @moduledoc """
  Documentation for `Interpreter`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Interpreter.hello()
      :world

  """
  def main do
    global = Env.global_frame()
    Core.load("lib/funcs.scm", global)
    IO.puts("Welcome to Scheme, Elixir edition")
    repl(global)
  end

  defp tokenise(str) do
    str
    |> String.graphemes()
    |> Reader.tokenise()
  end

  def process(str, single \\ true) do
    tokens = tokenise(str)

    if single do
      Reader.parse_single(tokens)
    else
      Reader.parse_series(tokens)
    end
  end

  def eval(str, env, print \\ false) do
    try do
      z = Eval_Apply.eval(process(str), env)

      if print do
        IO.inspect(z)
      end

      z
    rescue
      e -> e
    end
  end

  def repl(global, prompt \\ ">") do
    command = IO.gets(prompt)
    result = eval(command, global)
    IO.inspect(result)
    repl(global, prompt)
  end
end

defmodule Reader do
  defguardp whitespace?(token) when token in ["", " ", "\n"]
  defguardp digit?(x) when x in [".", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]

  defp digits?(x) do
    x != "" and Enum.all?(String.graphemes(x), &digit?/1)
  end

  defp parse_num(n) do
    String.to_integer(n)
  end

  def tokenise([h | t]) do
    rest = tokenise(t)
    specials = ["'", "{", "}", "(", ")", "#", "`", ","]

    cond do
      h in specials ->
        [h | rest]

      whitespace?(h) ->
        ["" | rest]

      h == "\"" ->
        {str, remaining} = read_str(t)
        [h <> str | tokenise(remaining)]

      h == ";" ->
        tokenise(after_eol(t))

      rest == [] or hd(rest) in specials ->
        [h | rest]

      true ->
        [h <> hd(rest) | tl(rest)]
    end
  end

  def tokenise([]) do
    []
  end

  defp after_eol([h | t]) do
    if h == "\n" do
      t
    else
      after_eol(t)
    end
  end

  defp after_eol([]) do
    []
  end

  defp read_str([h | t]) do
    case h do
      "\"" ->
        {h, t}

      _ ->
        {str, remaining} = read_str(t)
        {h <> str, remaining}
    end
  end

  defp read_str([]) do
    {"", []}
  end

  def process_token(h) do
    cond do
      # h == "'" -> :quote
      digits?(h) -> parse_num(h)
      quoted_string?(h) -> process_string(h)
      not quoted_string?(h) -> String.to_atom(h)
    end
  end

  def parse([h | t], acc) do
    reader_macros = %{"'" => :quote, "`" => :quasiquote, "," => :unquote}

    case h do
      "(" ->
        {expr, remaining} = parse(t, [])
        parse(remaining, [expr | acc])

      ")" ->
        {Enum.reverse(acc), t}

      '"' ->
        {string, remaining} = read_str(t)
        parse(remaining, [string | acc])

      "{" ->
        {vec, remaining} = parse(t, [])
        parse(remaining, [List.to_tuple(vec) | acc])

      "}" ->
        {Enum.reverse(acc), t}

      "" ->
        parse(t, acc)

      _ ->
        if not Map.has_key?(reader_macros, h) do
          parse(t, [process_token(h) | acc])
        else
          process_reader_macro(Map.get(reader_macros, h), t, acc)
        end
    end
  end

  def parse([], acc) do
    acc
  end

  def parse_single(lst) do
    hd(parse_series(lst))
  end

  def parse_series(lst) do
    try do
      Enum.reverse(parse(lst, []))
    rescue
      _ -> SchemeError.error("Malformed Expression")
    end
  end

  defp process_reader_macro(symb, t, acc) do
    case t do
      [] ->
        SchemeError.error("yikes")

      ["(" | rest] ->
        {expr, remaining} = parse(rest, [])
        parse(remaining, [[symb, expr] | acc])

      [fst | rest] ->
        parse(rest, [[symb, process_token(fst)] | acc])
    end
  end

  def quoted_string?(s) when is_bitstring(s) do
    String.starts_with?(s, "\"") and String.ends_with?(s, "\"")
  end

  def quoted_string?(s) when not is_bitstring(s) do
    false
  end

  defp process_string(s) do
    # Remove initial quote, and handle backslash wonkery
    String.slice(s, 1, String.length(s) - 2)
  end
end

defmodule SchemeError do
  @msg "DOOM BE UPON YE!"
  defexception message: @msg

  def error(msg \\ @msg) do
    raise SchemeError, message: msg
  end
end

defmodule Arith_Primitives do
  def add(x, y) do
    x + y
  end

  def sub(x, y) do
    x - y
  end

  def mul(x, y) do
    x * y
  end

  def divide(x, y) do
    x / y
  end

  def equal(x, y) do
    x == y
  end

  def op_dict() do
  end
end

defmodule Env do
  @name __MODULE__
  import GenTree

  @moduledoc """
  Use a GenTree as the basic state object, where each node has data being a bindings map.
  =lookup= takes a symbol and a pointer to an env, and does the recursion.
  =child= creates and returns a new child with the empty map of bindings.
  =set= takes a pid/pointer for env, retrieves the data from that, updates the bindings in that map, and passes the new map into update_node.
  """
  def global_frame() do
    default_map = Library.mappings()
    GenTree.new(default_map)
  end

  def lookup(sym, env) do
    # IO.inspect(sym)
    # if is_bitstring(sym) do sym = String.to_atom(sym) end
    if is_nil(env) do
      SchemeError.error("Undefined Variable" <> to_string(sym))
    end

    bindings = get_data(env)

    if Map.has_key?(bindings, sym) do
      Map.get(bindings, sym)
    else
      lookup(sym, get_parent(env))
    end
  end

  def child(env) do
    insert_child(env, %{})
  end

  def source(sym, env) do
    if is_nil(env) do
      false
    else
      if Map.has_key?(get_data(env), sym) do
        env
      else
        source(sym, get_parent(env))
      end
    end
  end

  def defined?(sym, env) do
    if source(sym, env) do
      true
    else
      false
    end
  end

  def define(sym, val, env) do
    update_data(env, Map.put(get_data(env), sym, val))
  end

  def set!(sym, val, env) do
    src = source(sym, env)

    if src do
      define(sym, val, src)
    else
      SchemeError.error("Cannot bind undefined variable")
    end
  end

  def gensym(root, env) when is_atom(root) do
    gensym(Kernel.to_string(root), env)
  end

  def gensym(root, env) when is_bitstring(root) do
    if defined?(root, env) do
      gensym(root <> "_", env)
    else
      String.to_atom(root)
    end
  end
end

defmodule Lambda do
  defstruct env: Env.global_frame(), params: [], body: [], macro: false, variadic: false
end

defmodule Builtin do
  defstruct [:func, params: [], macro: false, env?: false]
end

defmodule Eval_Apply do
  # import Types

  @primitives [:if, :quote, :lambda, :define, :set!, :mac, :lambdav, :macv, :gensym]
  defguard primitive?(op) when is_atom(op) and op in @primitives

  defguard lambda?(f) when is_struct(f, Lambda) and not f.macro
  defguard macro?(f) when is_struct(f, Lambda) and f.macro
  defguard function?(f) when lambda?(f) or is_struct(f, Builtin)

  def eval([op | args], env) when primitive?(op) do
    case op do
      :if ->
        [condition, on_true, on_false] = args

        if eval(condition, env) do
          eval(on_true, env)
        else
          eval(on_false, env)
        end

      :quote ->
        hd(args)

      :lambda ->
        [params | body] = args
        %Lambda{params: params, body: body, env: env}

      :lambdav ->
        [params | body] = args
        %Lambda{params: params, body: body, env: env, variadic: true}

      :mac ->
        [params | body] = args
        %Lambda{params: params, body: body, env: env, macro: true}

      :macv ->
        [params | body] = args
        %Lambda{params: params, body: body, env: env, macro: true, variadic: true}

      :define ->
        if is_atom(hd(args)) do
          [var, val] = args
          Env.define(var, eval(val, env), env)
          var
        else
          [[name | params] | body] = args
          Env.define(name, %Lambda{params: params, body: body, env: env}, env)
          name
        end

      :set! ->
        [var, val] = args
        Env.set!(var, eval(val, env), env)
        var

      :gensym ->
        Env.gensym(hd(args), env)
    end
  end

  def eval([op | args], env) when not primitive?(op) do
    proc = eval(op, env)
    # IO.inspect(proc)

    cond do
      is_function(proc) ->
        if proc == (&Eval_Apply.eval/2) do
          IO.inspect(args)
          # IO.inspect("BREAK")
          proc.(eval(hd(args), env), env)
          # Kernel.apply(proc, Enum.map(args, fn expr -> eval(expr, env)  end) ++ [env])
        else
          Kernel.apply(proc, Enum.map(args, fn expr -> eval(expr, env) end))
        end

      macro?(proc) ->
        Eval_Apply.apply(proc, args, env)

      function?(proc) ->
        resolved = Enum.map(args, fn expr -> eval(expr, env) end)
        Eval_Apply.apply(proc, resolved, proc.env)

      true ->
        SchemeError.error("Not a procedure: ")
        # IO.inspect(proc)
    end
  end

  def eval(atom, env) when not is_list(atom) or atom == [] do
    if is_atom(atom) do
      Env.lookup(atom, env)
    else
      atom
    end
  end

  def eval_all([h | t], env) do
    if t == [] do
      eval(h, env)
    else
      eval(h, env)
      eval_all(t, env)
    end
  end

  def replace_symbols(expr, env) when not is_list(expr) do
    if is_atom(expr) and Env.defined?(expr, env) do
      Env.gensym(expr, env)
    else
      expr
    end
  end

  def replace_symbols(expr, env) when is_list(expr) do
    Enum.map(expr, &replace_symbols(&1, env))
  end

  def apply(proc, args, env) when macro?(proc) do
    func =
      proc
      |> (&Map.update(&1, :macro, false, fn _x -> false end)).()
      |> (&Map.update(&1, :body, [], fn b -> replace_symbols(b, env) end)).()

    result = Eval_Apply.apply(func, args, env)
    result
    # Eval_Apply.eval(result, env)
  end

  def apply(proc, args, _env) when lambda?(proc) do
    %Lambda{params: p, body: b, variadic: v, env: e} = proc
    new_frame = Env.child(e)

    args =
      if v do
        [args]
      else
        args
      end

    # IO.inspect(args)
    params = Enum.zip(p, args)
    Enum.each(params, fn {name, val} -> Env.define(name, val, new_frame) end)
    eval_all(b, new_frame)
  end

  def apply(%Builtin{func: f}, args, env) do
    f.(args, env)
  end
end

defmodule Desugar do
  @moduledoc """
  Translation guide for core functions, basically. So things like define and cond, but ideally implement them via macros/syntax rules.
  """
end

defmodule TODO do
  @moduledoc """
  Mathpp
  """

  @moduledoc """
  Backslashes in strings. Tinker with read and process_str to have a special case for backslashes
  """

  @moduledoc """
  Macros: How to do these? Macros are classic, syntax rules are hard.
  Desugaring is easy once we have either of those.
  """
  @moduledoc """
  DONT Mutability like set-car and set-cdr are out
  """

  @moduledoc """
  Ports are IO devices as in https://hexdocs.pm/elixir/IO.html

  We should have a struct that wraps ports with some additional structure
  """
end

defmodule SanityCheck do
  def test() do
    root = Env.global_frame()
    # Interpreter.eval("(define id (lambda (x) x))", root)
    Interpreter.eval("(define x 5)", root, true)
    # Interpreter.eval("(define redef (lambda () (set! x 10)))", root)
    # Interpreter.eval("(redef)", root)
    Interpreter.eval("(define list (lambdav (args) args)) ", root)
    # Interpreter.eval("(list 1 2 (add 1 3))", root)
    Interpreter.eval(
      "(define map (lambda (f s) (if (null? s) s (cons (f (car s)) (map f (cdr s))))))",
      root,
      true
    )

    Interpreter.eval("(map (lambda (x) (add x 1)) (list 1 2 3))", root, true)

    Interpreter.eval(
      "
      (define quasiquote (mac (expr) (if (atom? expr) (list 'quote expr) (if (equal? (car expr) 'unquote) (car (cdr expr)) (map (lambda (e) (list 'quasiquote e)) expr)))))
",
      root,
      true
    )

    Interpreter.eval("(eval `(add 3 ,x))", root)
    # Interpreter.eval("quasiquote", root, true)
  end
end
