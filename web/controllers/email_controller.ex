defmodule HexFaktor.EmailController do
  use HexFaktor.Web, :controller

  alias HexFaktor.Auth
  alias HexFaktor.NotificationMailer
  alias HexFaktor.Persistence.Notification
  alias HexFaktor.ProjectProvider
  alias HexFaktor.LayoutView

  def notifications(conn, params) do
    user = Auth.current_user(conn)
    notifications = Notification.all_unseen_for(user, [:project, :git_branch, :deps_object, :package])
    {_, _, outdated_projects} = ProjectProvider.user_projects(user)

    assigns = NotificationMailer.notifications(user, notifications, outdated_projects)
    render(conn, "notifications.html", assigns ++ [layout: {LayoutView, "email.html"}])
  end

  def status_report(conn, params) do
    user = Auth.current_user(conn)
    {_, active_projects, outdated_projects} = ProjectProvider.user_projects(user)
    package_notifications = Notification.all_unseen_for_packages_for(user, [:package])

    assigns = NotificationMailer.status_report(user, active_projects, outdated_projects, package_notifications)
    render(conn, "status_report.html", assigns ++ [layout: {LayoutView, "email.html"}])
  end

  def validation(conn, params) do
    user = Auth.current_user(conn)

    assigns = NotificationMailer.validation(user)
    render(conn, "validation.html", assigns ++ [layout: {LayoutView, "email.html"}])
  end
end
