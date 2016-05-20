defmodule HexFaktor.ProjectAccess do
  alias HexFaktor.Persistence.ProjectUser
  alias HexFaktor.Persistence.ProjectUserSettings

  def granted?(_project_id, nil) do # not logged in
    true
  end
  def granted?(project_id, user) when is_binary(project_id) do # not logged in
    {project_id, ""} = project_id |> Integer.parse
    granted?(project_id, user)
  end
  def granted?(project_id, user) do
    project_user = ProjectUser.find(project_id, user.id)
    !is_nil(project_user)
  end

  def grant_exclusively(projects, user) do
    current_project_ids = currently_granted(user)
    new_project_ids = projects |> Enum.map(&(&1.id))

    current_project_ids
    |> Enum.each(fn(current_project_id) ->
        unless new_project_ids |> Enum.member?(current_project_id) do
          ProjectUser.remove(current_project_id, user.id)
        end
      end)

    projects
    |> Enum.each(&grant(&1, user))
  end

  def grant(project, user) do
    ProjectUser.ensure(project.id, user.id)
    ProjectUserSettings.ensure(project.id, user.id, project.default_branch)
  end

  defp currently_granted(user) do
    ProjectUser.find_by_user_id(user.id)
    |> Enum.map(&(&1.project_id))
  end

  def settings(project_id, user_id) when is_integer(project_id) and is_integer(user_id) do
    ProjectUserSettings.find(project_id, user_id)
  end
  def settings(project, user) do
    settings(project.id, user.id)
  end

  def update_settings(project, user, params) do
    attributes = %{
      notification_branches: params["notification_branches"],
      email_enabled: params["email_enabled"] == "true"
    }
    project_user_settings =
      ProjectUserSettings.ensure(project.id, user.id, project.default_branch)
    ProjectUserSettings.update_attributes(project_user_settings, attributes)
  end
end
