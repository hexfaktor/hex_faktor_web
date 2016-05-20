defmodule Refaktor.Job do
  @moduledoc """
  This module runs a Job inside a given `job_dir` which already exists.

  """

  @doc "Returns what language the job is concerned with (e.g. elixir)."
  @callback language() :: String.t

  @doc "Returns what the job is doing (e.g. code_analysis)."
  @callback intent() :: String.t

  @doc "Returns which image the job is going to run on (e.g. faktor-elixir)."
  @callback image_to_run() :: String.t

  @doc "Returns which script the job is going to run (e.g. run-elixir-inch)."
  @callback script_to_run() :: String.t

  @doc """
  """
  @callback handle_success(pos_integer, Path.t, String.t, map) :: tuple
  @callback handle_error(pos_integer, Path.t, String.t, integer, map) :: tuple
  @callback handle_timeout(pos_integer, Path.t, {tuple, tuple}, map) :: tuple

  alias Refaktor.Docker
  alias Refaktor.Util.JSON

  @work_dir Application.get_env :hex_faktor, :work_dir
  @tool_dir Application.get_env :hex_faktor, :tool_dir
  @default_json_result_filename "result.json"
  @code_dirname Application.get_env :hex_faktor, :code_dirname
  @eval_dirname Application.get_env :hex_faktor, :eval_dirname
  @kill_container_after 10 * 60 * 1000

  def run(job_dir, job, opts \\ [], meta \\ [])

  # Received via pipe from Builder.clone_for_job
  def run({:ok, job_id, job_dir, _repo_info}, job, opts, meta) do
    run(job_id, job_dir, job, opts, meta)
  end
  def run({:error, job_id, _job_dir, output, exit_code}, _job, _opts, _meta) do
    {:error, job_id, {:retrieval, output, exit_code}}
  end

  @doc """
  Runs a given +job+ in the +job_dir+.
  """
  @spec run(pos_integer, String.t, Job.t, map, map) :: {:ok | :error | :timeout, tuple}
  def run(job_id, job_dir, job, opts, meta) when is_binary(job_dir) do
    File.mkdir_p eval_dir(job_dir)

    volume_opts = ["-v", "#{code_dir(job_dir)}:#{code_mount_dir}",
                   "-v", "#{eval_dir(job_dir)}:#{eval_mount_dir}",
                   "-v", "#{tool_dir}:#{tool_mount_dir}:ro"]

    execution_opts = [
      name: opts[:container_name],
      kill_after: @kill_container_after
    ]

    image = job.image_to_run
    cmd = job.script_to_run

    case Docker.run(image, cmd, volume_opts, execution_opts) do
      {:ok, output} ->
        result =
          job_id
          |> job.handle_success(job_dir, output, meta)
          |> wrap_success()
      {:error, output, exit_code} ->
        {:error, job.handle_error(job_id, job_dir, output, exit_code, meta)}
      {:timeout, summary} ->
        {:timeout, job.handle_timeout(job_id, job_dir, summary, meta)}
    end
  end

  @doc """
  Wraps a given `tuple` in `{:ok, _your_tuple_here}` unless it starts with `:error`
  """
  def wrap_success(tuple) do
    case tuple |> Tuple.to_list |> List.first do
      :error -> tuple
      :ok -> tuple
      _ -> {:ok, tuple}
    end
  end

  def code_dir(job_dir), do: Path.join(job_dir, @code_dirname)
  def eval_dir(job_dir), do: Path.join(job_dir, @eval_dirname)
  def tool_dir, do: @tool_dir

  defp code_mount_dir, do: Path.join("/job", @code_dirname)
  defp eval_mount_dir, do: Path.join("/job", @eval_dirname)
  defp tool_mount_dir, do: "/tools"

  @doc """
  Returns the local working directory for the given +job_id+.
  """
  def dir(job_id) when is_integer(job_id) do
    Path.join([@work_dir] ++ split_job_id(job_id))
  end

  # Transforms a given +job_id+ from 1 to "0000001" to ["0000", "001"]
  defp split_job_id(job_id) do
    job_id
    |> to_string
    |> String.rjust(7, ?0)
    |> String.split_at(4)
    |> Tuple.to_list
  end

  def read_result(job_dir, json_file \\ @default_json_result_filename)

  def read_result(job_id, json_file) when is_integer(job_id) do
    job_id
    |> dir
    |> read_result(json_file)
  end
  def read_result(job_dir, json_file) when is_binary(job_dir) do
    filename = result_filename(job_dir, json_file)
    if File.exists?(filename) do
      filename
      |> File.read!
      |> JSON.parse
    else
      {:file_not_found, json_file}
    end
  end

  defp result_filename(job_dir, json_file) do
    [eval_dir(job_dir), json_file]
    |> Path.join
  end
end
