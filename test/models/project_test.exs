defmodule HexFaktor.ProjectTest do
  use HexFaktor.ModelCase

  alias HexFaktor.Project
  alias HexFaktor.ProjectHook
  alias HexFaktor.ProjectUser
  alias HexFaktor.ProjectUserSettings
  alias HexFaktor.Repo

  alias Refaktor.Builder.Model.Build

  @valid_attrs %{uid: 1, provider: "github", name: "rrrene/credo", active: false, default_branch: "master", git_repo_id: 42, html_url: "some content", clone_url: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Project.changeset(%Project{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Project.changeset(%Project{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "deletes associations of a project when project is deleted" do
    old_hook_count = count(ProjectHook)
    old_user_count = count(ProjectUser)
    old_user_settings_count = count(ProjectUserSettings)
    old_build_count = count(Build)

    project = Repo.get(Project, 1)
    Repo.delete!(project)

    assert old_hook_count < count(ProjectHook)
    assert old_user_count < count(ProjectUser)
    assert old_user_settings_count < count(ProjectUserSettings)
    #assert old_build_count < count(Build) # TODO: add builds to fixtures
  end

  defp count(model) do
    from(p in model, select: count(p.id))
    |> Repo.one!
  end
end
