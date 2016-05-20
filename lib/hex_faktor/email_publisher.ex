defmodule HexFaktor.EmailPublisher do
  alias HexFaktor.NotificationMailer
  alias HexFaktor.Persistence.User
  alias HexFaktor.Persistence.Notification
  alias HexFaktor.ProjectProvider

  require Logger

  def send_daily_emails do
    all_users = User.find_by_verified_email_frequency("daily")
    user_ids = all_users |> Enum.map(&(&1.id))

    unsent_notifications = Notification.find_unseen_and_unsent_for(user_ids, [:project, :git_branch, :deps_object, :package])

    relevant_user_ids =
      unsent_notifications
      |> Enum.map(&(&1.user_id))
      |> Enum.uniq

    relevant_user_ids
    |> Enum.map(&Task.async(fn -> send_notifications(&1, all_users, unsent_notifications) end))
    |> Enum.map(&Task.await(&1, 30_000))
  end

  defp send_notifications(user_id, all_users, unsent_notifications) do
    user = all_users |> Enum.find(&(&1.id == user_id))
    notifications = unsent_notifications |> Enum.filter(&(&1.user_id == user_id))
    {_, _, outdated_projects} = ProjectProvider.user_projects(user)

    #IO.puts "Sending mail to #{user.email}"
    if notifications |> Enum.any? do
      case NotificationMailer.send_notifications(user, notifications, outdated_projects) do
        :ok ->
          Notification.mark_as_email_sent_for_user!(user)
          Logger.info "[email] #{now} sent to <#{user.email}>"
        _ ->
          Logger.error "[email] #{now} sending failed for User##{user.id} <#{user.email}>"
      end
    end
  end

  @doc "Sends status reports in the weekly email"
  def send_weekly_emails do
    all_users = User.find_by_verified_email_frequency("weekly")

    all_users
    |> Enum.map(&Task.async(fn -> send_status_report(&1) end))
    |> Enum.map(&Task.await(&1, 30_000))
  end

  defp send_status_report(user) do
    {_, active_projects, outdated_projects} = ProjectProvider.user_projects(user)

    #IO.puts "Sending mail to #{user.email}"
    case NotificationMailer.send_status_report(user, active_projects, outdated_projects) do
      :ok ->
        Notification.mark_as_email_sent_for_user!(user)
        Logger.info "[email] #{now} status_report sent to <#{user.email}>"
      _ ->
        Logger.error "[email] #{now} status_report sending failed for User##{user.id} <#{user.email}>"
    end
  end

  @doc "Returns a formatted timestamp for logging"
  def now do
    Timex.Date.now
    |> Timex.DateFormat.format!("%Y-%m-%d %H:%M:%S", :strftime)
  end
end
