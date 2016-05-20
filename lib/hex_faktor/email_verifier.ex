defmodule HexFaktor.EmailVerifier do
  @email_token_salt Application.get_env(:hex_faktor, :salt_user_socket)

  @doc "Modifies a params Map for db insert/update."
  def update_email_params(conn, user, params) do
    params
    |> Map.put("email_token", new_email_token(conn, user))
    |> Map.put("email_verified_at", nil)
  end

  defp new_email_token(conn, user) do
    conn
    |> Phoenix.Token.sign(@email_token_salt, user.id)
    |> String.replace(~r/[^a-zA-Z0-9]/, "")
  end
end
