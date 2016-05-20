defmodule HexFaktor.Plugs.AssignCurrentUserInfo do
  @moduledoc """
  """
  use Phoenix.Controller

  alias HexFaktor.Persistence.User
  alias HexFaktor.Persistence.Notification

  @socket_token_salt Application.get_env(:hex_faktor, :salt_user_socket)

  def init(default), do: default

  # Fetch the current user from the session and add it to `conn.assigns`. This
  # will allow you to have access to the current user in your views with
  # `@current_user`.
  def call(conn, _) do
    if user_id = get_session(conn, :current_user_id) do
      current_user = User.find_by_id(user_id)
      oauth_token = get_session(conn, :current_oauth_token)
      socket_token =
        if current_user do
          Phoenix.Token.sign(conn, @socket_token_salt, current_user.id)
        end
      notification_count =
        if current_user do
          Notification.count_unseen_for(current_user)
        end

      conn
      |> assign(:current_user, current_user)
      |> assign(:current_oauth_token, oauth_token)
      |> assign(:user_socket_token, socket_token)
      |> assign(:notification_count, notification_count)
    else
      conn
    end
  end
end
