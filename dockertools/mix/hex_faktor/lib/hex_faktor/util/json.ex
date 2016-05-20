defmodule HexFaktor.Util.JSON do
  def encode(struct) do
    Poison.encode!(struct)
  end

  def parse(string) do
    case Poison.decode(string) do
      {:ok, map} -> map
      _ -> :parser_error
    end
  end

  def parse!(string) do
    Poison.decode!(string)
  end
end
