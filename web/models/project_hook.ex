defmodule HexFaktor.ProjectHook do
  use HexFaktor.Web, :model

  schema "project_hooks" do
    field :project_id, :integer
    field :provider, :string
    field :uid, :string
    field :active, :boolean, default: false

    timestamps
  end

  @required_fields ~w(project_id provider uid)
  @optional_fields ~w(active)

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
