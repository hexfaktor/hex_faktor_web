defmodule HexFaktor.PageController do
  use HexFaktor.Web, :controller
  require Logger

  alias HexFaktor.Auth
  alias HexFaktor.AppEvent
  alias HexFaktor.Persistence.Project
  alias HexFaktor.ProjectBuilder

  def index(conn, _params) do
    if Auth.current_user(conn) do
      redirect conn, to: project_path(conn, :index)
    else
      render conn, "index.html"
    end
  end

  def about(conn, _params) do
    render conn, "about.html"
  end

  def status_404(conn, _params) do
    render conn, "404.html"
  end

  def status_500(conn, _params) do
    render conn, "500.html"
  end

  # TODO: move to a proper controller
  def hex_package_update(conn, %{"name" => name, "github_url" => _github_url}) do
    Logger.info "Received Hex package update: #{name}"
    HexFaktor.Endpoint.broadcast!("feeds:lobby", "update", %{name: name})

    dependent_projects = Project.all_with_dep(name)

    AppEvent.log(:hex_package_update, name, dependent_projects)

    dependent_projects
    |> Enum.each(&ProjectBuilder.run_notification_branches(&1, "package_update"))

    render(conn, "ok.json")
  end
end
