defmodule HexFaktor.Repo.Migrations.AddMetadataToNotifications do
  use Ecto.Migration

  def change do
    alter table(:notifications) do
      add :metadata, :map
    end
  end
end
