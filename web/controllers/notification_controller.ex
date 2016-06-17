defmodule HexFaktor.NotificationController do
  use HexFaktor.Web, :controller

  alias HexFaktor.Persistence.Notification
  alias HexFaktor.Auth

  @filter_all "all"

  def index(conn, params) do
    if Auth.current_user(conn) do
      conn |> perform_index(params)
    else
      conn |> access_denied()
    end
  end

  defp perform_index(conn, params) do
    current_user = Auth.current_user(conn)
    notifications =
      if params["filter"] == @filter_all do
        Notification.latest_for(current_user, 200, [:project, :git_branch, :deps_object, :package])
      else
        Notification.all_unseen_for(current_user, [:project, :git_branch, :deps_object, :package])
      end

    notification_map = to_map(notifications)

    assigns = [
      notification_map: notification_map,
      current_filter: params["filter"] |> nil_if_empty
    ]
    render conn, "index.html", assigns
  end


  defp to_map(notifications) do
    notifications
    |> Enum.reduce(%{}, &reduce_notifications/2)
  end

  defp reduce_notifications(notification, memo) do
    key =
      if notification.package do
        {:package, notification.package.name, notification.project_id, nil}
      else
        {:project, notification.project.name, notification.project_id, notification.git_branch_id}
      end

    if memo[key] do
      Map.put(memo, key, [notification | memo[key]])
    else
      Map.put(memo, key, [notification])
    end
  end

  def mark_as_read_for_branch(conn, %{"id" => id}) do
    current_user = Auth.current_user(conn)
    notification = Notification.find(id, [:project, :git_branch])

    if current_user && current_user.id == notification.user_id do
      conn |> perform_mark_as_read_for_branch(current_user, notification)
    else
      conn |> access_denied()
    end
  end

  def perform_mark_as_read_for_branch(conn, current_user, notification) do
    Notification.mark_as_seen_for_branch!(current_user, notification.project_id, notification.git_branch_id)
    redirect conn, to: path_for(notification)
  end


  def mark_as_read_for_user(conn, _params) do
    current_user = Auth.current_user(conn)

    if current_user do
      conn |> perform_mark_as_read_for_user(current_user)
    else
      conn |> access_denied()
    end
  end

  def perform_mark_as_read_for_user(conn, current_user) do
    Notification.mark_as_seen_for_user!(current_user)
    redirect conn, to: "/notifications"
  end

  defp path_for(notification) do
    path = "/"
    if notification.deps_object do
      project = notification.project
      path = "/github/#{project.name}"
    end
    path
  end
end
