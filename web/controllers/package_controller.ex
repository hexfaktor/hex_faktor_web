defmodule HexFaktor.PackageController do
  use HexFaktor.Web, :controller

  alias HexFaktor.Persistence.Package
  alias HexFaktor.Persistence.PackageUserSettings
  alias HexFaktor.Persistence.Project
  alias HexFaktor.ProjectProvider
  alias HexFaktor.Auth

  @hex_mirror HexSonar
  @shown_release_count 5

  @filter_all "all"
  @filter_search "search"

  def index(conn, params) do
    perform_index(conn, params, "html")
  end

  def index_api(conn, params) do
    perform_index(conn, params, "json")
  end

  defp perform_index(conn, params, format) do
    search_query = params["q"] |> nil_if_empty
    current_package_filter = params["filter"] |> nil_if_empty

    if current_package_filter == @filter_search && is_nil(search_query) do
      current_package_filter = @filter_all
    end

    packages =
      case current_package_filter do
        @filter_search -> Package.all_by_query(search_query)
        _ -> Package.all
      end

    assigns = [
      current_package_filter: current_package_filter,
      packages: packages,
      search: search_query
    ]

    if [:dev, :test] |> Enum.member?(Mix.env) do
      render(conn, "index.#{format}", assigns)
    else
      render(conn, "404.html", assigns)
    end
  end

  def rebuild_via_web(conn, %{"id" => package_id} = params) do
    package = Package.find_by_id(package_id)
    update_package_from_hex(package)
    render(conn, "ok.json")
  end

  def show(conn, %{"name" => name}) do
    perform_show(conn, name, "html")
  end

  def show_api(conn, %{"name" => name}) do
    perform_show(conn, name, "json")
  end

  def perform_show(conn, name, format) do
    package =
      case Package.find_by_name(name) do
        nil -> fetch_package_from_hex(name)
        val -> val
      end
    user = Auth.current_user(conn)
    package_user_settings = nil

    if user do
      users_dep_projects = Project.all_with_dep_for_user(package.name, user)
      {dependent_projects, _active_projects, _outdated_projects} =
        ProjectProvider.user_projects(user, users_dep_projects)
      package =
        %HexFaktor.Package{package | dependent_projects_by_current_user: dependent_projects}
      package_user_settings = PackageUserSettings.find(package.id, user.id)
    end
    releases = package.releases |> List.wrap |> map_releases()
    {shown_releases, hidden_releases} =
      if Enum.count(releases) > @shown_release_count do
        {
          releases |> Enum.slice(0..@shown_release_count-1),
          releases |> Enum.slice(@shown_release_count..-1)
        }
      else
        {releases, []}
      end
    assigns =
      [
        package: package,
        shown_releases: shown_releases,
        hidden_releases: hidden_releases,
        package_user_settings: package_user_settings
      ]

    if [:dev, :test] |> Enum.member?(Mix.env) do
      render(conn, "show.#{format}", assigns)
    else
      render(conn, "404.html", assigns)
    end
  end

  #
  # /update_settings
  #

  def update_settings_all(conn, %{"id" => package_id}) do
    update_params = %{
      "notifications_for_major" => true,
      "notifications_for_minor" => true,
      "notifications_for_patch" => true,
      "notifications_for_pre" => false,
    }
    params = %{"id" => package_id, "package_user_settings" => update_params}
    update_settings(conn, params)
  end

  def update_settings_none(conn, %{"id" => package_id}) do
    update_params = %{
      "notifications_for_major" => false,
      "notifications_for_minor" => false,
      "notifications_for_patch" => false,
      "notifications_for_pre" => false,
    }
    params = %{"id" => package_id, "package_user_settings" => update_params}
    update_settings(conn, params)
  end

  def update_settings(conn, %{"id" => package_id, "package_user_settings" => update_params}) do
    current_user = Auth.current_user(conn)
    if current_user do
      package = Package.find_by_id(package_id)
      conn |> perform_update_settings(current_user, package, update_params)
    else
      conn |> access_denied()
    end
  end

  defp perform_update_settings(conn, current_user, package, update_params) do
    package_user_settings =
      PackageUserSettings.ensure(package.id, current_user.id)
    changeset =
      PackageUserSettings.update_attributes(package_user_settings, update_params)
    if changeset.valid? do
      conn = conn |> put_flash(:info, "Notification settings updated successfully.")
    end
    redirect(conn, to: package_path(conn, :show, package.name))
  end

  defp fetch_package_from_hex(name) do
    name
    |> @hex_mirror.load
    |> Package.create_from_hex(name)
  end

  defp update_package_from_hex(package) do
    package.name
    |> @hex_mirror.load
    |> Package.update_from_hex(package)
  end

  defp map_releases(releases) do
    releases
    |> Enum.map(fn(%{"version" => version, "updated_at" => updated_at}) ->
        %{"version" => version, "updated_at" => cast_time(updated_at)}
      end)
  end

  defp cast_time(string) do
    case Ecto.DateTime.cast(string) do
      {:ok, datetime} -> datetime
      _ -> nil
    end
  end
end
