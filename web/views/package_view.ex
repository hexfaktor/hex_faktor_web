defmodule HexFaktor.PackageView do
  use HexFaktor.Web, :view

  def current_version([%{"version" => version}|tail]), do: version
  def current_version(_), do: nil

  def render("index.json", %{packages: packages}) do
    packages |> Enum.map(&package_to_json/1)
  end

  def render("show.json", %{package: package}) do
    package |> package_to_json()
  end

  defp package_to_json(package) do
    versions =
      package.releases
      |> Enum.map(&release_to_json/1)
    %{
      name: package.name,
      description: package.description,
      source_url: package.source_url,
      releases: versions,
      cached_at: package.updated_at,
    }
  end

  defp release_to_json(release) do
    %{
      version: release["version"],
      updated_at: release["updated_at"]
    }
  end

  def render("ok.json", _), do: %{ok: true}
  def render("error.json", _), do: %{error: true}

  def render("404.html", _), do: "Not found"
  def render("404.json", _), do: %{error: true}
end
