defmodule HexFaktor.ProjectUserSettingsTest do
  use HexFaktor.ModelCase

  alias HexFaktor.ProjectUserSettings

  @valid_attrs %{active_branches: "some content", email_enabled: true, project_id: 42, user_id: 42}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = ProjectUserSettings.changeset(%ProjectUserSettings{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = ProjectUserSettings.changeset(%ProjectUserSettings{}, @invalid_attrs)
    refute changeset.valid?
  end
end
