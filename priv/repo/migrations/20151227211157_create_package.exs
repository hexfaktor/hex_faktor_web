defmodule HexFaktor.Repo.Migrations.CreatePackage do
  use Ecto.Migration

  def change do
    create table(:packages) do
      add :name, :string
      add :source, :string
      add :language, :string
      add :description, :string
      add :source_url, :string

      add :available_versions, {:array, :string}

      timestamps
    end
    create index(:packages, ["name"])
  end
end
