defmodule HexFaktor.PackageControllerTest do
  use HexFaktor.ConnCase

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
end
