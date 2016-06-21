defmodule HexFaktor.ProjectHookController do
  use HexFaktor.Web, :controller

  alias HexFaktor.AppEvent
  alias HexFaktor.Auth
  alias HexFaktor.Broadcast
  alias HexFaktor.Persistence.Package
  alias HexFaktor.Persistence.Project
  alias HexFaktor.Persistence.ProjectHook
  alias HexFaktor.ProjectAccess
  alias HexFaktor.ProjectBuilder
  alias HexFaktor.ProjectBuilder
  alias HexFaktor.ProjectSyncer

  require Logger

  @git_hub_api Application.get_env(:hex_faktor, :git_hub_api_module)

  @trigger_activate_webhook "activate-webhook"

  @event_webhook "project.webhook"

  #
  # /activate_webhook
  #
  # Creates webhooks on GitHub to be notified of pushes.
  #

  def activate_webhook(conn, %{"id" => id}) do
    current_user = Auth.current_user(conn)
    if current_user && ProjectAccess.granted?(id, current_user) do
      conn |> perform_activate_webhook(current_user, id)
    else
      conn |> access_denied()
    end
  end

  defp perform_activate_webhook(conn, current_user, project_id) do
    Logger.info "Event: project.activate_webhook - #{current_user.id} - #{project_id}"

    project = Project.find_by_id(project_id)
    if unsynced_project?(project) do
      current_user = Auth.current_user(conn)
      access_token = Auth.access_token(conn)
      ProjectSyncer.sync_project_via_github!(current_user, access_token, project.name)
      project = Project.find_by_id(project_id)
    end
    set_github_hook(conn, project, true)
    Project.update_active(project, true)
    Broadcast.to_user(current_user.id, @event_webhook, %{"project_id" => project.id, "active" => true})
    ProjectBuilder.run(current_user, project, project.default_branch, @trigger_activate_webhook)

    conn
    |> redirect_for_html("/projects/#{project.id}/settings")
  end

  #
  # /deactivate_webhook
  #
  # Deletes webhooks on GitHub.
  #

  def deactivate_webhook(conn, %{"id" => id}) do
    current_user = Auth.current_user(conn)
    if current_user && ProjectAccess.granted?(id, current_user) do
      conn |> perform_deactivate_webhook(current_user, id)
    else
      conn |> access_denied()
    end
  end

  defp perform_deactivate_webhook(conn, current_user, project_id) do
    Logger.info "Event: project.deactivate_webhook - #{current_user.id} - #{project_id}"

    project = Project.find_by_id(project_id)
    set_github_hook(conn, project, false)
    Project.update_active(project, false)
    Broadcast.to_user(current_user.id, @event_webhook, %{"project_id" => project.id, "active" => false})

    conn
    |> redirect_for_html("/projects/#{project.id}/settings")
  end

  defp set_github_hook(conn, project, active) do
    access_token = Auth.access_token(conn)
    project_hook_uid =
      case ProjectHook.find(project.id) do
        nil -> nil
        val -> val.uid
      end
    result = @git_hub_api.set_hook(access_token, project.name, project_hook_uid, active)
    case result do
      nil ->
        Logger.error "Activating webhook failed for project #{project.name}"
        nil
      %{"active" => active, "id" => uid} ->
        Logger.info "Setting hook #{uid} for #{project.name} to #{active}"
        ProjectHook.set(project.id, uid, active)
        active
      %{"message" => "Not Found"} ->
        ProjectHook.remove(project.id, project_hook_uid)
        set_github_hook(conn, project, active)
    end
  end

  defp unsynced_project?(project) do
    project.last_github_sync |> is_nil()
  end

  #
  # /receive_hex_package_update
  #
  # Receives the webhooks created with the functions above.
  #
  def receive_hex_package_update(conn, %{"name" => name, "github_url" => github_url} = payload) do
    Logger.info "Event: package.update_hex - #{name}"
    HexFaktor.Endpoint.broadcast!("feeds:lobby", "update", %{name: name})

    package = Package.ensure_and_update(name, payload)

    package_project = Project.find_by_html_url(github_url, [:git_repo_branches])

    if package_project && package_project.id != package.project_id do
      package |> Package.update_project_id(package_project.id)
    end

    dependent_projects_with_branches =
      ([package_project] ++ Project.all_with_dep(name))
      |> Enum.reject(&is_nil/1)

    AppEvent.log(:hex_package_update, name, dependent_projects_with_branches)

    dependent_projects_with_branches
    |> Enum.each(&ProjectBuilder.run_notification_branches(&1, "package_update"))

    HexFaktor.NotificationPublisher.handle_new_package_update(package)

    render(conn, "ok.json")
  end
end
