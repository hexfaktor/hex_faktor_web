defmodule HexFaktor.Persistence.User do
  import Ecto.Query, only: [from: 2]

  alias HexFaktor.Repo
  alias HexFaktor.User

  def create_from_auth_params(user_auth_params) do
    %User{
      uid: user_auth_params["id"],
      full_name: user_auth_params["name"],
      user_name: user_auth_params["login"],
      email: user_auth_params["email"],
      provider: "github",
      email_notification_frequency: "weekly",
      email_newsletter: true
    } |> Repo.insert!
  end

  def find_by_verified_email_frequency(frequency) do
    query = from u in User,
            where: not is_nil(u.email_verified_at) and
                    u.email_notification_frequency == ^frequency,
            select: u
    Repo.all(query)
  end

  def find_by_email_and_token(email, email_token) do
    query = from u in User,
            where: u.email == ^email and u.email_token == ^email_token,
            select: u
    Repo.one(query)
  end

  def find_by_id(user_id) do
    case user_id do
      nil -> nil
      _ -> Repo.get(User, user_id)
    end
  end

  def find_by_user_name(user_name, provider \\ "github") do
    query = from u in User,
            where: u.user_name == ^user_name and u.provider == ^provider,
            select: u
    Repo.one(query)
  end

  def update_last_github_sync(user) do
    attributes = %{last_github_sync: :calendar.universal_time}
    changeset = User.changeset user, attributes
    Repo.update!(changeset)
  end

  def update_attributes(user, attributes) do
    changeset = User.changeset user, attributes
    if changeset.valid?, do: Repo.update!(changeset)
    changeset
  end
end
