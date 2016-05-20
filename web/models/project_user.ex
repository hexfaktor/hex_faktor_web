defmodule HexFaktor.ProjectUser do
  use HexFaktor.Web, :model

  alias HexFaktor.User
  alias HexFaktor.Project

  schema "project_users" do
    timestamps

    belongs_to :project, Project
    belongs_to :user, User
  end

  @required_fields ~w(project_id user_id)
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
