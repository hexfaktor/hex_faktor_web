defmodule HexFaktor.Repo.Migrations.CreateProjectUserSettings do
  use Ecto.Migration

  def change do
    create table(:project_user_settings) do
      add :user_id, :integer
      add :project_id, :integer
      add :notification_branches, {:array, :string}
      add :email_enabled, :boolean, default: false

      timestamps
    end
    create index(:project_user_settings, ["project_id"])
    create index(:project_user_settings, ["user_id"])
  end
end
