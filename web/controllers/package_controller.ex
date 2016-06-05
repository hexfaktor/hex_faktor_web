defmodule HexFaktor.PackageController do
  use HexFaktor.Web, :controller

  alias HexFaktor.Persistence.Package
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

    if Mix.env == :dev do
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

    if user = Auth.current_user(conn) do
      users_dep_projects = Project.all_with_dep_for_user(package.name, user)
      {dependent_projects, _active_projects, _outdated_projects} =
        ProjectProvider.user_projects(user, users_dep_projects)
      package =
        %HexFaktor.Package{package | dependent_projects_by_current_user: dependent_projects}
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
    assigns = [package: package, shown_releases: shown_releases, hidden_releases: hidden_releases]

    if Mix.env == :dev do
      render(conn, "show.#{format}", assigns)
    else
      render(conn, "404.html", assigns)
    end
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
