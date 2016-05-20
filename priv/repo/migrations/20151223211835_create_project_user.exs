defmodule HexFaktor.Repo.Migrations.CreateProjectUser do
  use Ecto.Migration

  def change do
    create table(:project_users) do
      add :project_id, :integer
      add :user_id, :integer

      timestamps
    end
    create index(:project_users, ["project_id"])
    create index(:project_users, ["user_id"])
  end
end
