defmodule HexFaktor.PackageProvider do
  alias HexFaktor.Persistence.Notification
  alias HexFaktor.Persistence.Package
  alias HexFaktor.Persistence.PackageUserSettings
  alias HexFaktor.Persistence.Project
  alias HexFaktor.ProjectProvider
  alias HexFaktor.Auth

  @hex_mirror HexSonar
  @shown_release_count 5


  def assigns_for(current_user, package_name) do
    {package, package_user_settings, shown_releases, hidden_releases} =
      get(current_user, package_name)

    [
      package: package,
      package_user_settings: package_user_settings,
      shown_releases: shown_releases,
      hidden_releases: hidden_releases
    ]
  end

  def get(current_user, package_name) do
    package =
      case Package.find_by_name(package_name) do
        nil -> fetch_package_from_hex(package_name)
        val -> val
      end
    package_user_settings = nil

    mark_notifications_as_seen!(current_user, package)

    if current_user do
      users_dep_projects = Project.all_with_dep_for_user(package.name, current_user)
      {dependent_projects, _active_projects, _outdated_projects} =
        ProjectProvider.user_projects(current_user, users_dep_projects)
      package =
        %HexFaktor.Package{package | dependent_projects_by_current_user: dependent_projects}
      package_user_settings = PackageUserSettings.find(package.id, current_user.id)
    end

    releases = package.releases |> List.wrap |> map_and_sort_releases()

    {shown_releases, hidden_releases} =
      if Enum.count(releases) > @shown_release_count do
        {
          releases |> Enum.slice(0..@shown_release_count-1),
          releases |> Enum.slice(@shown_release_count..-1)
        }
      else
        {releases, []}
      end

    {package, package_user_settings, shown_releases, hidden_releases}
  end

  defp fetch_package_from_hex(name) do
    name
    |> @hex_mirror.load
    |> Package.create_from_hex(name)
  end

  defp mark_notifications_as_seen!(nil, _), do: nil
  defp mark_notifications_as_seen!(_, nil), do: nil
  defp mark_notifications_as_seen!(current_user, package) do
    Notification.mark_as_seen_for_package!(current_user, package.id)
  end

  defp map_and_sort_releases(releases) do
    releases
    |> Enum.map(fn(%{"version" => version, "updated_at" => updated_at}) ->
        %{"version" => version, "updated_at" => cast_time(updated_at)}
      end)
    |> Enum.sort(fn(a, b) ->
        compare = Version.compare(a["version"], b["version"])
        [:eq, :gt] |> Enum.member?(compare)
      end)
  end

  defp cast_time(string) do
    case Ecto.DateTime.cast(string) do
      {:ok, datetime} -> datetime
      _ -> nil
    end
  end

end
