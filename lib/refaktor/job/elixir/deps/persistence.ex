defmodule Refaktor.Job.Elixir.Deps.Persistence do
  import Ecto.Query, only: [from: 2]

  alias HexFaktor.Repo
  alias Refaktor.Job.Elixir.Deps.Model.DepsObject

  def find_by_id(id, preload_list \\ []) do
    query = from r in DepsObject, where: r.id == ^id,
                                  preload: ^preload_list
    Repo.one(query)
  end

  def find_by_job_id(job_id) do
    query = from r in DepsObject, where: r.build_job_id == ^job_id
                                          and r.toplevel == true,
                                  order_by: [asc: r.name]
    Repo.all(query)
  end

  def find_by_job_ids(job_ids) do
    query = from r in DepsObject, where: r.build_job_id in ^job_ids
                                          and r.toplevel == true,
                                  order_by: [asc: r.name]
    Repo.all(query)
  end

  def find_ids_by_name_and_branch(dep, git_branch) do
    query = from r in DepsObject,
              where: r.git_branch_id == ^git_branch.id and
                      r.name == ^dep.name and
                      r.source == ^dep.source,
              select: r.id
    Repo.all(query)
  end

  def find_outdated_project_ids(job_ids) do
    query = from r in DepsObject, where: r.build_job_id in ^job_ids
                                          and r.toplevel == true
                                          and r.severity != "none",
                                  group_by: r.project_id,
                                  select: r.project_id
    Repo.all(query)
  end

  def write(job_id, project_id, git_repo_id, git_branch_id, objects) do
    Repo.transaction([timeout: :infinity, pool_timeout: :infinity], fn ->
      objects
      |> Enum.map(&write_object(job_id, project_id, git_repo_id, git_branch_id, &1))
    end)
  end

  defp write_object(job_id, project_id, git_repo_id, git_branch_id, %{} = object) do
    %DepsObject{}
    |> DepsObject.changeset(%{
        build_job_id: job_id,
        project_id: project_id,
        git_repo_id: git_repo_id,
        git_branch_id: git_branch_id,
        language: "elixir",
        name: object["name"],
        source: object["source"],
        source_url: object["source_url"],
        toplevel: object["toplevel"],
        locked_version: object["locked_version"],
        required_version: object["required_version"],
        available_versions: object["available_versions"],
        mix_envs: object["mix_envs"],
        severity: object["severity"] |> to_string,
      })
    |> Repo.insert!
  end
end
