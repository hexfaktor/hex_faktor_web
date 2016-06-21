defmodule Refaktor.Worker.Supervisor do
  alias Refaktor.Persistence.Build
  alias Refaktor.Persistence.GitRepo
  alias Refaktor.Persistence.GitBranch

  def enqueue_clone(build, git_repo, git_branch, jobs_to_schedule, meta) do
    queue = trigger_to_queue(build.trigger)
    params = [build.id, git_repo.id, git_branch.id, jobs_to_schedule, meta]
    Exq.enqueue(Exq, queue, __MODULE__, params) # calls perform below
  end

  def perform(build_id, git_repo_id, git_branch_id, jobs_to_schedule, meta) do
    build = Build.find_by_id(build_id)
    git_repo = GitRepo.find_by_id(git_repo_id)
    git_branch = GitBranch.find_by_id(git_branch_id)
    jobs_to_schedule = jobs_to_schedule |> Enum.map(&stringify_job/1)

    Refaktor.Builder.run_clone(build, git_repo, git_branch, jobs_to_schedule, meta)
  end

  # job was serialized into a String/binary and needs to be an Atom again
  defp stringify_job(%{"job" => job, "job_id" => job_id}) do
    %{"job" => Module.safe_concat([job]), "job_id" => job_id}
  end

  defp trigger_to_queue("manual"), do: "priority"
  defp trigger_to_queue(_), do: "default"
end
