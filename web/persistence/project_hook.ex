defmodule HexFaktor.Persistence.ProjectHook do
  import Ecto.Query, only: [from: 2]

  alias HexFaktor.Repo
  alias HexFaktor.ProjectHook

  def set(project_id, github_hook_id, github_hook_active) do
    case find(project_id, github_hook_id) do
      nil -> add(project_id, github_hook_id, github_hook_active)
      val ->
        params = %{active: github_hook_active}
        changeset = ProjectHook.changeset val, params
        Repo.update!(changeset)
    end
  end

  def active?(project_id) do
    case find(project_id) do
      nil -> false
      val -> val.active
    end
  end

  def find(project_id) do
    query = from r in ProjectHook,
            where: r.project_id == ^project_id and
                    r.provider == "github",
            select: r,
            limit: 1
    Repo.one(query)
  end
  def find(project_id, github_hook_id) do
    uid = to_string(github_hook_id)
    query = from r in ProjectHook,
            where: r.project_id == ^project_id and
                    r.provider == "github" and r.uid == ^uid,
            select: r
    Repo.one(query)
  end

  def remove(project_id, github_hook_id) do
    case find(project_id, github_hook_id) do
      nil -> nil
      val -> Repo.delete!(val)
    end
  end

  defp add(project_id, github_hook_id, github_hook_active) do
    attributes = %{
      "project_id" => project_id,
      "provider" => "github",
      "uid" => to_string(github_hook_id),
      "active" => github_hook_active
    }
    %ProjectHook{}
    |> ProjectHook.changeset(attributes)
    |> Repo.insert!
  end
end
