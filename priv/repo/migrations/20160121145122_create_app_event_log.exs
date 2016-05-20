defmodule HexFaktor.Repo.Migrations.CreateAppEventLog do
  use Ecto.Migration

  def change do
    create table(:app_event_logs) do
      add :user_id, :integer
      add :key, :string
      add :value, :map

      timestamps
    end

  end
end
