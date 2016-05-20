defmodule HexFaktor.GitHubAuthController do
  use HexFaktor.Web, :controller

  @git_hub_auth Application.get_env(:hex_faktor, :git_hub_auth_module)
  @git_hub_api Application.get_env(:hex_faktor, :git_hub_api_module)
  @git_hub_scope "user:email,read:repo_hook,write:repo_hook,read:org"

  alias HexFaktor.AppEvent
  alias HexFaktor.Auth
  alias HexFaktor.Persistence.User
  alias HexFaktor.NotificationMailer
  alias HexFaktor.EmailVerifier

  require Logger

  @doc """
  This action is reached via `/auth` and redirects to the OAuth2 provider
  based on the chosen strategy.
  """
  def sign_in(conn, _params) do
    redirect conn, external: @git_hub_auth.authorize_url!(scope: @git_hub_scope)
  end

  @doc """
  This action is reached via `/auth/callback` is the the callback URL that
  the OAuth2 provider will redirect the user back to with a `code` that will
  be used to request an access token. The access token will then be used to
  access protected resources on behalf of the user.
  """
  def callback(conn, %{"code" => code}) do
    token =
      code
      |> @git_hub_auth.user_auth

    current_user =
      token
      |> @git_hub_api.user
      |> find_or_create_user(conn)

    conn
    |> put_session(:current_oauth_token, token)
    |> put_session(:current_user_id, current_user.id)
    |> assign(:current_user, current_user)
    |> redirect(to: "/projects?just_signed_in=true")
  end

  @doc """
  This action is reached via `/auth/sign_out` and redirects to the OAuth2 provider
  based on the chosen strategy.
  """
  def sign_out(conn, _params) do
    user = Auth.current_user(conn)
    AppEvent.log(:sign_out, user)

    conn
    |> clear_session
    |> redirect(to: "/?just_signed_out=true")
  end

  def find_or_create_user(user_auth_params, conn) do
    %{"login" => user_name} = user_auth_params

    case User.find_by_user_name(user_name) do
      nil ->
        user = User.create_from_auth_params(user_auth_params)
        if user.email do
          user_params = EmailVerifier.update_email_params(conn, user, %{})
          changeset = User.update_attributes(user, user_params)
          user = User.find_by_id(user.id)
          if changeset.valid? do
            NotificationMailer.send_validation(user)
          else
            Logger.error "adding email_token to user failed: User##{user.id}"
          end
        end
        AppEvent.log(:sign_up, user)
        user
      user ->
        AppEvent.log(:sign_in, user)
        user
    end
  end
end
