defmodule Refaktor.Builder.Model.GitRepo do
  use Ecto.Model

  alias Refaktor.Builder.Model.GitBranch

  schema "git_repos" do
    field :uid, :string
    field :url, :string

    timestamps

    belongs_to :default_git_branch, GitBranch
    has_many :branches, GitBranch, on_delete: :delete_all
  end

  @required_fields ~w(uid url)
  @optional_fields ~w(default_git_branch_id)

  def changeset(object, params \\ :empty) do
    object
    |> cast(params, @required_fields, @optional_fields)
    |> unique_constraint(:uid)
  end
end
