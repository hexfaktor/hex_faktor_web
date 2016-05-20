defmodule HexFaktor.ProjectSyncer do
  use HexFaktor.Web, :controller

  alias HexFaktor.Broadcast
  alias HexFaktor.Persistence.User
  alias HexFaktor.Persistence.Project
  alias HexFaktor.ProjectAccess

  require Logger

  @git_hub_api Application.get_env(:hex_faktor, :git_hub_api_module)

  @event_all_projects_sync "user.github_sync_projects"
  @event_project_sync "project.github_sync"

  @doc "Sync a single project via the GitHub API"
  def sync_project_via_github!(current_user, access_token, name) do
    project = sync_project_via_github!(access_token, name)

    Broadcast.call(current_user, @event_project_sync, %{complete: true})
    project
  end
  def sync_project_via_github!(access_token, name) do
    {project_info, branch_names} = @git_hub_api.project(access_token, name)

    project = Project.ensure(project_info)
    Project.ensure_repo(project, branch_names)
    Project.update_last_github_sync(project)
    project
  end

  @doc "Sync all projects of a User via the GitHub API"
  def sync_all_projects_via_github!(current_user, access_token) do
    projects =
      current_user
      |> load_projects(access_token)
      |> Enum.map(&Task.async(fn -> Project.ensure(&1) end))
      |> Enum.map(&Task.await(&1, 300_000))

    projects
    |> ProjectAccess.grant_exclusively(current_user) # TODO: scope this to the "github" provider!

    User.update_last_github_sync(current_user)
    Broadcast.call(current_user, @event_all_projects_sync, %{complete: true})
  end

  defp load_projects(current_user, access_token, link \\ "/user/repos", projects \\ []) do
    Broadcast.call(current_user, @event_all_projects_sync, %{link: link})
    case OAuth2.AccessToken.get!(access_token, link) do
      %OAuth2.Response{status_code: 200, headers: headers, body: body} ->
        projects = projects ++ body

        link =
          case List.keyfind(headers, "Link", 0) do
            {"Link", val} -> val
            _ -> ""
          end

        next_link =
          ~r/\<([^>]+)\>\; rel\=\"next\"/
          |> Regex.run(link)
          |> List.wrap
          |> Enum.at(1)

        if next_link do
          load_projects(current_user, access_token, next_link, projects)
        else
          projects
        end
      unexpected_response ->
        Logger.error "Unexpected response while syncing repos: #{inspect unexpected_response}"
        nil
    end
  end

end
