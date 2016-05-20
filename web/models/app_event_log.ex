defmodule HexFaktor.AppEventLog do
  use HexFaktor.Web, :model

  schema "app_event_logs" do
    field :user_id, :integer
    field :key, :string
    field :value, :map

    timestamps
  end

  @required_fields ~w(user_id key value)
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
