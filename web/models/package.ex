defmodule HexFaktor.Package do
  use HexFaktor.Web, :model

  schema "packages" do
    field :name, :string
    field :source, :string
    field :source_url, :string

    field :language, :string
    field :description, :string

    field :releases, {:array, :map}

    # these are the current_user's project dependent on the package
    # set optionally in the controller if user is logged in
    field :dependent_projects_by_current_user, {:array, :any}, virtual: true

    timestamps

    belongs_to :project, HexFaktor.Project
  end

  @required_fields ~w(name source)
  @optional_fields ~w(source_url language description releases project_id)

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
