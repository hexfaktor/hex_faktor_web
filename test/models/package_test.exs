defmodule HexFaktor.PackageTest do
  use HexFaktor.ModelCase

  alias HexFaktor.Package

  @valid_attrs %{name: "some content", source: "some content", source_url: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Package.changeset(%Package{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Package.changeset(%Package{}, @invalid_attrs)
    refute changeset.valid?
  end
end
