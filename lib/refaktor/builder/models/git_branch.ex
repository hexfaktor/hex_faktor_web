defmodule Refaktor.Builder.Model.GitBranch do
  use Ecto.Model

  alias Refaktor.Builder.Model.GitRepo
  alias Refaktor.Builder.Model.GitRevision

  schema "git_branches" do
    field :name, :string

    timestamps

    belongs_to :latest_git_revision, GitRevision
    belongs_to :git_repo, GitRepo
  end

  @required_fields ~w(git_repo_id name)
  @optional_fields ~w(latest_git_revision_id)

  def changeset(object, params \\ :empty) do
    object
    |> cast(params, @required_fields, @optional_fields)
  end
end
