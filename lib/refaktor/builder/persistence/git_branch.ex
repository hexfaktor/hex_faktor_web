defmodule Refaktor.Persistence.GitBranch do
  import Ecto.Query, only: [from: 2]

  alias HexFaktor.Repo
  alias Refaktor.Builder.Model.GitBranch
  alias Refaktor.Builder.Model.Build

  def add(repo_id, name) do
    %GitBranch{}
    |> GitBranch.changeset(%{git_repo_id: repo_id, name: name})
    |> Repo.insert!
  end

  def find_by_id(id, preload_list \\ []) do
    query = from r in GitBranch,
            where: r.id == ^id,
            select: r,
            preload: ^preload_list
    Repo.one(query)
  end

  def by_name(repo_id, name) do
    Repo.one(from r in GitBranch,
      where: r.git_repo_id == ^repo_id and r.name == ^name)
  end

  def latest_build(branch) do
    query = from r in Build, where: r.git_branch_id == ^branch.id,
                              order_by: [desc: r.id],
                              preload: [:build_jobs],
                              limit: 1
    Repo.one(query)
  end

  def latest_builds(branch_ids) when is_list(branch_ids) do
    query = from r in Build, where: r.git_branch_id in ^branch_ids,
                              order_by: [desc: r.id],
                              preload: [:build_jobs],
                              distinct: r.git_branch_id
    Repo.all(query)
  end
end
