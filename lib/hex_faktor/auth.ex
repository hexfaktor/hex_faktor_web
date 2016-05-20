defmodule HexFaktor.Auth do
  @moduledoc """
  The Auth module holds functions which handle authorization.
  """

  @admin_user_ids Application.get_env(:hex_faktor, :admin_user_ids, [])

  @doc "Returns true if the logged in user is an admin."
  def admin?(conn) do
    case current_user(conn) do
      nil  -> false
      user -> Enum.member?(@admin_user_ids, user.id)
    end
  end

  @doc "Returns the GitHub access token for the current user."
  def access_token(conn), do: conn.assigns[:current_oauth_token]

  @doc "Returns the current user."
  def current_user(conn), do: conn.assigns[:current_user]

  @doc "Returns true if a user is logged in."
  def logged_in?(conn), do: !is_nil current_user(conn)
end
