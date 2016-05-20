defmodule Refaktor.Docker do
  alias Refaktor.Docker.Build
  alias Refaktor.Docker.Run

  def build(path, opts \\ []), do: Build.call(path, opts)

  def run(image, cmd, docker_run_opts \\ [], execution_opts \\ []) do
    Run.call(image, cmd, docker_run_opts, execution_opts)
  end
end
