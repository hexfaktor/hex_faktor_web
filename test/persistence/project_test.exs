defmodule HexFaktor.Persistence.UserTest do
  use HexFaktor.ModelCase

  alias HexFaktor.Persistence.Project

  @valid_github_response %{
    "id" => 1296269,
    "full_name" => "rrrene/credo",
    "html_url" => "https://github.com/octocat/Hello-World",
    "clone_url" => "https://github.com/octocat/Hello-World.git",
    "default_branch" => "master",
    "language" => "Elixir",
    "fork" => false
  }

  @invalid_attrs %{}

  test "ensure does only create every project once" do
    old_count = Project.count

    Project.ensure(@valid_github_response)
    new_count = Project.count
    assert new_count > old_count

    Project.ensure(@valid_github_response)
    newer_count = Project.count
    assert new_count == newer_count
  end

end
