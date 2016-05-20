defmodule HexFaktor.MixLockLoader do
  alias HexFaktor.ExsLoader

  def parse(source) do
    ExsLoader.parse(source, true)
  end
end
