defmodule HexFaktor.PackageController do
  use HexFaktor.Web, :controller

  alias HexFaktor.Persistence.Package

  @hex_mirror HexSonar

  def index(conn, _params) do
    packages = Package.all
    render(conn, "index.html", packages: packages)
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
end
