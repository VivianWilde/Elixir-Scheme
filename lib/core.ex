defmodule Core do
  def mappings do
    %{
      eq?: fn x, y -> x == y end,
      equal?: fn x, y -> x == y end,
      eqv?: fn x, y -> x === y end,
      cons: fn h, t -> [h | t] end,
      car: &hd/1,
      cdr: &tl/1,
      null?: fn s -> s == [] end,
      list?: &is_list/1,
      apply: &Eval_Apply.apply(&1, &2, Env.global_frame),
      eval: &Eval_Apply.eval(&1, &2),
      symbol_to_string: &to_string/1,
      string_to_symbol: &String.to_atom/1,
      string_length: &String.length/1,
      string_ref: &String.at/2,
      vector_length: &tuple_size/1,
      vector_ref: &elem/2,
      display: &IO.inspect/1,
      exit: fn -> exit(:shutdown) end
    }
  end

  def load(fname, env) do
    # "Can we do this in scheme itself? It's basically read|>eval, so possible."
    Eval_Apply.eval_all(Interpreter.process(File.read!(fname), false), env)
  end
end

defmodule Math do
  @moduledoc """
  - Numeric tower: Structs are not ideal, but they are what elixir uses.
  - Exact vs inexact: Inexact is contagious
  - We maybe need a struct for numbers which tags their most precise type, and exact/inexactness
  - Rationals should be precise
  - Alternatively, just say screw it and implement funcs for complex numbers by importing.
  """
  # TODO
  # TODO: Floats, complexes, etc. Also rationals
  def mappings do
    %{add: &(&1 + &2), sub: &(&1 - &2), mul: &(&1 * &2), div: &div/2, mod: &rem/2}
  end
end

defmodule Types do
  def mappings do
    %{
      symbol?: &is_atom/1,
      boolean?: &is_boolean/1,
      string?: &is_bitstring/1,
      number?: &is_number/1,
      pair?: &is_list/1,
      vector?: &is_tuple/1,
      procedure?: &Eval_Apply.proc?/1,
      atom?: &(is_atom(&1) or is_boolean(&1) or is_number(&1))
    }
  end
end

defmodule Mutation do
  @moduledoc """
   One idea is to restructure the env stuff, so that each symbol points to a /location/ struct, which in turn includes an address/something and a pointer to a value. If we do (define y x), that sets the /symbol/ y to point to the same /place/ that x points to. We have abstractions so that most functions except for equality and set!automatically dereference pointers.
   The problem is that if we want set-car to always work we need to implement pairs as primitives, which would require a lot of restructuring, and we'd need to implement it so /cdr/s were /pointers/ to pairs rather than actual pairs, which seems like such an overhead.


  """
  def set_car!(pair, obj) do
  end

  def set_cdr!(pair, obj) do
  end

  def vector_set!(vector, k, obj) do
  end
end

defmodule Continuation do
  def call_with_cc(proc) do
  end
end

defmodule Scheme_Port do
  defstruct [:input?, port: :stdio]
end

defmodule Scheme_IO do
  def inport(device) do
    %Scheme_Port{input?: true, port: device}
  end

  def outport(device) do
    %Scheme_Port{input?: false, port: device}
  end

  @moduledoc """
  Scheme uses ports as the IO abstraction. So opening a file returns a port, read reads objects from a port, etc. ports are mutable, so they work like iterators - read advances them, peek does not.
  """

  def input_port?(%Scheme_Port{input?: i}) do
    i
  end

  def output_port?(o) do
    not input_port?(o)
  end

  def current_input_port do
    inport(:stdio)
  end

  def current_output_port do
    outport(:stdio)
  end

  def open_input_file(f) do
    inport(File.open!(f, [:read]))
  end

  def open_output_file(f) do
    outport(File.open!(f, [:write]))
  end

  def close_input_port(%Scheme_Port{port: p, input?: true}) do
    File.close(p)
  end

  def close_output_port(%Scheme_Port{port: p, input?: false}) do
    File.close(p)
  end

  def read_char(%Scheme_Port{port: p, input?: true}) do
    IO.getn(p, "", 1)
  end

  def peek_char(port) do
  end

  def eof_object?(o) do
  end

  def char_ready?(port) do
  end

  def write_char(char, %Scheme_Port{input?: false, port: p}) do
    IO.write(p, char)
  end
end

defmodule Library do
  def merge_maps(lst) do
    List.foldl(lst, %{}, &Map.merge/2)
  end

  def mappings do
    merge_maps([Core.mappings(), Types.mappings(), Math.mappings()])
  end
end
