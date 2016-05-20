defmodule HexFaktor.Persistence.ProjectUserSettings do
  import Ecto.Query, only: [from: 2]

  alias HexFaktor.Repo
  alias HexFaktor.ProjectUserSettings

  def ensure(project_id, user_id, default_branch) do
    case find(project_id, user_id) do
      nil -> add(project_id, user_id, default_branch)
      val -> val
    end
  end

  def find(project_id, user_id) do
    query = from u in ProjectUserSettings,
            where: u.project_id == ^project_id and u.user_id == ^user_id,
            select: u
    Repo.one(query)
  end

  def find_by_project_id(project_id) do
    query = from u in ProjectUserSettings,
            where: u.project_id == ^project_id,
            select: u
    Repo.all(query)
  end

  def find_by_user_id(user_id) do
    query = from u in ProjectUserSettings,
            where: u.user_id == ^user_id,
            select: u
    Repo.all(query)
  end

  defp add(project_id, user_id, default_branch) do
    attributes = %{
      "user_id" => user_id,
      "project_id" => project_id,
      "notification_branches" => [default_branch],
      "email_enabled" => true
    }
    %ProjectUserSettings{}
    |> ProjectUserSettings.changeset(attributes)
    |> Repo.insert!
  end

  def update_attributes(project_user_settings, attributes) do
    changeset = ProjectUserSettings.changeset project_user_settings, attributes
    if changeset.valid?, do: Repo.update!(changeset)
    changeset
  end
end
