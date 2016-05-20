defmodule HexFaktor.ProjectHookController do
  use HexFaktor.Web, :controller

  alias HexFaktor.Auth
  alias HexFaktor.Broadcast
  alias HexFaktor.ProjectAccess
  alias HexFaktor.ProjectBuilder
  alias HexFaktor.ProjectSyncer
  alias HexFaktor.Persistence.Project
  alias HexFaktor.Persistence.ProjectHook

  require Logger

  @git_hub_api Application.get_env(:hex_faktor, :git_hub_api_module)

  @trigger_activate_webhook "activate-webhook"

  @event_webhook "project.webhook"

  #
  # /activate_webhook
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

  def deactivate_webhook(conn, %{"id" => id}) do
    current_user = Auth.current_user(conn)
    if current_user && ProjectAccess.granted?(id, current_user) do
      conn |> perform_deactivate_webhook(current_user, id)
    else
      conn |> access_denied()
    end
  end

  defp perform_deactivate_webhook(conn, current_user, project_id) do
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
end
