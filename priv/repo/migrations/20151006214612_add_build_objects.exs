defmodule HexFaktor.Repo.Migrations.AddBuildObjects do
  use Ecto.Migration

  def change do
    create table(:builds) do
      add :nr, :integer
      add :trigger, :string

      timestamps

      add :git_repo_id, :integer
      add :git_branch_id, :integer
    end
    create index(:builds, ["git_repo_id"])

    create table(:build_jobs) do
      add :nr, :integer

      add :language, :string
      add :intent, :string
      add :stderr, :string
      add :stdout, :string
      add :logs, :text

      add :status, :string
      add :started_at, :datetime
      add :finished_at, :datetime
      add :debug_info, :text

      timestamps

      add :build_id, :integer
      add :git_branch_id, :integer
      add :git_revision_id, :integer
    end
    create index(:build_jobs, ["build_id"])
    create unique_index(:build_jobs,
                        ["nr", "build_id"],
                        name: :build_jobs_unique_index)
  end
end
