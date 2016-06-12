defmodule HexFaktor.Persistence.PackageUserSettings do
  import Ecto.Query, only: [from: 2]

  alias HexFaktor.Repo
  alias HexFaktor.PackageUserSettings

  def ensure(package_id, user_id) do
    case find(package_id, user_id) do
      nil -> add(package_id, user_id)
      val -> val
    end
  end

  def find(package_id, user_id) do
    query = from u in PackageUserSettings,
            where: u.package_id == ^package_id and u.user_id == ^user_id,
            select: u
    Repo.one(query)
  end

  def find_by_package_id(package_id) do
    query = from u in PackageUserSettings,
            where: u.package_id == ^package_id,
            select: u
    Repo.all(query)
  end

  def find_by_user_id(user_id) do
    query = from u in PackageUserSettings,
            where: u.user_id == ^user_id,
            select: u
    Repo.all(query)
  end

  defp add(package_id, user_id) do
    attributes = %{
      "user_id" => user_id,
      "package_id" => package_id,
      "notifications_for_major" => true,
      "notifications_for_minor" => true,
      "notifications_for_patch" => true,
      "email_enabled" => true
    }
    %PackageUserSettings{}
    |> PackageUserSettings.changeset(attributes)
    |> Repo.insert!
  end

  def update_attributes(package_user_settings, attributes) do
    changeset = PackageUserSettings.changeset package_user_settings, attributes
    if changeset.valid?, do: Repo.update!(changeset)
    changeset
  end
end
