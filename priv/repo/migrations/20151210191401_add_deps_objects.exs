defmodule HexFaktor.Repo.Migrations.AddDepsObjects do
  use Ecto.Migration

  def change do
    create table(:deps_objects) do
      add :build_job_id, :integer
      add :project_id, :integer
      add :git_repo_id, :integer
      add :git_branch_id, :integer

      add :toplevel, :boolean
      add :language, :string
      add :name, :string
      add :source, :string
      add :source_url, :string
      add :locked_version, :string
      add :required_version, :string
      add :available_versions, {:array, :string}
      add :mix_envs, {:array, :string}
      add :severity, :string

      timestamps
    end
    create index(:deps_objects, ["build_job_id"])
  end
end
