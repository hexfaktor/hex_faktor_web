defmodule HexFaktor.ProjectView do
  use HexFaktor.Web, :view

  alias HexFaktor.Project

  def render("ok.json", _), do: %{ok: true}
  def render("error.json", _), do: %{error: true}

  def github_revision_link(_project, nil), do: nil
  def github_revision_link(%Project{provider: "github"} = project, git_revision) do
    sha1 = git_revision.sha1
    text = sha1 |> String.slice(0..7)
    url = "https://github.com/#{project.name}/commit/#{sha1}"
    link text, to: url, target: "_blank"
  end
end
