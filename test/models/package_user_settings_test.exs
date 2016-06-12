defmodule HexFaktor.PackageUserSettingsTest do
  use HexFaktor.ModelCase

  alias HexFaktor.PackageUserSettings

  @valid_attrs %{package_id: 42, user_id: 42}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = PackageUserSettings.changeset(%PackageUserSettings{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = PackageUserSettings.changeset(%PackageUserSettings{}, @invalid_attrs)
    refute changeset.valid?
  end
end
