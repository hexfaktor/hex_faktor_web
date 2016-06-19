defmodule HexFaktor.HelpController do
  use HexFaktor.Web, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def badge(conn, _params) do
    render(conn, "badge.html")
  end

  def versions(conn, _params) do
    render(conn, "versions.html")
  end

  def version_requirements(conn, _params) do
    render(conn, "version_requirements.html")
  end
end
