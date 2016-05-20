defmodule Refaktor.Persistence.BuildJob do
  import Ecto.Query, only: [from: 2]

  alias HexFaktor.Repo
  alias Refaktor.Builder.Model.BuildJob

  def get(job_id) do
    BuildJob |> Repo.get!(job_id)
  end

  def get_with_repo(job_id) do
    from(c in BuildJob, where: c.id == ^job_id, preload: [build: :git_repo])
    |> Repo.one
  end

  def latest(git_branch_id, preload_list \\ []) do
    query = from c in BuildJob,
            where: c.git_branch_id == ^git_branch_id,
            preload: ^preload_list,
            order_by: [desc: :id],
            limit: 1
    Repo.one(query)
  end
  def latest_with_status(git_branch_id, status, preload_list \\ []) do
    query = from c in BuildJob,
            where: c.git_branch_id == ^git_branch_id and
                    c.status == ^status,
            preload: ^preload_list,
            order_by: [desc: :id],
            limit: 1
    Repo.one(query)
  end

  def latest_ids_with_status(git_branch_ids, status) when is_list(git_branch_ids) do
    query = from c in BuildJob,
            where: c.git_branch_id in ^git_branch_ids and
                    c.status == ^status,
            order_by: [desc: :id],
            distinct: c.git_branch_id,
            select: c.id
    Repo.all(query)
  end

  def update_status(job_id, status, debug_info \\ [], logs \\ nil) do
    params = %{
      status: status,
      debug_info: Macro.to_string(debug_info),
      logs: logs
    }
    changeset = BuildJob.changeset Repo.get!(BuildJob, job_id), params
    Repo.update!(changeset)
  end

  def update_output(job_id, output) do
    params = %{stdout: output}
    changeset = BuildJob.changeset Repo.get!(BuildJob, job_id), params
    Repo.update!(changeset)
  end

  def update_git_revision(job_id, git_revision_id) do
    params = %{git_revision_id: git_revision_id}
    changeset = BuildJob.changeset Repo.get!(BuildJob, job_id), params
    Repo.update!(changeset)
  end

  def update_timestamp(job_id, field) do
    params = Map.put(%{}, field, now)
    changeset = BuildJob.changeset Repo.get!(BuildJob, job_id), params
    Repo.update!(changeset)
  end

  defp now do
    :calendar.universal_time
  end
end
