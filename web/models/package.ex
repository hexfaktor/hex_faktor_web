defmodule HexFaktor.Package do
  use HexFaktor.Web, :model

  schema "packages" do
    field :name, :string
    field :source, :string
    field :source_url, :string

    timestamps
  end

  @required_fields ~w(name source)
  @optional_fields ~w(source_url)

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
