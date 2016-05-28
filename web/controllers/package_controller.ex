defmodule HexFaktor.PackageController do
  use HexFaktor.Web, :controller

  alias HexFaktor.Persistence.Package

  @hex_mirror HexSonar

  @filter_all "all"
  @filter_search "search"

  def index(conn, params) do
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
    render(conn, "index.html", assigns)
  end

  def rebuild_via_web(conn, %{"id" => package_id} = params) do
    package = Package.find_by_id(package_id)
    update_package_from_hex(package)
    render(conn, "ok.json")
  end

  def show(conn, %{"name" => name}) do
    package =
      case Package.find_by_name(name) do
        nil -> fetch_package_from_hex(name)
        val -> val
      end
    perform_show(conn, package)
  end

  def perform_show(conn, package) do
    render(conn, "show.html", package: package)
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
end
