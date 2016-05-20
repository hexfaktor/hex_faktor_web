defmodule Refaktor.Builder.Model.GitRevision do
  use Ecto.Model

  alias Refaktor.Builder.Model.GitRepo

  schema "git_revisions" do
    field :sha1, :string

    timestamps

    belongs_to :git_branch, GitBranch
    belongs_to :git_repo, GitRepo
  end

  @required_fields ~w(git_repo_id git_branch_id sha1)
  @optional_fields ~w()

  def changeset(object, params \\ :empty) do
    object
    |> cast(params, @required_fields, @optional_fields)
  end
end
