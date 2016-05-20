defmodule HexFaktor.Persistence.Package do
  import Ecto.Query, only: [from: 2]

  alias HexFaktor.Repo
  alias HexFaktor.Package

  def all do
    Repo.all(Package)
  end

  def create_from_hex(:econnrefused, _name) do
    nil
  end
  def create_from_hex(params, name) do
    %Package{
      name: name,
      source: "hex",
      source_url: params["github_url"]
    } |> Repo.insert!
  end

  def find_by_name(name) do
    query = from u in Package,
            where: u.name == ^name,
            select: u
    Repo.one(query)
  end
end
