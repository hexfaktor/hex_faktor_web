defmodule HexFaktor.Plugs.LoggedIn do
  @moduledoc """
  """
  use HexFaktor.Web, :controller
  alias HexFaktor.Auth

  def init(default), do: default

  def call(conn, _opts) do
    case Auth.current_user(conn) do
      nil -> redirect(conn, to: "/") |> halt
      _   -> conn
    end
  end
end
