
# defmodule Env_Old do
#   @moduledoc """
#   Do this the way scheme does properly. Variables point to locations, and locations contain values. How are we doing locations? Array means pointer arithmetic, but we do need a way to store objects in memory rather than just vals. So one idea is to just implement a crappy version of the stack and heap - pointers in the stack, values in the heap. The only real "values" we store are analogous to Elixir structures (LLs, structs, etc.), so we can just have the heap be an elixir storage. Stack and heap are part of our state.
#   Basically, we do pointers via indexing into a mutable vector. 164 does interpreted scheme just via maps, but no support for mutation.
#   Another way is to just do maps, and use Elixir's weird state handling to maintain a complex series of maps with priority.
#   """
#   defstruct parent: nil, bindings: %{}

#   def lookup(symbol, %Env{parent: p, bindings: b}) do
#     if Map.has_key?(b, symbol) do
#       Map.get(b, symbol)
#     else
#       Env.lookup(symbol, p)
#     end
#   end

#   def lookup(_, nil) do
#     error()
#   end

#   def child(env) do
#     %Env{parent: env, bindings: %{}}
#   end

#   def set(sym, val, env) do
#     %{binding: b} = env
#     %{env | binding: Map.put(b, sym, val)}
#   end
# end

# def symbolify([h|t]) do
#     rest = symbolify(t)

#     cond do
#       quoted_string?(h) -> [process_string(h) | rest]
#       is_bitstring(h) -> [String.to_atom(h) | rest]
#       true -> [h | rest]
#     end
#   end
