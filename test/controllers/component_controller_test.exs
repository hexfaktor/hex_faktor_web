defmodule HexFaktor.ComponentControllerTest do
  use HexFaktor.ConnCase

  @existent_project_id 1

  test "GET /project-list-item when NOT logged in", %{conn: conn} do
    conn = get conn, "/component/project-list-item/#{@existent_project_id}"
    assert html_response(conn, 403)
  end

  test "GET /project-list-item when logged in", %{conn: conn} do
    conn = perform_login(conn)

    conn = get conn, "/component/project-list-item/#{@existent_project_id}"
    assert html_response(conn, 200)
  end

end
