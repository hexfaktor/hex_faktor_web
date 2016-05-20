defmodule HexFaktor.ProjectUserTest do
  use HexFaktor.ModelCase

  alias HexFaktor.ProjectUser

  @valid_attrs %{project_id: 42, user_id: 42}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = ProjectUser.changeset(%ProjectUser{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = ProjectUser.changeset(%ProjectUser{}, @invalid_attrs)
    refute changeset.valid?
  end
end
