defmodule HexFaktor.NotificationControllerTest do
  use HexFaktor.ConnCase

  alias HexFaktor.Repo
  alias HexFaktor.Notification

  @existing_notification_id 1

  test "GET /notifications when NOT logged in", %{conn: conn} do
    conn = get conn, "/notifications/"
    assert access_denied?(conn)
  end

  test "GET /notifications", %{conn: conn} do
    conn = perform_login(conn)

    conn = get conn, "/notifications/"
    assert html_response(conn, 200)
  end


  # mark branch's notififcations as read

  test "GET /notifications/mark_as_read_for_branch when NOT logged in", %{conn: conn} do
    notification = create_fake_notification!
    conn = get conn, "/notifications/#{notification.id}"
    assert access_denied?(conn)
  end

  test "GET /notifications/mark_as_read_for_branch", %{conn: conn} do
    notification = create_fake_notification!
    notification2 = create_fake_notification!(2)
    assert is_nil(notification.seen_at)
    assert is_nil(notification2.seen_at)

    conn = perform_login(conn)

    conn = get conn, "/notifications/#{notification.id}"
    assert html_response(conn, 302)

    notification_reload = Repo.get(Notification, notification.id)
    notification_reload2 = Repo.get(Notification, notification2.id)
    refute is_nil(notification_reload.seen_at)
    assert is_nil(notification_reload2.seen_at)
  end

  # mark all as read

  test "POST /notifications/mark_as_read_for_user when NOT logged in", %{conn: conn} do
    notification = create_fake_notification!
    conn = post conn, "/notifications/mark_all_as_read"
    assert access_denied?(conn)
  end

  test "POST /notifications/mark_as_read_for_user", %{conn: conn} do
    notification = create_fake_notification!
    notification2 = create_fake_notification!(2)
    assert is_nil(notification.seen_at)
    assert is_nil(notification2.seen_at)

    conn = perform_login(conn)

    conn = post conn, "/notifications/mark_all_as_read"
    assert html_response(conn, 302)

    notification_reload = Repo.get(Notification, notification.id)
    notification_reload2 = Repo.get(Notification, notification2.id)
    refute is_nil(notification_reload.seen_at)
    assert is_nil(notification_reload2.seen_at)
  end

  defp create_fake_notification!(user_id \\ 1, project_id \\ 1, git_branch_id \\ 1, deps_object_id \\ 1) do
    %Notification{}
    |> Notification.changeset(%{
        user_id: user_id,
        project_id: project_id,
        git_branch_id: git_branch_id,
        deps_object_id: deps_object_id,
        reason: "dep",
        reason_hash: :random.uniform |> to_string
      })
    |> Repo.insert!
  end
end
