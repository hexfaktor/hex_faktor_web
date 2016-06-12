defmodule HexFaktor.PackageUserSettings do
  use HexFaktor.Web, :model

  schema "package_user_settings" do
    field :user_id, :integer
    field :package_id, :integer

    field :notifications_for_major, :boolean
    field :notifications_for_minor, :boolean
    field :notifications_for_patch, :boolean
    field :notifications_for_pre, :boolean

    field :email_enabled, :boolean

    timestamps
  end

  @required_fields ~w(user_id package_id)
  @optional_fields ~w(notifications_for_major notifications_for_minor notifications_for_patch notifications_for_pre email_enabled)

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end
end
