defmodule Refaktor.Persistence.Build do
  import Ecto.Query, only: [from: 2]

  alias HexFaktor.Repo
  alias Refaktor.Builder.Model.Build
  alias Refaktor.Builder.Model.BuildJob

  def add(git_repo_id, git_branch_id, trigger \\ nil) do
    %Build{}
    |> Build.changeset(%{
          nr: git_repo_id |> next_build_nr,
          git_repo_id: git_repo_id,
          git_branch_id: git_branch_id,
          trigger: trigger
        })
    |> Repo.insert!
  end

  def add_job(build_id, git_branch_id, language, intent) do
    %BuildJob{}
    |> BuildJob.changeset(%{
          build_id: build_id,
          git_branch_id: git_branch_id,
          nr: build_id |> next_job_nr,
          language: language,
          intent: intent,
        })
    |> Repo.insert!
  end

  def all(git_repo_id) do
    Repo.all(from r in Build,
      where: r.git_repo_id == ^git_repo_id,
      order_by: [desc: :id],
      preload: [build_jobs: :git_revision])
  end

  def last(count \\ 5) do
    Repo.all(from r in Build,
      order_by: [desc: :id],
      limit: ^count,
      preload: [:git_repo, :git_branch])
  end

  defp next_build_nr(git_repo_id) do
    Repo.one(from r in Build,
      where: r.git_repo_id == ^git_repo_id,
      order_by: [desc: :nr],
      limit: 1,
      select: r.nr)
    |> next_nr
  end

  defp next_job_nr(build_id) do
    Repo.one(from r in BuildJob,
      where: r.build_id == ^build_id,
      order_by: [desc: :nr],
      limit: 1,
      select: r.nr)
    |> next_nr
  end

  defp next_nr(nil), do: 1
  defp next_nr(nr), do: nr + 1
end
