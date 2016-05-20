defmodule GitHubAuthMock do
  def authorize_url!(_params \\ []) do
    "/"
  end

  def user_auth(code) when is_binary(code) do
    code
  end
end
