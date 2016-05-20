defmodule HexFaktor.ProjectUserSettings do
  use HexFaktor.Web, :model

  schema "project_user_settings" do
    field :notification_branches, {:array, :string}
    field :email_enabled, :boolean, default: true

    timestamps

    belongs_to :project, Project
    belongs_to :user, User
  end

  @required_fields ~w(user_id project_id notification_branches email_enabled)
  @optional_fields ~w()

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
