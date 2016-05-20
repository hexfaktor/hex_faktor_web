defmodule HexFaktor.GitHubAuthControllerTest do
  use HexFaktor.ConnCase

  test "GET /auth (logged in)" do
    conn = get conn(), "/auth"
    assert html_response(conn, 302)
    conn = get conn, "/auth/callback?code=1"
    assert html_response(conn, 302)

    conn = get conn, "/projects"
    assert html_response(conn, 200) =~ ~r/hf\:user_id/

    conn = get conn, "/auth/sign_out"
    assert html_response(conn, 302)

    conn = get conn, "/"
    refute html_response(conn, 200) =~ ~r/hf\:user_id/
  end
end
