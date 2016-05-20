defmodule HexFaktor.Repo.Migrations.CreateProjectHook do
  use Ecto.Migration

  def change do
    create table(:project_hooks) do
      add :project_id, :integer
      add :provider, :string
      add :uid, :string
      add :active, :boolean, default: false

      timestamps
    end
    create index(:project_hooks, ["project_id"])
  end
end
