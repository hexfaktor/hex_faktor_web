defmodule Refaktor.Docker.Run do
  alias Refaktor.Docker.Run

  @default_system_opts [stderr_to_stdout: true]
  @userid_inside_docker Application.get_env(:hex_faktor, :userid_inside_docker)

  require Logger

  @doc """
  Runs a +cmd+ inside a given +image+.
  """
  def call(image, cmd, docker_run_opts \\ [], execution_opts \\ []) do
    run(image, cmd, docker_run_opts, execution_opts, @default_system_opts)
  end

  defp run(image, cmd, docker_run_opts, execution_opts, system_opts) do
    name = execution_opts[:name] || generate_name
    docker_run_opts = docker_run_opts ++ ["--name=#{name}",
                                          "--user=#{@userid_inside_docker}"]
    run_args = List.flatten(["docker", "run", docker_run_opts, image, cmd])
    kill_after = execution_opts[:kill_after]

    result =
      if kill_after do
        start_and_kill_after(name, run_args, system_opts, kill_after)
      else
        System.cmd("sudo", run_args, system_opts)
      end

    case result do
      {:timeout, summary} -> {:timeout, summary}
      {output, 0} -> {:ok, output}
      {output, x} when is_integer(x) -> {:error, output, x}
      other ->
        Logger.error "#{__MODULE__}: Unknown result: #{inspect other}"
    end
  end

  defp generate_name(hash_length \\ 6) do
    hash =
      hash_length
      |> :crypto.strong_rand_bytes
      |> Base.url_encode64
      |> binary_part(0, hash_length)
    "faktor-#{hash}"
  end

  defp start_and_kill_after(name, run_args, system_opts, millisec) do
    parent = self()
    pid = spawn(Run, :start, [parent, name, run_args, system_opts])
    Process.send_after(pid, :terminate, millisec)
    receive do
      {^pid, val} -> val
    end
  end

  def start(parent, name, run_args, system_opts) do
    pid = spawn(Run, :spawn_process_for_docker, [self(), run_args, system_opts])
    receive do
      :terminate ->
        result = kill(name)
        send parent, {self(), {:timeout, result}}
      {^pid, :ok, result} ->
        send parent, {self(), result}
    end
  end

  def spawn_process_for_docker(parent, run_args, system_opts) do
    result = System.cmd("sudo", run_args, system_opts)
    send parent, {self(), :ok, result}
  end

  defp kill(container_name) do
    result_top = System.cmd("sudo", ["docker", "top", container_name], @default_system_opts)
    result_kill = System.cmd("sudo", ["docker", "kill", container_name], @default_system_opts)
    {result_top, result_kill}
  end
end
