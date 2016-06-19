defmodule HexFaktor.ComponentController do
  use HexFaktor.Web, :controller

  alias HexFaktor.Persistence.Package
  alias HexFaktor.Persistence.Project
  alias HexFaktor.Persistence.ProjectUserSettings
  alias HexFaktor.PackageProvider
  alias HexFaktor.ProjectAccess
  alias HexFaktor.ProjectController
  alias HexFaktor.ProjectProvider
  alias HexFaktor.Auth
  alias HexFaktor.LayoutView
  alias HexFaktor.VersionHelper

  def project_list_item(conn, %{"id" => project_id}) do
    current_user = Auth.current_user(conn)

    if current_user && ProjectAccess.granted?(project_id, current_user) do
      conn |> perform_project_list_item(current_user, project_id)
    else
      conn |> access_denied()
    end
  end

  defp perform_project_list_item(conn, current_user, project_id) do
    # TODO: check rights
    project_user_settings = ProjectUserSettings.find_by_user_id(current_user.id)
    project =
      project_id
      |> Project.find_by_id([:git_repo_branches, :project_hooks])
      |> List.wrap
      |> ProjectProvider.mark_outdated_projects(project_user_settings)
      |> List.first
    assigns = [
      layout: blank_layout,
      project: project,
      no_cache: :random.uniform(1_000_000)
    ]
    render conn, "project-list-item.html", assigns
  end

  def dep(conn, %{"id" => dep_id}) do
    # TODO: check rights
    dep = Refaktor.Job.Elixir.Deps.Persistence.find_by_id(dep_id, [:project])
    current_user = Auth.current_user(conn)
    package_assigns = PackageProvider.assigns_for(current_user, dep.name)
    assigns = [
      layout: blank_layout,
      dep: dep,
      project: dep.project,
      expanded?: true
    ]
    shown_releases =
      package_assigns[:shown_releases] |> releases_until_last_matching(dep)

    render conn, "dep.html", assigns ++ package_assigns ++ [shown_releases: shown_releases]
  end

  def notification_counter(conn, _) do
    current_user = Auth.current_user(conn)

    render conn, "notification-counter.html",
            layout: blank_layout,
            current_user: current_user,
            notification_count: conn.assigns[:notification_count]
  end

  defp blank_layout do
    {LayoutView, "blank.html"}
  end

  defp releases_until_last_matching(releases, dep) do
    not_matching_releases =
      releases
      |> Enum.take_while(fn(%{"version" => version}) ->
          !VersionHelper.matching?(dep.required_version, version)
        end)
    last_matching_release =
      releases
      |> Enum.find(fn(%{"version" => version}) ->
          VersionHelper.matching?(dep.required_version, version)
        end)

    not_matching_releases ++ [last_matching_release]
  end
end
