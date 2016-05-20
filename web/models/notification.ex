defmodule HexFaktor.Notification do
  use HexFaktor.Web, :model

  alias Refaktor.Job.Elixir.Deps.Model.DepsObject
  alias Refaktor.Builder.Model.GitBranch
  alias HexFaktor.Project

  schema "notifications" do
    field :reason, :string
    field :reason_hash, :string

    field :resolved_by_build_job_id, :integer

    field :seen_at, Ecto.DateTime
    field :email_sent_at, Ecto.DateTime

    timestamps

    belongs_to :user, User
    belongs_to :project, Project
    belongs_to :git_branch, GitBranch
    belongs_to :deps_object, DepsObject
    belongs_to :package, Package
  end

  @required_fields ~w(user_id reason reason_hash)
  @optional_fields ~w(project_id git_branch_id deps_object_id package_id resolved_by_build_job_id)

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
