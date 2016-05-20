defmodule HexFaktor.AppEventLogTest do
  use HexFaktor.ModelCase

  alias HexFaktor.AppEventLog

  @valid_attrs %{key: "some content", user_id: 42, value: %{}}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = AppEventLog.changeset(%AppEventLog{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = AppEventLog.changeset(%AppEventLog{}, @invalid_attrs)
    refute changeset.valid?
  end
end
