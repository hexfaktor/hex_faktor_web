defmodule Refaktor.Worker.JobRunner do
  use GenServer

  alias Refaktor.Job
  alias Refaktor.Persistence.BuildJob

  alias HexFaktor.Persistence.Project

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], [])
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call({:run_clone, build, git_repo, branch_name, jobs_to_schedule, meta, parent}, _from, state) do
    Refaktor.Builder.run_clone(build, git_repo, branch_name, jobs_to_schedule, meta, parent)

    {:reply, [], state}
  end

  def run_job(job_id, job_dir, job, meta) do
    update_job(job_id, "running", [], :started_at)

    if meta["project_id"] do
      Project.update_latest_build_job(meta["project_id"], job_id)
    end

    try do
      Job.run(job_id, job_dir, job, run_opts(Mix.env, job_id), meta)
    rescue
      value -> {:error, :rescue, Exception.format(:error, value)}
    end
    |> case do
      {:ok, result} ->
        update_job(job_id, "success", {:ok, result}, :finished_at)
        {:ok, result}
      value ->
        update_job(job_id, "failure", value, :finished_at)
        value
    end
  end

  defp update_job(job_id, status, debug_info, timestamp_field) do
    BuildJob.update_status(job_id, status, debug_info, docker_logs(status, job_id))
    if timestamp_field do
      BuildJob.update_timestamp(job_id, timestamp_field)
    end
  end

  defp docker_logs("running", _), do: nil
  defp docker_logs(_status, job_id) do
    {docker_logs, _} = System.cmd("sudo", ["docker", "logs", container_name(job_id)], stderr_to_stdout: true)
    docker_logs
  end

  defp run_opts(:test, _), do: []
  defp run_opts(_, job_id), do: [container_name: container_name(job_id)]

  defp container_name(job_id), do: "hf-job-#{job_id}"
end
