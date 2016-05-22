defmodule HexFaktor.Persistence.Project do
  import Ecto.Query, only: [from: 2]

  alias HexFaktor.Repo
  alias HexFaktor.Project
  alias HexFaktor.ProjectUser
  alias Refaktor.Job.Elixir.Deps.Model.DepsObject

  def all do
    Repo.all(Project)
  end

  def all_for(user, preload_list \\ []) do
    query = from r in ProjectUser,
            where: r.user_id == ^user.id,
            select: r.project_id
    project_ids = Repo.all(query)

    query = from r in Project,
            where: r.id in ^project_ids,
            select: r,
            order_by: [asc: :name],
            preload: ^preload_list

    Repo.all(query)
  end

  def all_active do
    query = from r in Project,
            where: r.active == true
    Repo.all(query)
  end

  def all_active_ids do
    query = from r in Project,
            where: r.active == true,
            select: r.id
    Repo.all(query)
  end

  def all_with_dep(name) when is_binary(name) do
    project_ids = all_active_ids
    #
    query = from r in DepsObject,
            select: max(r.build_job_id),
            where: r.project_id in ^project_ids,
            group_by: [r.project_id, r.git_branch_id]
    newest_build_job_ids = Repo.all(query)

    query = from r in DepsObject,
            select: r.project_id,
            where: r.name == ^name and r.build_job_id in ^newest_build_job_ids

    project_ids = Repo.all(query)

    query = from r in Project,
            select: r,
            where: r.id in ^project_ids,
            preload: [:git_repo_branches]
    Repo.all(query)
  end

  def count do
    query = from r in Project,
            select: count(r.id),
            limit: 1
    Repo.one(query)
  end

  def ensure(%{"id" => uid} = attributes) do
    case find_by_uid(uid) do
      nil -> add(attributes)
      val -> val
    end
  end

  def ensure_repo(%Project{clone_url: clone_url} = project, branch_names) do
    repo = Refaktor.UseCase.Git.get_repo(clone_url)
    update_repo(project, repo)

    branch_names
    |> Enum.each(fn(branch_name) ->
        Refaktor.UseCase.Git.get_branch(repo.id, branch_name)
      end)
    repo
  end

  def find_by_id(id, preload_list \\ []) do
    query = from r in Project,
            where: r.id == ^id,
            select: r,
            preload: ^preload_list
    Repo.one(query)
  end

  def find_by_html_url(html_url, preload_list \\ [])

  def find_by_html_url(nil, _preload_list), do: nil
  def find_by_html_url(html_url, preload_list) do
    query = from r in Project,
            where: r.html_url == ^html_url,
            select: r,
            preload: ^preload_list,
            limit: 1
    Repo.one(query)
  end

  def find_by_uid(uid, provider \\ "github") do
    query = from u in Project,
            where: u.uid == ^uid and u.provider == ^provider,
            select: u
    Repo.one(query)
  end

  def find_by_provider_and_name(provider, name, preload_list \\ nil) do
    query = from u in Project,
            where: u.name == ^name and u.provider == ^provider,
            select: u,
            preload: ^preload_list
    Repo.one(query)
  end

  def update_last_github_sync(project) do
    project
    |> Project.changeset(%{last_github_sync: :calendar.universal_time})
    |> Repo.update!
  end

  def update_latest_build_job(project_id, build_job_id) when is_integer(project_id) do
    project_id
    |> find_by_id
    |> update_latest_build_job(build_job_id)
  end
  def update_latest_build_job(project, build_job_id) do
    project
    |> Project.changeset(%{latest_build_job_id: build_job_id})
    |> Repo.update!
  end

  def update_active(project, active) do
    project
    |> Project.changeset(%{active: active})
    |> Repo.update!
  end

  def update_use_lock_file(project, use_lock_file) do
    project
    |> Project.changeset(%{use_lock_file: use_lock_file})
    |> Repo.update!
  end

  defp update_repo(project, repo) do
    project
    |> Project.changeset(%{git_repo_id: repo.id})
    |> Repo.update!
  end

  defp add(%{"id" => uid, "full_name" => name, "html_url" => html_url, "clone_url" => clone_url, "default_branch" => default_branch, "language" => language, "fork" => fork}) do
    attributes = %{
      "uid" => uid,
      "provider" => "github",
      "use_lock_file" => false,
      "active" => false,
      "name" => name,
      "html_url" => html_url,
      "clone_url" => clone_url,
      "default_branch" => default_branch,
      "language" => language,
      "fork" => fork
    }
    %Project{}
    |> Project.changeset(attributes)
    |> Repo.insert!
  end
end
