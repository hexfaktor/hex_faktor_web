defmodule GitHubAuth do
  @moduledoc """
  An OAuth2 strategy for GitHub.
  """
  use OAuth2.Strategy

  alias OAuth2.Strategy.AuthCode

  @github_access_token Application.get_env(:hex_faktor, :github_access_token)
  @github_client_id Application.get_env(:hex_faktor, :github_client_id)
  @github_client_secret Application.get_env(:hex_faktor, :github_client_secret)

  # Public API

  def access_token do
    OAuth2.AccessToken.new(@github_access_token, new())
    |> IO.inspect
  end

  def new do
    OAuth2.Client.new([
      strategy: __MODULE__,
      client_id: @github_client_id || System.get_env("CLIENT_ID"),
      client_secret: @github_client_secret || System.get_env("CLIENT_SECRET"),
      redirect_uri: System.get_env("REDIRECT_URI"),
      site: "https://api.github.com",
      authorize_url: "https://github.com/login/oauth/authorize",
      token_url: "https://github.com/login/oauth/access_token"
    ])
  end

  def authorize_url!(params \\ []) do
    OAuth2.Client.authorize_url!(new(), params)
  end

  def user_auth(code) when is_binary(code) do
    # Exchange an auth code for an access token
    OAuth2.Client.get_token!(new(), code: code)
  end

  def get_token!(params \\ [], _headers \\ []) do
    OAuth2.Client.get_token!(new(), params)
  end

  # Strategy Callbacks

  def authorize_url(client, params) do
    AuthCode.authorize_url(client, params)
  end

  def get_token(client, params, headers) do
    client
    |> put_header("Accept", "application/json")
    |> put_header("Content-Type", "application/json")
    |> AuthCode.get_token(params, headers)
  end
end
