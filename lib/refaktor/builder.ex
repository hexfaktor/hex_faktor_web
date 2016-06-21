defmodule Refaktor.Builder do
  @moduledoc """
  The Hub connects the Git, Docker and Job modules to first retrieve
  git repos and then execute jobs on them using containerization.
  """

  alias Refaktor.Job
  alias Refaktor.Persistence.Build
  alias Refaktor.Persistence.BuildJob
  alias Refaktor.Persistence.GitRevision
  alias Refaktor.Util.JSON
  alias Refaktor.Worker.ProgressCallback

  @work_dir Application.get_env :hex_faktor, :work_dir
  @filename_repo_info "git.json"

  def add_and_run_repo(repo_url, branch_name, options \\ []) do
    trigger = options[:trigger]
    jobs = options[:jobs]
    meta = options[:meta]

    {git_repo, git_branch} = Refaktor.UseCase.Git.get_repo_and_branch(repo_url, branch_name)

    build = Build.add(git_repo.id, git_branch.id, trigger)
    jobs_to_schedule =
      Enum.map(jobs, fn(job) ->
        build_job = Build.add_job(build.id, git_branch.id, job.language, job.intent)

        %{"job" => job, "job_id" => build_job.id}
      end)

    # this puts the "cloning" jobs in a queue. runs &run_clone/5 below.
    pid = Refaktor.Worker.Supervisor.enqueue_clone(build, git_repo, git_branch, jobs_to_schedule, meta)
    {:ok, build, pid}
  end

  def run_clone(build, git_repo, git_branch, jobs_to_schedule, meta, parent_pid) do
    progress_callback = ProgressCallback.cast(meta[:progress_callback])
    progress_callback.("cloning")

    IO.inspect {:__meta__, meta}

    %{"job" => job, "job_id" => first_job_id} = Enum.at(jobs_to_schedule, 0)

    case clone_for_job(git_repo.url, git_branch.name, first_job_id) do
      {:ok, _job_id, first_job_dir, repo_info} ->
        # repo cloned succesfully, let's duplicate it!
        duplicate_job_dir!(first_job_dir, jobs_to_schedule)

        progress_callback.("running")

        git_revision =
          GitRevision.ensure(git_repo, git_branch, repo_info.revision[:sha1])

        jobs_to_schedule
        |> Enum.map(&update_git_revision(&1, git_revision.id))

        # now schedule the jobs for execution
        pids =
          jobs_to_schedule
          |> Enum.map(&run_job(&1, meta, parent_pid))

        {:ok, build, pids}
      {:error, _job_id, _job_dir, _output, _exit_code} = error_tuple ->
        # we couldn't even clone this repo
        progress_callback.("error")
        send(parent_pid, error_tuple)

        jobs_to_schedule
        |> Enum.each(fn({_, job_id}) ->
            BuildJob.update_status(job_id, "failure", error_tuple)
            BuildJob.update_timestamp(job_id, :finished_at)
          end)
        error_tuple
    end
  end

  defp run_job(%{"job" => job, "job_id" => job_id}, meta, parent) do
    result = Refaktor.Worker.JobRunner.run_job(job_id, Job.dir(job_id), job, meta)
    send(parent, {:job_done, job_id, result})
  end

  defp duplicate_job_dir!(first_job_dir, jobs_to_schedule) do
    jobs_to_schedule
    |> Enum.slice((1..-1))
    |> Enum.each(fn %{"job_id" => job_id} ->
          File.cp_r first_job_dir, Job.dir(job_id)
        end)
  end

  defp update_git_revision(%{"job" => _job, "job_id" => job_id}, git_revision_id) do
    BuildJob.update_git_revision(job_id, git_revision_id)
  end

  @doc """
  Clones a Git repo.
  """
  def clone_for_job(repo_url, branch_name, job_id) do
    job_dir = generate_job_dir(job_id)

    case Refaktor.Builder.Git.clone(repo_url, job_dir, branch: branch_name) do
      {:ok, repo_info} ->
        save_git_data(repo_info, job_dir)
        {:ok, job_id, job_dir, repo_info}
      {:error, output, exit_code} ->
        {:error, job_id, job_dir, output, exit_code}
    end
  end

  defp save_git_data(repo, dir) do
    filename = Path.join(dir, @filename_repo_info)
    content = JSON.encode(repo)
    File.write(filename, content)
  end

  defp generate_job_dir(job_id) do
    dirname = Job.dir(job_id)
    File.mkdir_p dirname
    dirname
  end

  @doc """
  Returns the Builder's working directory.
  """
  def work_dir do
    @work_dir
  end
end
