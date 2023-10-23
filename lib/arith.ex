defmodule Arith do
  def whitespace?(char) do
    String.equivalent?(String.strip(char), "")
  end

  def digit?(char) do
    char in (Enum.map(0..9, &Integer.to_string/1) ++ ["."])
  end

  def op?(char) do
    char in ["+", "-", "/", "*"]
  end

  def eof?(chars) do
    Enum.empty?(chars)
  end

  def parse_num(chars) do
    parse(chars, &digit?/1)
  end

  def parse_op(chars) do
    parse(chars, &op?/1)
  end

  def to_num(x) do
    try do
      String.to_float(x)
    rescue
      ArgumentError -> String.to_integer(x)
    end
  end

  def apply_op(op, a, b) do
    case op do
      "+" -> a + b
      "-" -> a - b
      "*" -> a * b
      "/" -> a / b
    end
  end

  def parse([h | t], checker) do
    "Read a token that satisfies checker, and return the unread portion of the list."

    if checker.(h) or whitespace?(h) do
      {val, chars} = parse(t, checker)

      cond do
        checker.(h) ->
          {h <> val, chars}

        whitespace?(h) ->
          {val, chars}
      end
    else
      {"", [h | t]}
    end
  end

  def parse([], _) do
    {"", []}
  end

  def interpret(chars) when is_list(chars) do
    {result, chars} = parse_num(chars)
    update(to_num(result), chars)
  end

  def interpret(string) when is_bitstring(string) do
    interpret(String.graphemes(string))
  end

  def update(result, chars) when is_list(chars) and is_number(result) do
    if eof?(chars) do
      result
    else
      {op, chars} = parse_op(chars)
      {next, chars} = parse_num(chars)
      update(apply_op(op, result, to_num(next)), chars)
    end
  end

  def repl(prompt \\ "calc>") do
    command = IO.gets(prompt)
    result = interpret(command)
    IO.inspect(result)
    repl(prompt)
  end
end
