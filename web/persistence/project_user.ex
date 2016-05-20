defmodule HexFaktor.Persistence.ProjectUser do
  import Ecto.Query, only: [from: 2]

  alias HexFaktor.Repo
  alias HexFaktor.ProjectUser

  def ensure(project_id, user_id) do
    case find(project_id, user_id) do
      nil -> add(project_id, user_id)
      val -> val
    end
  end

  def remove(project_id, user_id) do
    case find(project_id, user_id) do
      nil -> nil
      val -> Repo.delete!(val)
    end
  end

  def find(project_id, user_id) do
    query = from u in ProjectUser,
            where: u.project_id == ^project_id and u.user_id == ^user_id,
            select: u
    Repo.one(query)
  end

  def find_by_user_id(user_id) do
    query = from u in ProjectUser,
            where: u.user_id == ^user_id,
            select: u
    Repo.all(query)
  end

  def find_user_ids_by_project_id(project_id) do
    query = from r in ProjectUser,
            select: r.user_id,
            where: r.project_id == ^project_id
    Repo.all(query)
  end

  defp add(project_id, user_id) do
    attributes = %{
      "user_id" => user_id,
      "project_id" => project_id,
    }
    %ProjectUser{}
    |> ProjectUser.changeset(attributes)
    |> Repo.insert!
  end
end
