defmodule Mix.Tasks.Faktor.Get do
  use Mix.Task

  @shortdoc  "Get a git repo and run a docker image on it"
  @moduledoc @shortdoc

  @dockerfile_dir "dockerfiles"

  alias Refaktor.Builder

  def run(argv) when is_list(argv) do
    Refaktor.start

    count = argv |> List.wrap |> Enum.count
    cond do
      count == 1 -> run(argv |> List.first)
      true -> print_usage
    end
  end

  def run(repo_url, _image_to_run \\ "faktor-elixir") when is_binary(repo_url) do
    branch_name = "master"

    Builder.add_and_run_repo(repo_url, branch_name, jobs: [])
  end

  defp print_usage do
    """
    Usage: mix faktor.get <GIT-URL> [IMAGE-TO-RUN]

    GIT-URL       - local or remote Git repository that will be cloned
    IMAGE-TO-RUN  - defaults to `faktor-elixir`
    """
    |> IO.puts
  end
end
