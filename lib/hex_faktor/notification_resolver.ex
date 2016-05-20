defmodule HexFaktor.NotificationResolver do
  @moduledoc """
  NotificationResolver is responsible for marking no-longer-valid notifications
  as resolved.
  """

  alias HexFaktor.Persistence.Notification

  def handle_existing_notifications(deps_objects, job_id, git_branch_id) do
    git_branch_id
    |> Notification.all_unseen_for_branch([:deps_object])
    |> handle_notifications(deps_objects, job_id)
  end

  def handle_notifications(notifications, deps_objects, job_id) do
    notifications
    |> Enum.filter(&resolve_notification?(&1, deps_objects))
    |> Enum.map(&(&1.id))
    |> Notification.mark_as_resolved_by_build_job!(job_id)
  end

  # Returns true if the given `notification` is no longer valid because
  # it concerned itself with one of the now up-to-date `deps_objects`
  defp resolve_notification?(notification, deps_objects) do
    dep = notification.deps_object
    deps_objects
    |> Enum.any?(&(&1.id != dep.id && &1.name == dep.name && &1.source == dep.source))
  end
end
