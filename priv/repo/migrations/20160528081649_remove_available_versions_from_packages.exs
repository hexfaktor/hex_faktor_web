defmodule HexFaktor.Repo.Migrations.RemoveAvailableVersionsFromPackages do
  use Ecto.Migration

  def change do
    alter table(:packages) do
      remove :available_versions
    end
  end
end
