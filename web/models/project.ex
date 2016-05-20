defmodule HexFaktor.Project do
  use HexFaktor.Web, :model

  schema "projects" do
    field :active, :boolean

    field :uid, :integer
    field :provider, :string

    field :name, :string
    field :html_url, :string
    field :clone_url, :string
    field :default_branch, :string
    field :language, :string
    field :fork, :boolean

    field :last_github_sync, Ecto.DateTime
    field :latest_build_job_id, :integer

    field :use_lock_file, :boolean

    field :outdated_deps, {:array, :any}, virtual: true

    timestamps

    belongs_to :git_repo, Refaktor.Builder.Model.GitRepo
    has_many :git_repo_branches, through: [:git_repo, :branches], on_delete: :delete_all
    has_many :builds, through: [:git_repo, :builds], on_delete: :delete_all
    has_many :project_hooks, HexFaktor.ProjectHook, on_delete: :delete_all
    has_many :project_users, HexFaktor.ProjectUser, on_delete: :delete_all
    has_many :project_user_settings, HexFaktor.ProjectUserSettings, on_delete: :delete_all
  end

  @required_fields ~w(uid provider name clone_url active default_branch)
  @optional_fields ~w(git_repo_id language last_github_sync html_url fork latest_build_job_id use_lock_file)

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> unique_constraint(:uid, name: :projects_unique_index)
  end
end
