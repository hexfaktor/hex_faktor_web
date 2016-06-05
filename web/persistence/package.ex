defmodule HexFaktor.Persistence.Package do
  import Ecto.Query, only: [from: 2]

  alias HexFaktor.Repo
  alias HexFaktor.Package

  def all do
    Repo.all(Package)
  end

  def all_by_query(search_query) do
    search_query = "%#{search_query}%"
    query = from r in Package,
            where: like(r.name, ^search_query)
                    or r.source_url == ^search_query,
            select: r
    Repo.all(query)
  end

  def create_from_hex(:econnrefused, _name) do
    nil
  end
  def create_from_hex(params, name) do
    %Package{
      name: name,
      source: "hex",
      source_url: params["github_url"],
      description: params["description"],
      releases: params["releases"] |> reduce_releases()
    } |> Repo.insert!
  end

  def ensure(name) do
    case find_by_name(name) do
      nil -> %Package{name: name, source: "hex"} |> Repo.insert!
      val -> val
    end
  end

  def ensure_and_update(name, params) do
    package = ensure(name)
    update_from_hex(params, package)
  end

  def find_by_id(id, preload_list \\ []) do
    query = from r in Package,
            where: r.id == ^id,
            select: r,
            preload: ^preload_list
    Repo.one(query)
  end

  def find_by_name(name) do
    query = from u in Package,
            where: u.name == ^name,
            select: u
    Repo.one(query)
  end

  def update_from_hex(:econnrefused, _package) do
    nil
  end
  def update_from_hex(params, package) do
    package
    |> Package.changeset(%{
        source_url: params["github_url"],
        description: params["description"],
        releases: params["releases"] |> reduce_releases()
      })
    |> Repo.update!
  end

  def update_project_id(package, project_id) do
    package
    |> Package.changeset(%{project_id: project_id})
    |> Repo.update!
  end

  defp reduce_releases(releases) do
    releases
    |> Enum.map(fn(release) ->
        %{
          "version" => release["version"],
          "updated_at" => cast_time(release["updated_at"])
        }
      end)
    |> Enum.sort_by(&(&1["version"]))
    |> Enum.reverse
  end

  defp cast_time(string) do
    string
    |> String.replace(~r/^(\d\d\d\d-\d\d-\d\dT\d\d\:\d\d\:\d\d)(.+Z)/, "\\1Z")
    |> Ecto.DateTime.cast
    |> case do
        {:ok, datetime} -> datetime
        _ -> nil
      end
  end
end
