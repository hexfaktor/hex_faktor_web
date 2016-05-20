defmodule HexFaktor.Repo.Migrations.AddGitObjects do
  use Ecto.Migration

  def change do
    create table(:git_repos) do
      add :uid, :string
      add :url, :string

      timestamps

      add :default_git_branch_id, :integer
    end
    create index(:git_repos, ["uid"])
    create unique_index(:git_repos, ["url"])

    create table(:git_branches) do
      add :name, :string

      timestamps

      add :git_repo_id, :integer
      add :latest_git_revision_id, :integer
    end

    create table(:git_revisions) do
      add :sha1, :string

      timestamps

      add :git_repo_id, :integer
      add :git_branch_id, :integer
    end
  end
end
