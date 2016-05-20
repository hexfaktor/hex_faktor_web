defmodule HexFaktor.NotificationPublisher do
  @moduledoc """
  NotificationPublisher is responsible for generating new notifications.
  """

  alias HexFaktor.Broadcast
  alias HexFaktor.ProjectAccess

  alias Refaktor.Persistence.GitBranch
  alias HexFaktor.Persistence.Notification
  alias HexFaktor.Persistence.ProjectUser

  alias Refaktor.Job.Elixir.Deps.Model.DepsObject

  def handle_new_deps_objects(deps_objects, git_branch_id) do
    git_branch = GitBranch.find_by_id(git_branch_id)

    deps_objects
    |> Enum.each(&handle_new_deps_object(&1, git_branch))
  end

  defp handle_new_deps_object(%DepsObject{source: "git"}, _branch) do
  end
  defp handle_new_deps_object(%DepsObject{} = dep, git_branch) do
    all_user_ids = ProjectUser.find_user_ids_by_project_id(dep.project_id)

    reason_hash =
      ["dep", dep.project_id, dep.git_branch_id, dep.name, dep.available_versions]
      |> to_reason_hash()

    all_user_ids
    |> Enum.each(&handle_notification(&1, dep, git_branch, reason_hash))
  end

  defp handle_notification(user_id, dep, git_branch, reason_hash) do
    attributes = Notification.build_for_deps_object(user_id, dep, reason_hash)
    if create_notification?(user_id, dep.project_id, git_branch, attributes) do
      case Notification.ensure_for_deps_object(user_id, dep, reason_hash) do
        nil -> # Notification with `reason_hash` already existed
          nil
        notification ->
          map =
            notification
            |> Map.take([:id, :project_id, :git_branch_id])
          Broadcast.to_user(user_id, "notification.new", map)
      end
    else
      require Logger
      Logger.error "DID NOT create notification for branch `#{git_branch.name}`"
    end
  end

  def create_notification?(user_id, project_id, git_branch, _attributes) do
    settings = ProjectAccess.settings(project_id, user_id)
    settings.notification_branches |> Enum.member?(git_branch.name)
  end

  defp to_reason_hash(object) do
    string = object |> Macro.to_string

    :sha256
    |> :crypto.hash(string)
    |> Base.encode16
  end
end
