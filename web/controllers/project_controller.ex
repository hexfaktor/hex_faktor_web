defmodule HexFaktor.ProjectController do
  use HexFaktor.Web, :controller

  alias HexFaktor.DepsObjectFilter
  alias HexFaktor.ProjectAccess
  alias HexFaktor.ProjectBuilder
  alias HexFaktor.ProjectProvider
  alias HexFaktor.ProjectSyncer

  alias HexFaktor.Persistence.Project
  alias HexFaktor.Persistence.Notification

  alias HexFaktor.Auth
  alias HexFaktor.AppEvent
  alias HexFaktor.Broadcast

  alias Refaktor.Util.JSON

  require Logger

  # plug HexFaktor.Plugs.LoggedIn

  @default_branch "master"

  @filter_all "all"
  @filter_elixir "elixir"
  @filter_search "search"
  @filter_outdated "outdated"
  @filter_unknown "unknown"
  @filter_latest "latest"

  @git_hub_api Application.get_env(:hex_faktor, :git_hub_api_module)

  @trigger_web_post "manual"
  @trigger_web_hook "hook"

  @edit_sections [
    {"monitoring", "Settings"},
    {"notifications", "Notifications"},
    {"badges", "Get your Badge!"},
    {"history", "History"},
    {"github_sync", "Sync GitHub"},
  ]

  #
  # /
  #

  def index(conn, params) do
    if Auth.current_user(conn) do
      conn |> perform_index(params)
    else
      conn |> access_denied()
    end
  end

  defp perform_index(conn, params) do
    current_user = Auth.current_user(conn)
    search_query = params["q"] |> nil_if_empty
    current_project_filter = params["filter"] |> nil_if_empty

    if current_project_filter == @filter_search && is_nil(search_query) do
      current_project_filter = @filter_all
    end

    {all_projects, active_projects, outdated_projects} = ProjectProvider.user_projects(current_user)
    outdated_project_ids = outdated_projects |> Enum.map(&(&1.id))

    projects =
      all_projects
      |> filter_projects(current_project_filter, search_query, outdated_project_ids)

    if is_nil(current_project_filter) && Enum.empty?(projects) do
      redirect conn, to: project_path(conn, :index, filter: @filter_elixir)
    else
      assigns = [
        fresh_user?: fresh_user?(current_user),
        add_project?: false,
        projects: projects,
        project_filters: [@filter_elixir, @filter_all],
        current_project_filter: current_project_filter,
        search: search_query,
        active_projects_count: active_projects |> Enum.count,
        outdated_projects_count: outdated_projects |> Enum.count
      ]
      render conn, "index.html", assigns
    end
  end

  defp filter_projects(projects, nil, _search_query, _outdated_project_ids) do
    projects |> Enum.filter(&(&1.active))
  end
  defp filter_projects(projects, @filter_search, search_query, _outdated_project_ids) do
    projects
    |> Enum.filter(&name_matches?(&1.name, search_query))
  end
  defp filter_projects(projects, @filter_elixir, _search_query, _outdated_project_ids) do
    projects
    |> Enum.filter(&(&1.language == "Elixir" && !&1.fork))
  end
  defp filter_projects(projects, @filter_outdated, _search_query, outdated_project_ids) do
    projects
    |> Enum.filter(fn(p) ->
        outdated_project_ids
        |> Enum.member?(p.id)
      end)
  end
  defp filter_projects(projects, @filter_latest, _, _) do
    projects
    |> Enum.sort_by(&(&1.inserted_at))
    |> Enum.reverse
  end
  defp filter_projects(projects, @filter_all, _, _), do: projects

  defp name_matches?(name, search_query) do
    query = search_query |> String.downcase
    name
    |> String.downcase
    |> String.contains?(query)
  end

  #
  # /add_project
  #

  def add_project(conn, params) do
    if Auth.current_user(conn) do
      conn |> perform_add_project(params)
    else
      conn |> access_denied()
    end
  end

  defp perform_add_project(conn, params) do
    current_user = Auth.current_user(conn)
    search_query = params["q"] |> nil_if_empty
    current_project_filter = params["filter"] |> nil_if_empty

    if current_project_filter == @filter_search && is_nil(search_query) do
      current_project_filter = @filter_all
    end

    {all_projects, active_projects, outdated_projects} = ProjectProvider.user_projects(current_user)
    outdated_project_ids = outdated_projects |> Enum.map(&(&1.id))

    projects =
      all_projects
      |> filter_projects(current_project_filter, search_query, outdated_project_ids)
      |> Enum.reject(&(&1.active))

    if is_nil(current_project_filter) && Enum.empty?(projects) do
      redirect conn, to: project_path(conn, :add_project, filter: @filter_elixir)
    else
      assigns = [
        fresh_user?: fresh_user?(current_user),
        add_project?: true,
        projects: projects,
        project_filters: [@filter_elixir, @filter_all],
        current_project_filter: current_project_filter,
        search: search_query,
        active_projects_count: active_projects |> Enum.count,
        outdated_projects_count: outdated_projects |> Enum.count,
        outdated_project_ids: outdated_project_ids
      ]
      render conn, "add_project.html", assigns
    end
  end

  #
  # /edit
  #

  def edit(conn, %{"id" => id} = params) do
    current_user = Auth.current_user(conn)
    if current_user && ProjectAccess.granted?(id, current_user) do
      project = Project.find_by_id(id, [:git_repo_branches, :project_hooks])
      conn |> perform_edit(current_user, project, params)
    else
      conn |> access_denied()
    end
  end

  defp perform_edit(conn, current_user, project, params) when is_map(params) do
    section = params["section"] |> nil_if_empty || "monitoring"
    assigns = [
      current_section: section,
      sections: @edit_sections,
      unsynced_project?: ProjectProvider.unsynced_project?(project),
      project: project
    ]
    perform_edit(conn, current_user, project, assigns, section)
  end
  defp perform_edit(conn, _current_user, project, assigns, "monitoring" = section) do
    changeset = project |> HexFaktor.Project.changeset(%{})
    monitored? = project.project_hooks |> Enum.any?(&(&1.active))
    assigns = assigns ++ [changeset: changeset, monitored?: monitored?]
    render(conn, "edit.html", assigns)
  end
  defp perform_edit(conn, _current_user, project, assigns, "history" = section) do
    builds =
      if ProjectProvider.unsynced_project?(project) do
        []
      else
        Refaktor.Persistence.Build.all(project.git_repo_id)
      end
    assigns = assigns ++ [builds: builds]
    render(conn, "edit.html", assigns)
  end
  defp perform_edit(conn, current_user, project, assigns, "notifications" = section) do
    assigns = assigns ++ [
      settings: ProjectAccess.settings(project, current_user),
      git_branches: project.git_repo_branches
    ]
    render(conn, "edit.html", assigns)
  end
  defp perform_edit(conn, _current_user, _project, assigns, section) do
    render(conn, "edit.html", assigns)
  end

  #
  # /update
  #

  def update(conn, %{"id" => id, "project" => project_params}) do
    current_user = Auth.current_user(conn)
    if current_user && ProjectAccess.granted?(id, current_user) do
      project = Project.find_by_id(id, [:git_repo_branches, :project_hooks])
      conn |> perform_update(current_user, project, project_params)
    else
      conn |> access_denied()
    end
  end

  defp perform_update(conn, _current_user, project, %{"use_lock_file" => use_lock_file}) do
    Project.update_use_lock_file(project, use_lock_file)

    conn
    |> put_flash(:info, "Analysis settings updated successfully.")
    |> redirect(to: project_path(conn, :edit, project.id))
  end

  #
  # /update_settings
  #

  def update_settings(conn, %{"id" => id} = params) do
    current_user = Auth.current_user(conn)
    if current_user && ProjectAccess.granted?(id, current_user) do
      project = Project.find_by_id(id, [:git_repo_branches, :project_hooks])
      conn |> perform_update_settings(current_user, project, params)
    else
      conn |> access_denied()
    end
  end

  defp perform_update_settings(conn, current_user, project, params) do
    # TODO: do stuff
    changeset = ProjectAccess.update_settings(project, current_user, params)
    if changeset.valid? do
      conn = conn |> put_flash(:info, "Notification settings updated successfully.")
    end
    redirect(conn, to: project_path(conn, :edit, project.id) <> "?section=notifications")
  end

  #
  # /rebuild
  #

  def rebuild_via_web(conn, %{"id" => id} = params) do
    current_user = Auth.current_user(conn)
    # let everyone rebuild projects! power to the people!
    #if current_user && ProjectAccess.granted?(id, current_user) do
      conn |> perform_rebuild_via_web(current_user, id, params["branch"] |> nil_if_empty)
    #else
    #  conn |> access_denied()
    #end
  end

  defp perform_rebuild_via_web(conn, current_user, project_id, branch_name) do
    project = Project.find_by_id(project_id)
    ProjectBuilder.run(current_user, project, branch_name, @trigger_web_post)
    render(conn, "ok.json")
  end

  #
  # /rebuild_via_hook
  #

  def rebuild_via_hook(conn, %{"id" => id}) do
    project = Project.find_by_id(id)
    branch_name = project.default_branch
    ProjectBuilder.run(nil, project, branch_name, @trigger_web_hook)
    AppEvent.log(:rebuild_via_hook, :id, project, branch_name)
    render(conn, "ok.json")
  end

  def rebuild_via_hook(conn, payload) do
    project =
      case payload do
        %{"pull_request" => _pull_request} ->
          nil
        %{"repository" => %{"id" => uid}} ->
          Project.find_by_uid(uid)
        value ->
          if Mix.env != :test do
            Logger.error("ProjectController.rebuild_via_hook: bad payload: #{inspect value}")
          end
          nil
      end

    perform_rebuild_via_hook(conn, project, payload)
  end

  defp perform_rebuild_via_hook(conn, nil, _) do
    render(conn, "error.json")
  end
  defp perform_rebuild_via_hook(conn, _project, nil) do
    render(conn, "error.json")
  end
  defp perform_rebuild_via_hook(conn, project, payload) when is_map(payload) do
    branch_name = get_branch_name_from_payload(payload, project)
    perform_rebuild_via_hook(conn, project, branch_name)
  end
  defp perform_rebuild_via_hook(conn, project, branch_name) when is_binary(branch_name) do
    ProjectBuilder.run(nil, project, branch_name, @trigger_web_hook)
    AppEvent.log(:rebuild_via_hook, :github, project, branch_name)
    render(conn, "ok.json")
  end

  defp get_branch_name_from_payload(%{"ref" => ref}, _project) do
    # don't return branch_name for ref/tags
    if ref |> String.match?(~r/^refs\/heads\//) do
      String.replace(ref, "refs/heads/", "")
    end
  end
  defp get_branch_name_from_payload(_, project) do
    project.default_branch
  end

  #
  # /show
  #

  def show_github(conn, %{"owner" => owner, "name" => name} = params) do
    show(conn, %{"provider" => "github", "name" => "#{owner}/#{name}", "branch" => params["branch"], "env" => params["env"], "filter" => params["filter"]})
  end

  def show(conn, %{"provider" => _, "name" => _} = params) do
    current_user = Auth.current_user(conn)
    assigns =
      current_user
      |> ProjectProvider.assigns_for(params)

    mark_notifications_as_seen!(current_user, assigns)

    render conn, "show.html", assigns
  end

  def mark_notifications_as_seen!(nil, _), do: nil
  def mark_notifications_as_seen!(current_user, assigns) do
    project = assigns[:project]
    branch = assigns[:branch]
    if branch do
      Notification.mark_as_seen_for_branch!(current_user, project.id, branch.id)
    end
  end

  #
  # /sync (single project)
  #

  def sync_github(conn, %{"owner" => owner, "name" => name}) do
    current_user = Auth.current_user(conn)
    access_token = Auth.access_token(conn)

    # TODO: check permission to sync the project
    project =
      ProjectSyncer.sync_project_via_github!(current_user, access_token, "#{owner}/#{name}")
    conn
    |> redirect_for_html("/projects/#{project.id}/settings?section=github_sync")
  end

  #
  # /sync (all projects)
  #

  def sync_github(conn, _params) do
    sync_projects(conn, %{})
  end

  defp sync_projects(conn, params) do
    if Auth.current_user(conn) do
      conn |> perform_sync_projects(params)
    else
      conn |> access_denied()
    end
  end

  defp perform_sync_projects(conn, _params) do
    current_user = Auth.current_user(conn)
    access_token = Auth.access_token(conn)
    spawn fn ->
      ProjectSyncer.sync_all_projects_via_github!(current_user, access_token)
    end

    conn
    |> redirect_for_html("/settings?section=github_sync")
  end

  # Returns true if the User has just registered
  defp fresh_user?(user) do
    user.last_github_sync |> is_nil()
  end
end
