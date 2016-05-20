defmodule Mix.Tasks.Faktor do
  use Mix.Task

  alias HexFaktor.CLI

  @shortdoc  "Run deps analysis"
  @moduledoc @shortdoc

  def run(args) do
    CLI.main(args)
  end
end
