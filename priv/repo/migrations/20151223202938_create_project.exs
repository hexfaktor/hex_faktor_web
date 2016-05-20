defmodule HexFaktor.Repo.Migrations.CreateProject do
  use Ecto.Migration

  def change do
    create table(:projects) do
      add :uid, :integer # unique id in the oauth provider's system
      add :provider, :string
      add :name, :string
      add :html_url, :string
      add :clone_url, :string
      add :default_branch, :string
      add :language, :string
      add :fork, :boolean

      add :active, :boolean
      add :git_repo_id, :integer

      add :last_github_sync, :datetime
      add :latest_build_job_id, :integer

      timestamps
    end
    create index(:projects, ["provider", "name"])
    create unique_index(:projects, ["provider", "uid"], name: :projects_unique_index)
  end
end
