defmodule Refaktor.Builder.Model.BuildJob do
  use Ecto.Model

  alias Refaktor.Builder.Model.Build
  alias Refaktor.Builder.Model.GitBranch
  alias Refaktor.Builder.Model.GitRevision

  schema "build_jobs" do
    field :nr, :integer
    field :language, :string
    field :intent, :string
    field :stderr, :string
    field :stdout, :string

    field :status, :string  # scheduled, running, success, failure
    field :debug_info, :string # json-encoded debug log
    field :logs, :string # output from `docker logs`
    field :started_at, Ecto.DateTime
    field :finished_at, Ecto.DateTime

    timestamps

    belongs_to :build, Build
    belongs_to :git_branch, GitBranch
    belongs_to :git_revision, GitRevision
  end

  @required_fields ~w(nr language intent build_id git_branch_id)
  @optional_fields ~w(started_at finished_at logs stderr stdout git_revision_id status debug_info)

  def changeset(object, params \\ :empty) do
    object
    |> cast(params, @required_fields, @optional_fields)
    |> unique_constraint(:nr, name: :build_jobs_unique_index)
  end
end
