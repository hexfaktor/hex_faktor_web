defmodule HexFaktor.Persistence.AppEventLog do
  import Ecto.Query, only: [from: 2]

  alias HexFaktor.Repo
  alias HexFaktor.AppEventLog

  def all do
    Repo.all(AppEventLog)
  end

  def create(current_user, key, params) do
    user_id = current_user && current_user.id
    %AppEventLog{
      user_id: user_id,
      key: key,
      value: params
    } |> Repo.insert!
  end
end
