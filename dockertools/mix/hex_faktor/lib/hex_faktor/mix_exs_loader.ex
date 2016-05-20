defmodule HexFaktor.MixExsLoader do
  @def_ops [:def, :defp]

  alias HexFaktor.ExsLoader

  def parse(source) do
    case source |> Code.string_to_quoted do
      {:ok, ast} ->
        traverse(ast, &do_traverse/2)
      val -> val
    end
  end

  defp traverse(source_ast, fun, memo \\ nil) do
    {_, accumulated} = Macro.prewalk(source_ast, memo, fun)
    accumulated
  end

  for op <- @def_ops do
    defp do_traverse({unquote(op), _meta, arguments} = ast, memo) do
      {ast, memo || handle_function_definition(arguments, memo)}
    end
  end
  defp do_traverse(ast, memo) do
    {ast, memo}
  end

  defp handle_function_definition(body, memo) do
    case Enum.at(body, 0) do
      {:deps, _meta, nil} -> parse_body(body)
      {:deps, _meta, []} -> parse_body(body)
      _ ->
        memo
    end
  end

  defp parse_body(body) do
    body
    |> do_block_for!
    |> ExsLoader.parse(true)
  end

  defp do_block_for!(ast) do
    case do_block_for(ast) do
      {:ok, block} -> block
      nil -> nil
    end
  end

  defp do_block_for({_atom, _meta, arguments}) when is_list(arguments) do
    do_block_for(arguments)
  end
  defp do_block_for([do: block]) do
    {:ok, block}
  end
  defp do_block_for(arguments) when is_list(arguments) do
    arguments
    |> Enum.find_value(&find_keyword(&1, :do))
  end
  defp do_block_for(_) do
    nil
  end

  defp find_keyword(list, keyword) when is_list(list) do
    if Keyword.has_key?(list, keyword) do
      {:ok, list[keyword]}
    else
      nil
    end
  end
  defp find_keyword(_, _), do: nil
end
