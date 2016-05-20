defmodule Refaktor.Builder.Model.Build do
  use Ecto.Model

  alias Refaktor.Builder.Model.GitRepo
  alias Refaktor.Builder.Model.GitBranch
  alias Refaktor.Builder.Model.BuildJob

  schema "builds" do
    field :nr, :integer
    field :trigger, :string

    timestamps

    belongs_to :git_repo, GitRepo
    belongs_to :git_branch, GitBranch
    has_many :build_jobs, BuildJob, on_delete: :delete_all
  end

  @required_fields ~w(nr git_repo_id)
  @optional_fields ~w(trigger git_branch_id)

  def changeset(object, params \\ :empty) do
    object
    |> cast(params, @required_fields, @optional_fields)
  end
end
