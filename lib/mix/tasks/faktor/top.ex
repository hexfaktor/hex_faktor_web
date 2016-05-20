defmodule Mix.Tasks.Faktor.Top do
  use Mix.Task

  @shortdoc  "Shows currently running and recent builds"
  @moduledoc @shortdoc

  @dockerfile_dir "dockerfiles"

  alias Refaktor.Builder.Model.Build

  def run(argv) when is_list(argv) do
    Refaktor.start

    Refaktor.Persistence.Build.last
    |> Enum.each(&print_build/1)
  end

  defp print_build(%Build{id: build_id, git_branch: git_branch, git_repo: git_repo}) do
    [build_id, git_repo.uid, git_branch.name]
    |> Enum.join(" | ")
    |> IO.puts
  end

end
