defmodule HexFaktor.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  imports other functionality to make it easier
  to build and query models.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      use Phoenix.ConnTest

      alias HexFaktor.Repo
      import Ecto.Model
      import Ecto.Query, only: [from: 2]

      import HexFaktor.Router.Helpers

      # The default endpoint for testing
      @endpoint HexFaktor.Endpoint

      def perform_login(conn, user_id \\ 1) do
        conn = get conn, "/auth/callback?code=#{user_id}"
        assert html_response(conn, 302)
        conn
      end

      def svg_response(conn, status) do
        body = response(conn, status)
        _    = response_content_type(conn, :svg)
        body
      end

      def access_denied?(conn) do
        html_response(conn, 403)
      end
    end
  end

  setup tags do
    unless tags[:async] do
      Ecto.Adapters.SQL.restart_test_transaction(HexFaktor.Repo, [])
    end

    {:ok, conn: Phoenix.ConnTest.conn()}
  end
end
