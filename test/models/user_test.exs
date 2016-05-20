defmodule HexFaktor.UserTest do
  use HexFaktor.ModelCase

  alias HexFaktor.User

  @valid_attrs %{uid: 1, provider: "github", full_name: "René Föhring", user_name: "rrrene", email: "rf@bamaru.de", email_notification_frequency: "none"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = User.changeset(%User{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = User.changeset(%User{}, @invalid_attrs)
    refute changeset.valid?
  end
end
