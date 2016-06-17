defmodule HexFaktor.NotificationMailer do
  use Mailgun.Client, Application.get_env(:hex_faktor, :mailgun)

  alias Phoenix.View
  alias HexFaktor.LayoutView
  alias HexFaktor.EmailView

  @base_url Application.get_env(:hex_faktor, :base_url)
  @from "HexFaktor <notifications@hexfaktor.org>"

  def validation(user) do
    title = "Please confirm your e-mail address!"
    [
      title: title,
      alert_title: title,
      alert_title_bg_color: "#0E4879",
      html_title: "HexFaktor",
      email: user.email,
      base_url: @base_url,
      validation_url: validation_url(user)
    ]
  end

  def send_validation(user) do
    assigns = validation(user)
    send_email to: user.email,
               from: @from,
               subject: "[HexFaktor] #{assigns[:title]}",
               html: render("validation.html", assigns)
  end

  def notifications(user, notifications, outdated_projects) do
    notification_map = to_map(notifications)
    notification_count = notification_map |> map_size
    [
      title: "You have #{notification_count} unread notifications!",
      title_bg_color: "#0E4879",
      html_title: "HexFaktor",
      email: user.email,
      base_url: @base_url,
      unsubcribe_url: settings_url,
      notification_count: notification_count,
      notification_map: notification_map,
      outdated_projects: outdated_projects
    ]
  end

  def send_notifications(user, notifications, outdated_projects) do
    assigns = notifications(user, notifications, outdated_projects)
    send_email to: user.email,
               from: @from,
               subject: "[HexFaktor] #{assigns[:title]}",
               html: render("notifications.html", assigns)
    #IO.puts render("notifications.html", assigns)
    :ok
  end

  def status_report(user, active_projects, outdated_projects, package_notifications) do
    [
      title: "You have #{outdated_projects |> Enum.count} projects with outdated dependencies!",
      html_title: "HexFaktor - Weekly Report",
      email: user.email,
      base_url: @base_url,
      unsubcribe_url: settings_url,
      active_projects: active_projects,
      outdated_projects: outdated_projects,
      package_notifications: package_notifications
    ]
  end

  def send_status_report(user, active_projects, outdated_projects, package_notifications) do
    assigns = status_report(user, active_projects, outdated_projects, package_notifications)
    send_email to: user.email,
               from: @from,
               subject: "[HexFaktor] #{assigns[:title]}",
               html: render("status_report.html", assigns)
    :ok
  end

  defp render(template, assigns) do
    assigns = assigns ++ [layout: {LayoutView, "email.html"}]
    View.render_to_string(EmailView, template, assigns)
  end

  defp validation_url(user) do
    "#{@base_url}/verify_email?email=#{URI.encode_www_form user.email}&token=#{URI.encode_www_form user.email_token}"
  end

  defp settings_url do
    "#{@base_url}/settings"
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
end
