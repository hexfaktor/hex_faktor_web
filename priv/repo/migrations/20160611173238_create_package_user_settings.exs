defmodule HexFaktor.Repo.Migrations.CreatePackageUserSettings do
  use Ecto.Migration

  def change do
    create table(:package_user_settings) do
      add :user_id, :integer
      add :package_id, :integer

      add :notifications_for_major, :boolean, default: false
      add :notifications_for_minor, :boolean, default: false
      add :notifications_for_patch, :boolean, default: false
      add :notifications_for_pre, :boolean, default: false

      add :email_enabled, :boolean, default: false

      timestamps
    end
    create index(:package_user_settings, ["package_id"])
    create index(:package_user_settings, ["user_id"])
  end
end
