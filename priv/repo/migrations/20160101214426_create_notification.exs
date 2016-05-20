defmodule HexFaktor.Repo.Migrations.CreateNotification do
  use Ecto.Migration

  def change do
    create table(:notifications) do
      add :user_id, :integer

      add :project_id, :integer
      add :git_branch_id, :integer
      add :deps_object_id, :integer
      add :package_id, :integer

      add :reason, :string
      add :reason_hash, :string

      add :resolved_by_build_job_id, :integer
      add :seen_at, :datetime
      add :email_sent_at, :datetime

      timestamps
    end
    create index(:notifications, ["user_id", "seen_at"])
  end
end
