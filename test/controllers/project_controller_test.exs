defmodule HexFaktor.ProjectControllerTest do
  use HexFaktor.ConnCase

  @valid_attrs %{clone_url: "some content", default_branch_id: "some content", git_repo_id: 42, html_url: "some content", name: "some content", provider: "some content"}
  @invalid_attrs %{}

  @existent_project_id    1
  @existent_project_name  "rrrene/credo"

  #
  # /
  #

  test "GET /projects when NOT logged in", %{conn: conn} do
    conn = get conn, "/projects/"
    assert access_denied?(conn)
  end

  test "GET /projects", %{conn: conn} do
    conn = perform_login(conn)

    conn = get conn, "/projects/"
    assert html_response(conn, 200)
  end

  #
  # /edit section: "history"
  #

  test "GET /builds when NOT logged in", %{conn: conn} do
    conn = get conn, "/projects/#{@existent_project_id}/settings?section=history"
    assert access_denied?(conn)
  end

  test "GET /builds", %{conn: conn} do
    conn = perform_login(conn)

    conn = get conn, "/projects/#{@existent_project_id}/settings?section=history"
    assert html_response(conn, 200)
  end

  #
  # /update_settings
  #

  test "POST /update_settings when NOT logged in", %{conn: conn} do
    conn = post conn, "/projects/#{@existent_project_id}/update_settings"
    assert access_denied?(conn)
  end

  test "POST /update_settings", %{conn: conn} do
    conn = perform_login(conn)

    params = %{
      "notification_branches" => ["develop"],
      "email_enabled" => "false"
    }
    conn = post conn, "/projects/#{@existent_project_id}/update_settings", params
    assert html_response(conn, 302)
  end

  #
  # /rebuild
  #

  test "POST /rebuild when NOT logged in", %{conn: conn} do
    conn = post conn, "/projects/#{@existent_project_id}/rebuild"
    assert access_denied?(conn)
  end

  test "POST /rebuild", %{conn: conn} do
    conn = perform_login(conn)

    conn = post conn, "/projects/#{@existent_project_id}/rebuild"
    assert json_response(conn, 200) == %{"ok" => true}
  end

  #
  # /rebuild_via_hook
  #

  test "POST /rebuild_via_hook 2", %{conn: conn} do
    conn = post conn, rebuild_via_hook_path(conn, :rebuild_via_hook), %{"ref" => "refs/heads/master", "before" => "9049f1265b7d61be4a8904a9a27120d2064dab3b", "after" => "0d1a26e67d8f5eaf1f6ba5c57fc3c7d91ac0fd1c", "repository" => %{"id" => 123, "full_name" => "rrrene/credo"}}
    assert json_response(conn, 200) == %{"ok" => true}
  end

  test "POST /rebuild_via_hook w/ tag ref", %{conn: conn} do
    conn = post conn, rebuild_via_hook_path(conn, :rebuild_via_hook), %{"ref" => "refs/tags/v0.1.1", "before" => "9049f1265b7d61be4a8904a9a27120d2064dab3b", "after" => "0d1a26e67d8f5eaf1f6ba5c57fc3c7d91ac0fd1c", "repository" => %{"id" => 123, "full_name" => "rrrene/credo"}}
    assert json_response(conn, 200) == %{"error" => true}
  end

  test "POST /rebuild_via_hook w/ bad project id", %{conn: conn} do
    conn = post conn, rebuild_via_hook_path(conn, :rebuild_via_hook), %{"ref" => "refs/heads/master", "before" => "9049f1265b7d61be4a8904a9a27120d2064dab3b", "after" => "0d1a26e67d8f5eaf1f6ba5c57fc3c7d91ac0fd1c", "repository" => %{"id" => 999, "full_name" => "rrrene/credo"}}
    assert json_response(conn, 200) == %{"error" => true}
  end

  test "POST /rebuild_via_hook w/ bad payload", %{conn: conn} do
    conn = post conn, rebuild_via_hook_path(conn, :rebuild_via_hook), payload: ~s({"repository":{"full_name":"rrrene/credo"}})
    assert json_response(conn, 200) == %{"error" => true}
  end

  #
  # /show
  #

  test "GET /projects/show when NOT logged in", %{conn: conn} do
    conn = get conn, "/github/#{@existent_project_name}"
    assert html_response(conn, 200)
  end

  test "GET /projects/show", %{conn: conn} do
    conn = perform_login(conn)

    conn = get conn, "/github/#{@existent_project_name}"
    assert html_response(conn, 200)
  end
end
