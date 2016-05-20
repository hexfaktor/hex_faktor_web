defmodule HexFaktor.NotificationTest do
  use HexFaktor.ModelCase

  alias HexFaktor.Notification

  @valid_attrs %{package_id: 42, project_id: 42, git_branch_id: 42, reason: "some content", reason_hash: "some content", user_id: 42}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Notification.changeset(%Notification{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Notification.changeset(%Notification{}, @invalid_attrs)
    refute changeset.valid?
  end
end
