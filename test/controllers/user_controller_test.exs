defmodule HexFaktor.UserControllerTest do
  use HexFaktor.ConnCase

  @valid_attrs %{email_notification_frequency: "none", email_newsletter: false}
  @invalid_attrs %{email_notification_frequency: "something"}

  test "GET /settings when NOT logged in", %{conn: conn} do
    conn = get conn, "/settings"
    assert access_denied?(conn)
  end

  test "GET /settings", %{conn: conn} do
    conn = perform_login(conn)

    conn = get conn, "/settings"
    assert html_response(conn, 200)
  end

  test "PUT /settings", %{conn: conn} do
    conn = perform_login(conn)
    user = Repo.get!(HexFaktor.User, 1)

    assert "weekly" == user.email_notification_frequency
    assert user.email_newsletter

    conn = put conn, "/settings", user: @valid_attrs
    assert html_response(conn, 302)

    user = Repo.get!(HexFaktor.User, 1)
    assert "none" == user.email_notification_frequency
    refute user.email_newsletter
  end

  test "PUT /settings change email", %{conn: conn} do
    conn = perform_login(conn)
    user = Repo.get!(HexFaktor.User, 1)

    refute nil == user.email
    refute nil == user.email_verified_at
    assert nil == user.email_token

    conn = put conn, "/settings", user: %{email: "rf-changed@bamaru.de"}
    assert html_response(conn, 302)

    user = Repo.get!(HexFaktor.User, 1)
    refute nil == user.email
    assert nil == user.email_verified_at
    refute nil == user.email_token
  end

  test "PUT /settings with invalid attrs", %{conn: conn} do
    conn = perform_login(conn)
    user = Repo.get!(HexFaktor.User, 1)

    assert "weekly" == user.email_notification_frequency

    conn = put conn, "/settings", user: @invalid_attrs
    assert html_response(conn, 200)

    user = Repo.get!(HexFaktor.User, 1)
    assert "weekly" == user.email_notification_frequency
  end

end
