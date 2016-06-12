defmodule HexFaktor.PackageControllerTest do
  use HexFaktor.ConnCase

  @existent_package_id 1


  test "GET /packages when NOT logged in", %{conn: conn} do
    conn = get conn, "/packages/"
    assert html_response(conn, 200)
  end

  test "GET /packages", %{conn: conn} do
    conn = perform_login(conn)

    conn = get conn, "/packages/"
    assert html_response(conn, 200)
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, package_path(conn, :index)
    assert html_response(conn, 200)
  end

  test "show package for existing package", %{conn: conn} do
    conn = get conn, package_path(conn, :show, "credo")
    assert html_response(conn, 200)
  end

  test "show package for NOT existing package", %{conn: conn} do
    conn = get conn, package_path(conn, :show, "html_sanitize_ex")
    assert html_response(conn, 200)
  end

  #
  # /update_settings_all
  #

  test "POST /update_settings_all when NOT logged in", %{conn: conn} do
    conn = post conn, "/packages/#{@existent_package_id}/follow"
    assert access_denied?(conn)
  end

  test "POST /update_settings_all", %{conn: conn} do
    conn = perform_login(conn)

    conn = post conn, "/packages/#{@existent_package_id}/follow"
    assert html_response(conn, 302)

    #TODO: test if package is actually followed
  end

  #
  # /update_settings_none
  #

  test "POST /update_settings_none when NOT logged in", %{conn: conn} do
    conn = post conn, "/packages/#{@existent_package_id}/unfollow"
    assert access_denied?(conn)
  end

  test "POST /update_settings_none", %{conn: conn} do
    conn = perform_login(conn)

    conn = post conn, "/packages/#{@existent_package_id}/unfollow"
    assert html_response(conn, 302)

    #TODO: test if package is actually unfollowed
  end

end
