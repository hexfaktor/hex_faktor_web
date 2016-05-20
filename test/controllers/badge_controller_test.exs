defmodule HexFaktor.BadgeControllerTest do
  use HexFaktor.ConnCase

  @existent_project_id    1
  @existent_project_name  "rrrene/credo"

  #
  # /badge
  #

  test "GET /projects/badge when NOT logged in", %{conn: conn} do
    conn = get conn, "/badge/all/github/#{@existent_project_name}"
    assert svg_response(conn, 200)
  end

  test "GET /projects/badge", %{conn: conn} do
    conn = perform_login(conn)

    conn = get conn, "/badge/all/github/#{@existent_project_name}"
    assert svg_response(conn, 200)
  end
end
