defmodule Refaktor.Job.Elixir.Deps.Model.DepsObject do
  use Ecto.Model

  schema "deps_objects" do
    belongs_to :build_job, BuildJob
    belongs_to :project, HexFaktor.Project
    belongs_to :git_branch, GitBranch
    belongs_to :git_repo, GitRepo

    field :language, :string, size: 10
    field :name, :string
    field :source, :string
    field :source_url, :string
    field :toplevel, :boolean
    field :locked_version, :string
    field :required_version, :string
    field :available_versions, {:array, :string}
    field :mix_envs, {:array, :string}
    field :severity, :string

    timestamps
  end

  @required_fields ~w(build_job_id language name source toplevel)
  @optional_fields ~w(project_id git_branch_id git_repo_id source_url locked_version required_version available_versions mix_envs severity)

  def changeset(object, params \\ :empty) do
    object
    |> cast(params, @required_fields, @optional_fields)
  end
end
