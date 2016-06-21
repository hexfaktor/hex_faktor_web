defmodule Refaktor.Persistence.GitRepo do
  import Ecto.Query, only: [from: 2]

  alias HexFaktor.Repo
  alias Refaktor.Builder.Model.GitRepo

  def add(url, uid) do
    %GitRepo{}
    |> GitRepo.changeset(%{url: url, uid: uid})
    |> Repo.insert!
  end

  def by_url(url) do
    Repo.one(from r in GitRepo, where: r.url == ^url)
  end

  def by_uid(uid) do
    Repo.one(from r in GitRepo, where: r.uid == ^uid)
  end

  def find_by_id(id) do
    Repo.one(from r in GitRepo, where: r.id == ^id)
  end
end
